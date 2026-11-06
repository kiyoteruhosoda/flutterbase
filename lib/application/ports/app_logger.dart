import 'package:flutterbase/domain/entities/log_entry.dart';
import 'package:flutterbase/domain/value_objects/log_level.dart';

/// Outbound logging port.
///
/// Declared in Application so that Use Cases and Presentation depend on the
/// contract rather than on a logging backend. The concrete adapter lives in
/// `infrastructure/logging/` and is bound in `app/di/service_locator.dart`.
///
/// The port deliberately speaks in [String] paths rather than `dart:io`
/// handles: `dart:io` is an Infrastructure detail and is rejected outside
/// that layer by `tool/check_architecture.dart`.
abstract interface class AppLogger {
  void verbose(String message, {Object? error, StackTrace? stackTrace});
  void debug(String message, {Object? error, StackTrace? stackTrace});
  void info(String message, {Object? error, StackTrace? stackTrace});
  void warning(String message, {Object? error, StackTrace? stackTrace});
  void error(String message, {Object? error, StackTrace? stackTrace});

  /// All entries currently in the in-memory buffer (oldest first).
  List<LogEntry> get entries;

  /// Entries filtered by [level]; null returns all.
  List<LogEntry> entriesForLevel(LogLevel? level);

  /// Current minimum log level. Messages below this level are silently dropped.
  LogLevel get minLevel;

  /// Changes the minimum log level at runtime.
  void setMinLevel(LogLevel level);

  /// Clears the in-memory buffer. Persistent files are unaffected.
  void clearBuffer();

  /// Saves the buffer as a `.log` file where the person chooses — Android's
  /// "save to" screen (Downloads, a Drive folder…) — so they can open it
  /// later from the Files app (docs/adr/0018-save-logs-where-the-person-can-open-them.md).
  ///
  /// Answers [LogExportCancelled] when they backed out of the screen, and
  /// [LogExportFailed] when nothing could be written.
  Future<LogExportResult> exportLogs();

  /// Hands the buffer, as a `.log` file, to Android's share sheet (mail it to
  /// yourself, a chat, Drive…). Answers false when the sheet could not be
  /// opened.
  Future<bool> shareLogs();

  /// Returns the paths of all persisted log files (newest first).
  Future<List<String>> logFilePaths();
}

/// What became of [AppLogger.exportLogs].
sealed class LogExportResult {
  const LogExportResult();
}

/// The file was written. [fileName] is the name it was saved under (the
/// person may have changed it), [folder] the place as the platform names it
/// — "Download", "Documents", a Drive folder — or null when it does not say.
final class LogExportSaved extends LogExportResult {
  const LogExportSaved({required this.fileName, this.folder});

  final String fileName;
  final String? folder;
}

/// The person closed the "save to" screen without choosing a place.
final class LogExportCancelled extends LogExportResult {
  const LogExportCancelled();
}

/// The file could not be written.
final class LogExportFailed extends LogExportResult {
  const LogExportFailed();
}
