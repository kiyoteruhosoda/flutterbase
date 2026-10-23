/// Why the paired web app is not answering.
enum ServiceOutageReason {
  /// Closed on purpose: a maintenance was declared at the edge.
  maintenance,

  /// The app behind the edge is not running.
  stopped,
}

/// The paired web app said it is out of service.
///
/// Built from the edge's `503` JSON
/// (`{"error": "service_unavailable", "reason": "maintenance" | "stopped",
/// ...}`; docs/adr/0011-in-app-maintenance-screen.md). Everything except
/// [reason] is optional: a stopped app sends none of it, and an older edge
/// sends no [title] or [body].
final class ServiceOutage {
  const ServiceOutage({
    required this.reason,
    this.title,
    this.body,
    this.message,
    this.until,
  });

  final ServiceOutageReason reason;

  /// Heading written by whoever declared the maintenance.
  final String? title;

  /// Longer text written by whoever declared the maintenance.
  final String? body;

  /// The reason given when the maintenance was declared.
  final String? message;

  /// When the service is expected back (UTC).
  final DateTime? until;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ServiceOutage &&
          other.reason == reason &&
          other.title == title &&
          other.body == body &&
          other.message == message &&
          other.until == until);

  @override
  int get hashCode => Object.hash(reason, title, body, message, until);

  @override
  String toString() => 'ServiceOutage(${reason.name}, until: $until)';
}
