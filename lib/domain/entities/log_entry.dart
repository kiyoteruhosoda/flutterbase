import 'package:flutterbase/domain/value_objects/log_level.dart';

/// A single immutable log entry.
final class LogEntry {
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

  /// One line for the log file and the clipboard.
  ///
  /// The instant is rendered in UTC so the trailing `Z` is always there:
  /// an ISO string without an offset reads as local time wherever it lands,
  /// and these lines get pasted into issues next to server logs that are UTC.
  String toLogLine() {
    final ts = timestamp.toUtc().toIso8601String();
    final base = '[$ts][$levelLabel] $message';
    if (error != null) return '$base\n  ERROR: $error';
    return base;
  }
}
