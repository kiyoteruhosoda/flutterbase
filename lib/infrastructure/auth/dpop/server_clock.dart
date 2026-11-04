import 'dart:io' show HttpDate, HttpException;

/// The time the servers go by, learnt from their `Date` headers.
///
/// A DPoP proof carries the phone's idea of "now" (`iat`), and assay and the
/// web app accept it only from 120 s before to 60 s after their own clocks
/// (assay ADR-0075). A phone whose clock is off by more would fail every
/// call, so the proofs use this clock instead of the phone's.
final class ServerClock {
  ServerClock({DateTime Function()? now}) : _now = now ?? DateTime.now;

  /// Below this the difference is the `Date` header's one-second resolution
  /// and the network's delay, not a wrong clock.
  static const Duration _tolerance = Duration(seconds: 5);

  final DateTime Function() _now;
  Duration _offset = Duration.zero;

  /// UTC, corrected by the last observed server time.
  DateTime now() => _now().toUtc().add(_offset);

  /// Learns from a response's `Date` header (ignored when missing or bad).
  void observe(Map<String, String> headers) {
    final date = headers['date'];
    if (date == null) return;
    final DateTime server;
    try {
      server = HttpDate.parse(date);
    } on FormatException {
      return;
    } on HttpException {
      return;
    }
    final difference = server.difference(_now().toUtc());
    _offset = difference.abs() > _tolerance ? difference : Duration.zero;
  }
}
