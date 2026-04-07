import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

// ─── Log Entry model ─────────────────────────────────────────────────────────

/// Severity level for a log entry.
enum LogLevel { verbose, debug, info, warning, error }

/// A single log entry stored in the in-memory buffer.
class LogEntry {
  const LogEntry({
    required this.timestamp,
    required this.level,
    required this.message,
    this.error,
    this.stackTrace,
  });

  final DateTime timestamp;
  final LogLevel level;
  final String message;
  final Object? error;
  final StackTrace? stackTrace;

  String get levelLabel => switch (level) {
        LogLevel.verbose => 'V',
        LogLevel.debug => 'D',
        LogLevel.info => 'I',
        LogLevel.warning => 'W',
        LogLevel.error => 'E',
      };

  String toLogLine() {
    final ts = timestamp.toIso8601String();
    final base = '[$ts][$levelLabel] $message';
    if (error != null) return '$base\n  ERROR: $error';
    return base;
  }
}

// ─── AppLogger ───────────────────────────────────────────────────────────────

/// Singleton logger service.
///
/// - Forwards all output to the `logger` package (console).
/// - Keeps an in-memory circular buffer of the last [maxBufferEntries] entries.
/// - Persists to rotating log files under the app documents directory:
///   `<docs>/logs/app_YYYYMMDD_HHmmss.log`
///   Up to [maxFiles] files are kept; the oldest is deleted when the limit
///   is exceeded or the current file exceeds [maxFileSizeBytes].
class AppLogger {
  AppLogger._() {
    _logger = Logger(
      filter: _AppLogFilter(),
      printer: _PlainPrinter(),
      output: ConsoleOutput(),
      level: kDebugMode ? Level.trace : Level.info,
    );
  }

  static final AppLogger instance = AppLogger._();

  static const int maxBufferEntries = 1000;
  static const int maxFiles = 5;
  static const int maxFileSizeBytes = 1024 * 1024; // 1 MB

  late final Logger _logger;
  final List<LogEntry> _buffer = [];
  IOSink? _fileSink;
  File? _currentFile;
  bool _initialized = false;

  // ── Initialisation ────────────────────────────────────────────────────

  /// Call once at app startup (after WidgetsFlutterBinding.ensureInitialized).
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    try {
      await _openNewLogFile();
    } catch (e) {
      // File logging unavailable — console only.
      debugPrint('[AppLogger] Could not open log file: $e');
    }
  }

  // ── Public API ────────────────────────────────────────────────────────

  void verbose(String message, {Object? error, StackTrace? stackTrace}) =>
      _log(LogLevel.verbose, message, error: error, stackTrace: stackTrace);

  void debug(String message, {Object? error, StackTrace? stackTrace}) =>
      _log(LogLevel.debug, message, error: error, stackTrace: stackTrace);

  void info(String message, {Object? error, StackTrace? stackTrace}) =>
      _log(LogLevel.info, message, error: error, stackTrace: stackTrace);

  void warning(String message, {Object? error, StackTrace? stackTrace}) =>
      _log(LogLevel.warning, message, error: error, stackTrace: stackTrace);

  void error(String message, {Object? error, StackTrace? stackTrace}) =>
      _log(LogLevel.error, message, error: error, stackTrace: stackTrace);

  /// All entries currently in the in-memory buffer (oldest first).
  List<LogEntry> get entries => List.unmodifiable(_buffer);

  /// Returns entries filtered by [level] (null = all).
  List<LogEntry> entriesForLevel(LogLevel? level) => level == null
      ? entries
      : entries.where((e) => e.level == level).toList();

  /// Clears the in-memory buffer. Persistent files are unaffected.
  void clearBuffer() => _buffer.clear();

  /// Returns the path of the current log file, or null if unavailable.
  String? get currentLogFilePath => _currentFile?.path;

  /// Returns all log file paths (newest first).
  Future<List<File>> logFiles() async {
    try {
      final dir = await _logsDirectory();
      final files = dir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.log'))
          .toList()
        ..sort((a, b) => b.path.compareTo(a.path));
      return files;
    } catch (_) {
      return [];
    }
  }

  /// Exports the in-memory buffer to a new file and returns its path.
  Future<String?> exportLogs() async {
    try {
      final dir = await _logsDirectory();
      final stamp = _fileTimestamp();
      final file = File('${dir.path}/export_$stamp.log');
      final sink = file.openWrite();
      for (final entry in _buffer) {
        sink.writeln(entry.toLogLine());
      }
      await sink.flush();
      await sink.close();
      return file.path;
    } catch (e) {
      debugPrint('[AppLogger] Export failed: $e');
      return null;
    }
  }

  // ── Internal ──────────────────────────────────────────────────────────

  void _log(
    LogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: level,
      message: message,
      error: error,
      stackTrace: stackTrace,
    );

    // In-memory buffer with cap
    _buffer.add(entry);
    if (_buffer.length > maxBufferEntries) _buffer.removeAt(0);

    // Console via logger package
    switch (level) {
      case LogLevel.verbose:
        _logger.t(message, error: error, stackTrace: stackTrace);
      case LogLevel.debug:
        _logger.d(message, error: error, stackTrace: stackTrace);
      case LogLevel.info:
        _logger.i(message, error: error, stackTrace: stackTrace);
      case LogLevel.warning:
        _logger.w(message, error: error, stackTrace: stackTrace);
      case LogLevel.error:
        _logger.e(message, error: error, stackTrace: stackTrace);
    }

    // File output (fire-and-forget)
    _writeToFile(entry);
  }

  void _writeToFile(LogEntry entry) {
    if (_fileSink == null) return;
    try {
      _fileSink!.writeln(entry.toLogLine());
      // Rotate if file is too large
      _currentFile?.length().then((size) {
        if (size >= maxFileSizeBytes) {
          _openNewLogFile();
        }
      });
    } catch (_) {
      // Swallow file write errors — console logging continues.
    }
  }

  Future<void> _openNewLogFile() async {
    await _fileSink?.close();
    _fileSink = null;

    final dir = await _logsDirectory();
    final stamp = _fileTimestamp();
    _currentFile = File('${dir.path}/app_$stamp.log');
    _fileSink = _currentFile!.openWrite(mode: FileMode.append);

    await _pruneOldFiles(dir);
  }

  Future<void> _pruneOldFiles(Directory dir) async {
    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.log'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path)); // oldest first

    while (files.length > maxFiles) {
      await files.removeAt(0).delete();
    }
  }

  Future<Directory> _logsDirectory() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/logs');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir;
  }

  String _fileTimestamp() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}'
        '_${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}'
        '${now.second.toString().padLeft(2, '0')}';
  }
}

// ─── Logger internals ─────────────────────────────────────────────────────────

class _AppLogFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) => true;
}

class _PlainPrinter extends LogPrinter {
  @override
  List<String> log(LogEvent event) {
    final level = event.level.name.toUpperCase().padRight(7);
    final lines = <String>['[$level] ${event.message}'];
    if (event.error != null) lines.add('  ERROR: ${event.error}');
    return lines;
  }
}
