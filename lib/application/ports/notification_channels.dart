/// How loudly Android rings a channel. The person can change it in the
/// system settings afterwards; Android keeps their choice over the app's.
enum DeviceNotificationImportance {
  /// Sound, and a banner over the screen.
  high,

  /// Sound, no banner.
  normal,

  /// No sound; only in the notification shade.
  low,
}

/// One Android notification channel: a line in the system settings that the
/// person can switch off or make quieter on its own (docs/adr/0014-*).
final class DeviceNotificationChannel {
  const DeviceNotificationChannel({
    required this.id,
    required this.name,
    this.description,
    this.importance = DeviceNotificationImportance.normal,
  });

  /// Never changes once released: Android keeps the person's settings by it,
  /// and the server or the manifest names the channel by it.
  final String id;

  /// What the system settings show, in the app's language. Say what the
  /// channel carries; never reuse another channel's name.
  final String name;

  /// The line under [name] in the system settings.
  final String? description;

  final DeviceNotificationImportance importance;
}

/// A named heading in the system settings that gathers channels. Without
/// one, Android lists the app's channels under a nameless "Other".
final class DeviceNotificationChannelGroup {
  const DeviceNotificationChannelGroup({
    required this.id,
    required this.name,
    required this.channels,
  });

  /// Never changes once released, as [DeviceNotificationChannel.id].
  final String id;

  /// The heading, in the app's language.
  final String name;

  final List<DeviceNotificationChannel> channels;
}

/// The device's notification channels and their groups
/// (docs/adr/0014-notification-channel-groups.md).
///
/// An outbound port: `infrastructure/notifications/` creates them through
/// `flutter_local_notifications`.
abstract interface class NotificationChannels {
  /// Creates [groups] and their channels — or renames them, when they exist
  /// (after a change of language) — and then removes the channels in
  /// [retiredChannelIds]. Safe to call on every start.
  Future<void> prepare(
    List<DeviceNotificationChannelGroup> groups, {
    List<String> retiredChannelIds = const <String>[],
  });
}
