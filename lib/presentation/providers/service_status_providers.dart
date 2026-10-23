import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutterbase/application/usecases/service_status/check_service_usecase.dart';
import 'package:flutterbase/application/usecases/service_status/watch_service_outages_usecase.dart';
import 'package:flutterbase/domain/entities/service_outage.dart';
import 'package:flutterbase/presentation/providers/app_providers.dart';
import 'package:flutterbase/presentation/providers/auth_providers.dart';

// ─── Use-case seams ────────────────────────────────────────────────────────
//
// Overridden only when the sign-in is on: only then does the app call the
// paired web app at all. Nothing reads them otherwise
// ([ServiceOutageNotifier.build] stops first).

final Provider<WatchServiceOutagesUseCase> watchServiceOutagesUseCaseProvider =
    Provider<WatchServiceOutagesUseCase>((ref) {
      throw UnimplementedError(
        missingOverrideMessage('watchServiceOutagesUseCaseProvider'),
      );
    });

final Provider<CheckServiceUseCase> checkServiceUseCaseProvider =
    Provider<CheckServiceUseCase>((ref) {
      throw UnimplementedError(
        missingOverrideMessage('checkServiceUseCaseProvider'),
      );
    });

// ─── Screen state ──────────────────────────────────────────────────────────

/// The outage the maintenance screen shows, or null while in service.
final NotifierProvider<ServiceOutageNotifier, ServiceOutage?>
serviceOutageProvider = NotifierProvider<ServiceOutageNotifier, ServiceOutage?>(
  ServiceOutageNotifier.new,
);

/// Holds the outage the last call to the paired web app ran into
/// (docs/adr/0011-in-app-maintenance-screen.md).
///
/// Any call, from any screen, that gets the edge's `503` puts the app behind
/// the maintenance screen; [recheck] — which the screen runs every
/// [recheckInterval] — takes it away once the web app answers again.
class ServiceOutageNotifier extends Notifier<ServiceOutage?> {
  /// How often the maintenance screen asks whether the service is back.
  static const Duration recheckInterval = Duration(seconds: 90);

  @override
  ServiceOutage? build() {
    if (!ref.read(signInSettingsProvider).isEnabled) return null;
    final subscription = ref
        .read(watchServiceOutagesUseCaseProvider)
        .execute()
        .listen((outage) => state = outage);
    ref.onDispose(() => unawaited(subscription.cancel()));
    return null;
  }

  /// Asks the web app whether it is back; does nothing while in service.
  ///
  /// A failed request (no network) keeps the screen as it is: it says nothing
  /// about the service, and the next recheck asks again.
  Future<void> recheck() async {
    if (state == null) return;
    final ServiceOutage? outage;
    try {
      outage = await ref.read(checkServiceUseCaseProvider).execute();
    } on Exception {
      return;
    }
    if (ref.mounted) state = outage;
  }
}
