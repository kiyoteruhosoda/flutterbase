import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutterbase/application/ports/app_logger.dart';
import 'package:flutterbase/domain/entities/log_entry.dart';
import 'package:flutterbase/domain/value_objects/log_level.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

/// [AppLogger] implementation that writes to the console and to rotating
/// log files under `<documents>/logs/`.
///
/// Those files are inside the app's own storage, which the person cannot
/// reach. Saving and sharing therefore go through `MainActivity`'s
/// `nolumia/log_files` channel: Android's "save to" screen and share sheet
/// (docs/adr/0018-save-logs-where-the-person-can-open-them.md).
///
/// Register as a singleton in `app/di/service_locator.dart`:
/// ```dart
/// sl.registerSingleton<AppLogger>(PersistentAppLogger());
/// await sl<AppLogger>().init();
/// ```
final class PersistentAppLogger implements AppLogger {
  PersistentAppLogger([
    this._logFiles = const MethodChannel('nolumia/log_files'),
  ]) {
    _logger = Logger(
      filter: _PassThroughFilter(),
      printer: _PlainPrinter(),
      output: ConsoleOutput(),
      level: kDebugMode ? Level.trace : Level.info,
    );
  }

  static const int maxBufferEntries = 1000;
  static const int maxFiles = 5;
  static const int maxFileSizeBytes = 1024 * 1024; // 1 MB

  late final Logger _logger;
  final MethodChannel _logFiles;
  final List<LogEntry> _buffer = [];
  IOSink? _fileSink;
  File? _currentFile;
  LogLevel _minLevel = LogLevel.debug;

  // ── AppLogger: min level ──────────────────────────────────────────────

  @override
  LogLevel get minLevel => _minLevel;

  @override
  void setMinLevel(LogLevel level) => _minLevel = level;

  // ── Initialisation ────────────────────────────────────────────────────

  /// Opens the initial log file and optionally restores [savedLevel].
  /// Call once after construction.
  Future<void> init({LogLevel? savedLevel}) async {
    if (savedLevel != null) _minLevel = savedLevel;
    try {
      await _openNewLogFile();
    } on Exception catch (e) {
      debugPrint('[PersistentAppLogger] Could not open log file: $e');
    }
  }

  // ── AppLogger interface ───────────────────────────────────────────────

  @override
  void verbose(String message, {Object? error, StackTrace? stackTrace}) =>
      _log(LogLevel.verbose, message, error: error, stackTrace: stackTrace);

  @override
  void debug(String message, {Object? error, StackTrace? stackTrace}) =>
      _log(LogLevel.debug, message, error: error, stackTrace: stackTrace);

  @override
  void info(String message, {Object? error, StackTrace? stackTrace}) =>
      _log(LogLevel.info, message, error: error, stackTrace: stackTrace);

  @override
  void warning(String message, {Object? error, StackTrace? stackTrace}) =>
      _log(LogLevel.warning, message, error: error, stackTrace: stackTrace);

  @override
  void error(String message, {Object? error, StackTrace? stackTrace}) =>
      _log(LogLevel.error, message, error: error, stackTrace: stackTrace);

  @override
  List<LogEntry> get entries => List.unmodifiable(_buffer);

  @override
  List<LogEntry> entriesForLevel(LogLevel? level) =>
      level == null ? entries : entries.where((e) => e.level == level).toList();

  @override
  void clearBuffer() => _buffer.clear();

  @override
  Future<LogExportResult> exportLogs() async {
    try {
      final answer = await _logFiles.invokeMapMethod<String, Object?>(
        'saveAs',
        _exportArguments(),
      );
      // No answer is the person backing out of the "save to" screen.
      if (answer == null) return const LogExportCancelled();
      final name = answer['name'];
      final folder = answer['folder'];
      return LogExportSaved(
        fileName: name is String && name.isNotEmpty ? name : _exportName(),
        folder: folder is String && folder.isNotEmpty ? folder : null,
      );
    } on Exception catch (e) {
      debugPrint('[PersistentAppLogger] Export failed: $e');
      return const LogExportFailed();
    }
  }

  @override
  Future<bool> shareLogs() async {
    try {
      await _logFiles.invokeMethod<void>('share', _exportArguments());
      return true;
    } on Exception catch (e) {
      debugPrint('[PersistentAppLogger] Share failed: $e');
      return false;
    }
  }

  /// The buffer as log lines and the name the file is offered under.
  /// Android puts the app's own name in front (`MainActivity`), so files
  /// from several apps in Downloads can be told apart.
  Map<String, Object?> _exportArguments() => <String, Object?>{
    'name': _exportName(),
    'text': _buffer.map((e) => '${e.toLogLine()}\n').join(),
  };

  /// `.txt`, not `.log`: Android's Files app opens nothing for `.log` (no
  /// app claims the type), and the "save to" screen would turn it into
  /// `.log.txt` anyway (docs/adr/0018-*).
  String _exportName() => 'log_${_fileTimestamp()}.txt';

  @override
  Future<List<String>> logFilePaths() async {
    try {
      final dir = await _logsDirectory();
      return dir
          .listSync()
          .whereType<File>()
          .map((f) => f.path)
          .where((path) => path.endsWith('.log'))
          .toList()
        ..sort((a, b) => b.compareTo(a));
    } on Exception {
      return <String>[];
    }
  }

  // ── Internal ──────────────────────────────────────────────────────────

  void _log(
    LogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (level.index < _minLevel.index) return;

    final entry = LogEntry(
      timestamp: DateTime.now().toUtc(),
      level: level,
      message: message,
      error: error,
      stackTrace: stackTrace,
    );

    _buffer.add(entry);
    if (_buffer.length > maxBufferEntries) _buffer.removeAt(0);

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

    _writeToFile(entry);
  }

  void _writeToFile(LogEntry entry) {
    final sink = _fileSink;
    final file = _currentFile;
    if (sink == null) return;
    try {
      sink.writeln(entry.toLogLine());
      if (file != null) unawaited(_rotateIfOversized(file));
    } on Exception {
      // Swallowed on purpose: a logging failure must never take down the
      // caller. Console output continues regardless.
    }
  }

  /// Starts a new log file once [file] has grown past [maxFileSizeBytes].
  Future<void> _rotateIfOversized(File file) async {
    try {
      if (await file.length() < maxFileSizeBytes) return;
      await _openNewLogFile();
    } on Exception catch (e) {
      debugPrint('[PersistentAppLogger] Rotation failed: $e');
    }
  }

  Future<void> _openNewLogFile() async {
    await _fileSink?.close();
    _fileSink = null;
    final dir = await _logsDirectory();
    _currentFile = File('${dir.path}/app_${_fileTimestamp()}.log');
    _fileSink = _currentFile!.openWrite(mode: FileMode.append);
    await _pruneOldFiles(dir);
  }

  Future<void> _pruneOldFiles(Directory dir) async {
    final files =
        dir
            .listSync()
            .whereType<File>()
            .where((f) => f.path.endsWith('.log'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));
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

  /// UTC so the file names line up with the timestamps inside them.
  String _fileTimestamp() {
    final now = DateTime.now().toUtc();
    return '${now.year.toString().padLeft(4, '0')}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}'
        '_${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}'
        '${now.second.toString().padLeft(2, '0')}';
  }
}

// ─── Logger internals ────────────────────────────────────────────────────

class _PassThroughFilter extends LogFilter {
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
