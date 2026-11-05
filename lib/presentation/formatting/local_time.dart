import 'package:flutter/material.dart';

/// The one place that turns an instant into text on screen (ADR-0016).
///
/// The app keeps UTC; only here does it become the viewer's local time, and
/// the zone is always written after it, so a time copied out of the app still
/// says which clock it was read on. `tool/check_architecture.dart` rejects
/// `toLocal()` and the `MaterialLocalizations` date and time formatters
/// anywhere else under lib/.

/// How much of the date to write before the time.
enum LocalDateLength {
  /// `11/5/2026` — lists and compact rows.
  short,

  /// `Nov 5, 2026` — a single prominent time.
  medium,

  /// `Thursday, November 5, 2026` — a detail page.
  full,
}

/// The offset from UTC as people write it: `UTC+9`, `UTC+5:30`, `UTC-3:30`,
/// or `UTC` when there is none.
///
/// A number, not a name like `JST`: the names a device knows differ from one
/// device to the next, and some show none at all.
String utcOffsetLabel(Duration offset) {
  final totalMinutes = offset.inMinutes;
  if (totalMinutes == 0) return 'UTC';
  final sign = totalMinutes < 0 ? '-' : '+';
  final hours = totalMinutes.abs() ~/ 60;
  final minutes = totalMinutes.abs() % 60;
  final tail = minutes == 0 ? '' : ':${minutes.toString().padLeft(2, '0')}';
  return 'UTC$sign$hours$tail';
}

/// [instant] in the device's time zone, in the app's language, followed by
/// the zone it is in: `11/5/2026 7:00 AM UTC+9`.
String formatLocalDateTime(
  BuildContext context,
  DateTime instant, {
  LocalDateLength date = LocalDateLength.short,
}) {
  final local = instant.toLocal();
  final material = MaterialLocalizations.of(context);
  final day = switch (date) {
    LocalDateLength.short => material.formatShortDate(local),
    LocalDateLength.medium => material.formatMediumDate(local),
    LocalDateLength.full => material.formatFullDate(local),
  };
  final time = material.formatTimeOfDay(
    TimeOfDay.fromDateTime(local),
    alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
  );
  return '$day $time ${utcOffsetLabel(local.timeZoneOffset)}';
}
