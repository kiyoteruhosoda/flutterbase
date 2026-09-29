/// The Firebase project that carries notifications to this app — or that there
/// is none.
///
/// All four values come from `--dart-define` at build time (`FIREBASE_*`) and
/// default to empty. **If any one is empty, notifications through FCM are
/// off**: Firebase is never started and nobody is asked for the notification
/// permission. See `docs/adr/0010-notifications-through-fcm.md`.
///
/// Pure Dart, like every value object here; the composition root builds one
/// from `AppConfig` and hands it to Infrastructure.
final class PushSettings {
  const PushSettings({
    required this.apiKey,
    required this.appId,
    required this.messagingSenderId,
    required this.projectId,
  });

  /// No FCM — what a build without the four `--dart-define`s gets.
  const PushSettings.disabled()
    : apiKey = '',
      appId = '',
      messagingSenderId = '',
      projectId = '';

  final String apiKey;
  final String appId;
  final String messagingSenderId;
  final String projectId;

  /// True only when all four values are present.
  bool get isEnabled => [
    apiKey,
    appId,
    messagingSenderId,
    projectId,
  ].every((value) => value.trim().isNotEmpty);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PushSettings &&
          other.apiKey == apiKey &&
          other.appId == appId &&
          other.messagingSenderId == messagingSenderId &&
          other.projectId == projectId);

  @override
  int get hashCode => Object.hash(apiKey, appId, messagingSenderId, projectId);

  /// Never prints the API key.
  @override
  String toString() =>
      isEnabled ? 'PushSettings($projectId)' : 'PushSettings(off)';
}
