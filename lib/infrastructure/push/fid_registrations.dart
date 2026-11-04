import 'dart:async';

/// Turns FCM's "register, then hear the Firebase Installation ID (FID) on a
/// stream" into "ask for the FID" plus "FIDs that changed later"
/// (docs/adr/0013-notify-by-installation-id.md).
///
/// FCM answers every `register()` on `onRegistered`, even when the app was
/// already registered, and also emits there when it re-registers by itself
/// (a new FID). The stream drops what arrives before anyone listens, so this
/// listens from the start and before the first `register()`.
final class FidRegistrations {
  FidRegistrations({
    required Stream<String> registered,
    required Future<void> Function() register,
    this.timeout = const Duration(seconds: 20),
  }) : _register = register {
    _subscription = registered.listen(_onRegistered);
  }

  final Future<void> Function() _register;

  /// How long [current] waits for FCM to answer a `register()`.
  final Duration timeout;

  late final StreamSubscription<String> _subscription;
  final StreamController<String> _changes =
      StreamController<String>.broadcast();
  Completer<String>? _pending;
  String? _last;

  /// Registers with FCM and answers the FID it gives, or the last one heard
  /// when FCM does not answer in time (null if there was none).
  Future<String?> current() async {
    final pending = _pending ??= Completer<String>();
    try {
      await _register();
      return await pending.future.timeout(timeout);
    } on TimeoutException {
      return _last;
    } finally {
      if (identical(_pending, pending)) _pending = null;
    }
  }

  /// FIDs FCM handed out without being asked, when they differ from the last
  /// one (a reinstall, a restore, a re-registration).
  Stream<String> get changes => _changes.stream;

  void _onRegistered(String fid) {
    final pending = _pending;
    if (pending != null && !pending.isCompleted) {
      _last = fid;
      pending.complete(fid);
      return;
    }
    if (fid == _last) return;
    _last = fid;
    _changes.add(fid);
  }

  Future<void> close() async {
    await _subscription.cancel();
    await _changes.close();
  }
}
