import 'package:flutter_test/flutter_test.dart';
import 'package:flutterbase/shared/logging/app_logger.dart';

void main() {
  // Use a fresh logger state per test group by clearing the buffer.
  setUp(() => AppLogger.instance.clearBuffer());

  group('AppLogger — in-memory buffer', () {
    test('starts empty after clear', () {
      expect(AppLogger.instance.entries, isEmpty);
    });

    test('verbose logs are stored', () {
      AppLogger.instance.verbose('verbose message');
      expect(AppLogger.instance.entries, hasLength(1));
      expect(AppLogger.instance.entries.first.level, equals(LogLevel.verbose));
      expect(AppLogger.instance.entries.first.message, equals('verbose message'));
    });

    test('debug logs are stored', () {
      AppLogger.instance.debug('debug message');
      final entries = AppLogger.instance.entries;
      expect(entries, hasLength(1));
      expect(entries.first.level, equals(LogLevel.debug));
    });

    test('info logs are stored', () {
      AppLogger.instance.info('info message');
      expect(AppLogger.instance.entries.first.level, equals(LogLevel.info));
    });

    test('warning logs are stored', () {
      AppLogger.instance.warning('warn message');
      expect(AppLogger.instance.entries.first.level, equals(LogLevel.warning));
    });

    test('error logs are stored with error object', () {
      final err = Exception('test error');
      AppLogger.instance.error('error message', error: err);
      final entry = AppLogger.instance.entries.first;
      expect(entry.level, equals(LogLevel.error));
      expect(entry.error, equals(err));
    });

    test('multiple entries accumulate in order', () {
      AppLogger.instance.info('first');
      AppLogger.instance.info('second');
      AppLogger.instance.info('third');
      final entries = AppLogger.instance.entries;
      expect(entries, hasLength(3));
      expect(entries[0].message, equals('first'));
      expect(entries[1].message, equals('second'));
      expect(entries[2].message, equals('third'));
    });

    test('buffer caps at maxBufferEntries', () {
      const limit = AppLogger.maxBufferEntries;
      for (var i = 0; i <= limit + 10; i++) {
        AppLogger.instance.debug('entry $i');
      }
      expect(AppLogger.instance.entries.length, equals(limit));
    });

    test('clearBuffer empties the buffer', () {
      AppLogger.instance.info('test');
      AppLogger.instance.clearBuffer();
      expect(AppLogger.instance.entries, isEmpty);
    });
  });

  group('AppLogger — level filtering', () {
    setUp(() {
      AppLogger.instance.clearBuffer();
      AppLogger.instance.verbose('v');
      AppLogger.instance.debug('d');
      AppLogger.instance.info('i');
      AppLogger.instance.warning('w');
      AppLogger.instance.error('e');
    });

    test('entriesForLevel(null) returns all entries', () {
      expect(AppLogger.instance.entriesForLevel(null), hasLength(5));
    });

    test('entriesForLevel(verbose) returns only verbose', () {
      final filtered = AppLogger.instance.entriesForLevel(LogLevel.verbose);
      expect(filtered, hasLength(1));
      expect(filtered.first.level, equals(LogLevel.verbose));
    });

    test('entriesForLevel(error) returns only errors', () {
      final filtered = AppLogger.instance.entriesForLevel(LogLevel.error);
      expect(filtered, hasLength(1));
      expect(filtered.first.level, equals(LogLevel.error));
    });
  });

  group('LogEntry', () {
    test('toLogLine includes level label and message', () {
      final entry = LogEntry(
        timestamp: DateTime(2026, 4, 7, 12, 0, 0),
        level: LogLevel.info,
        message: 'hello',
      );
      final line = entry.toLogLine();
      expect(line, contains('[I]'));
      expect(line, contains('hello'));
    });

    test('toLogLine includes error when present', () {
      final entry = LogEntry(
        timestamp: DateTime(2026, 4, 7, 12, 0, 0),
        level: LogLevel.error,
        message: 'fail',
        error: Exception('oops'),
      );
      final line = entry.toLogLine();
      expect(line, contains('ERROR'));
      expect(line, contains('oops'));
    });

    test('levelLabel returns single-character code', () {
      expect(
        LogEntry(timestamp: DateTime.now(), level: LogLevel.verbose, message: '').levelLabel,
        equals('V'),
      );
      expect(
        LogEntry(timestamp: DateTime.now(), level: LogLevel.debug, message: '').levelLabel,
        equals('D'),
      );
      expect(
        LogEntry(timestamp: DateTime.now(), level: LogLevel.info, message: '').levelLabel,
        equals('I'),
      );
      expect(
        LogEntry(timestamp: DateTime.now(), level: LogLevel.warning, message: '').levelLabel,
        equals('W'),
      );
      expect(
        LogEntry(timestamp: DateTime.now(), level: LogLevel.error, message: '').levelLabel,
        equals('E'),
      );
    });
  });
}
