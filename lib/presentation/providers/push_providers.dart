import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutterbase/application/ports/push_messaging.dart';
import 'package:flutterbase/application/usecases/push/open_push_tap_usecase.dart';
import 'package:flutterbase/application/usecases/push/register_for_push_usecase.dart';
import 'package:flutterbase/application/usecases/push/unregister_from_push_usecase.dart';
import 'package:flutterbase/presentation/providers/app_update_providers.dart';
import 'package:flutterbase/presentation/providers/notice_providers.dart';

// ─── Seams ─────────────────────────────────────────────────────────────────
//
// Null unless the build carries the Firebase settings *and* the sign-in, and
// Firebase started (docs/adr/0010-notifications-through-fcm.md). Everything
// below does nothing while they are null.

final Provider<PushMessaging?> pushMessagingProvider = Provider<PushMessaging?>(
  (ref) => null,
);

final Provider<RegisterForPushUseCase?> registerForPushUseCaseProvider =
    Provider<RegisterForPushUseCase?>((ref) => null);

final Provider<UnregisterFromPushUseCase?> unregisterFromPushUseCaseProvider =
    Provider<UnregisterFromPushUseCase?>((ref) => null);

final Provider<OpenPushTapUseCase?> openPushTapUseCaseProvider =
    Provider<OpenPushTapUseCase?>((ref) => null);

// ─── State ─────────────────────────────────────────────────────────────────

/// Whether this device is registered for the signed-in person's notices.
final NotifierProvider<PushRegistrationNotifier, bool>
pushRegistrationProvider = NotifierProvider<PushRegistrationNotifier, bool>(
  PushRegistrationNotifier.new,
);

/// Keeps this device registered with the paired web app and answers taps on
/// device notifications.
///
/// - [start] (once, from the main screen) listens for new FCM tokens, taps,
///   and messages arriving in the foreground, and answers the tap that
///   launched the app
/// - [register] runs on start and after a sign-in
/// - [unregister] runs before a sign-out, with the person's token still valid
class PushRegistrationNotifier extends Notifier<bool> {
  final List<StreamSubscription<Object?>> _subscriptions = [];
  bool _started = false;

  @override
  bool build() {
    ref.onDispose(() {
      for (final subscription in _subscriptions) {
        unawaited(subscription.cancel());
      }
      _subscriptions.clear();
    });
    return false;
  }

  /// Starts listening. Does nothing when FCM is off, or the second time.
  Future<void> start() async {
    final messaging = ref.read(pushMessagingProvider);
    if (messaging == null || _started) return;
    _started = true;
    _subscriptions
      ..add(messaging.tokenRefreshes.listen((token) => register(token: token)))
      ..add(messaging.taps.listen(_onTap))
      ..add(messaging.foregroundMessages.listen((_) => _refreshBell()));
    final initial = await messaging.initialTap();
    if (initial != null) await _onTap(initial);
  }

  /// Registers this device as the signed-in person's. Does nothing when FCM
  /// is off or nobody is signed in.
  Future<bool> register({String? token}) async {
    final useCase = ref.read(registerForPushUseCaseProvider);
    if (useCase == null || !await isSignedIn(ref)) return false;
    final registered = await useCase.execute(token: token);
    if (ref.mounted) state = registered;
    return registered;
  }

  /// Takes this device off the signed-in person's list. Never throws.
  Future<void> unregister() async {
    final useCase = ref.read(unregisterFromPushUseCaseProvider);
    if (useCase == null) return;
    await useCase.execute();
    if (ref.mounted) state = false;
  }

  Future<void> _onTap(PushTap tap) async {
    final useCase = ref.read(openPushTapUseCaseProvider);
    if (useCase == null) return;
    await useCase.execute(tap);
    await _refreshBell();
  }

  Future<void> _refreshBell() async {
    if (!ref.mounted) return;
    await ref.read(noticeInboxProvider.notifier).refresh(force: true);
  }
}
