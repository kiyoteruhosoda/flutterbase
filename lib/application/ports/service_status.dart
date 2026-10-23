import 'package:flutterbase/domain/entities/service_outage.dart';

/// Whether the paired web app is in service.
///
/// An outbound port: `infrastructure/api/` notices the edge's `503` on every
/// call to the web app and reports it here, so the maintenance screen does not
/// depend on which screen made the call
/// (docs/adr/0011-in-app-maintenance-screen.md).
abstract interface class ServiceStatus {
  /// Every outage a call to the web app ran into, as it happens.
  Stream<ServiceOutage> get outages;

  /// Asks the web app once.
  ///
  /// Answers the outage while it is still out of service and null once it
  /// answers anything else. Throws an `InfrastructureError` when the request
  /// itself failed (no network), which says nothing either way.
  Future<ServiceOutage?> check();
}
