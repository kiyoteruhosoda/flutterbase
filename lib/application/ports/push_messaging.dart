/// A notification the person tapped (from the tray, or the one that launched
/// the app).
///
/// Carries what the paired web app put in the FCM message's `data`: the
/// notice's id and, when it has one, its link (`/items` or `https://…`).
final class PushTap {
  const PushTap({required this.noticeId, this.linkUrl});

  final int? noticeId;
  final String? linkUrl;

  @override
  bool operator ==(Object other) =>
      other is PushTap &&
      other.noticeId == noticeId &&
      other.linkUrl == linkUrl;

  @override
  int get hashCode => Object.hash(noticeId, linkUrl);

  @override
  String toString() => 'PushTap(#$noticeId, $linkUrl)';
}

/// The device's side of notifications through FCM.
///
/// An outbound port: `infrastructure/push/` supplies the implementation
/// (`firebase_messaging`). Only registered when the build carries the
/// Firebase settings (`PushSettings.isEnabled`) and the sign-in.
/// See `docs/adr/0010-notifications-through-fcm.md`.
abstract interface class PushMessaging {
  /// Asks for the notification permission (Android 13+ shows a prompt once).
  /// Answers whether notifications may be shown.
  Future<bool> requestPermission();

  /// This device's FCM registration token, or null when there is none yet.
  Future<String?> token();

  /// New tokens FCM hands out later (reinstalls, restores, rotations).
  Stream<String> get tokenRefreshes;

  /// Notifications tapped while the app was running or in the background.
  Stream<PushTap> get taps;

  /// The notification whose tap launched the app, if any. Answers it once.
  Future<PushTap?> initialTap();

  /// A notification arrived while the app is in the foreground (Android shows
  /// nothing then; the app refreshes its bell instead).
  Stream<void> get foregroundMessages;
}
