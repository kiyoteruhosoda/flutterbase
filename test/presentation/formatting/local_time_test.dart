import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutterbase/presentation/formatting/local_time.dart';
import 'package:flutterbase/presentation/widgets/maintenance/maintenance_view.dart';
import 'package:flutterbase/presentation/widgets/notices/notice_list_sheet.dart';

final _at = DateTime.utc(2026, 11, 4, 22);

/// The zone label the device running the test is in at [_at].
String get _zone => utcOffsetLabel(_at.toLocal().timeZoneOffset);

Future<BuildContext> _context(WidgetTester tester) async {
  late BuildContext captured;
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) {
          captured = context;
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  return captured;
}

void main() {
  group('utcOffsetLabel', () {
    test('whole hours east of UTC', () {
      expect(utcOffsetLabel(const Duration(hours: 9)), 'UTC+9');
      expect(utcOffsetLabel(const Duration(hours: 14)), 'UTC+14');
    });

    test('hours and minutes', () {
      expect(utcOffsetLabel(const Duration(hours: 5, minutes: 30)), 'UTC+5:30');
      expect(utcOffsetLabel(const Duration(hours: 5, minutes: 45)), 'UTC+5:45');
      expect(
        utcOffsetLabel(const Duration(hours: 10, minutes: 5)),
        'UTC+10:05',
      );
    });

    test('west of UTC', () {
      expect(utcOffsetLabel(const Duration(hours: -5)), 'UTC-5');
      expect(
        utcOffsetLabel(const Duration(hours: -3, minutes: -30)),
        'UTC-3:30',
      );
    });

    test('UTC itself has no sign or number', () {
      expect(utcOffsetLabel(Duration.zero), 'UTC');
    });
  });

  group('formatLocalDateTime', () {
    testWidgets('is local time with its zone, at each date length', (
      tester,
    ) async {
      final context = await _context(tester);
      final local = _at.toLocal();
      final material = MaterialLocalizations.of(context);
      final time = material.formatTimeOfDay(
        TimeOfDay.fromDateTime(local),
        alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
      );

      expect(
        formatLocalDateTime(context, _at),
        '${material.formatShortDate(local)} $time $_zone',
      );
      expect(
        formatLocalDateTime(context, _at, date: LocalDateLength.medium),
        '${material.formatMediumDate(local)} $time $_zone',
      );
      expect(
        formatLocalDateTime(context, _at, date: LocalDateLength.full),
        '${material.formatFullDate(local)} $time $_zone',
      );
    });

    testWidgets('the bell and the maintenance screen both say the zone', (
      tester,
    ) async {
      final context = await _context(tester);
      expect(formatNoticeTime(context, _at), endsWith(' $_zone'));
      expect(formatLocalInstant(context, _at), endsWith(' $_zone'));
    });
  });
}
