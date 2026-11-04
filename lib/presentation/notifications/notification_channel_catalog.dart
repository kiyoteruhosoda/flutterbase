import 'package:flutterbase/application/ports/notification_channels.dart';
import 'package:flutterbase/presentation/l10n/app_localizations.dart';

/// Every notification channel the app has, and the groups that gather them
/// in the system settings (docs/adr/0014-notification-channel-groups.md).
///
/// **A derived app adds its own channels here** — to [groupsFor], in a group
/// of their own or in [appGroupId] — and lists in [retiredChannelIds] the ids
/// it stops using. Rules:
///
/// - Ids never change once released: Android keeps the person's settings
///   (switched off, made quiet) by the id, and a new id starts over.
/// - Names say what the channel carries, in the app's language, and are
///   never borrowed from another channel ("warning" in one app means
///   something else in the next).
/// - The group's heading is the app's name ([AppLocalizations.appName]), so
///   renaming the app renames it; a derived app may name its own groups.
abstract final class NotificationChannelCatalog {
  /// The app's own group. Its heading is the app's name.
  static const String appGroupId = 'app';

  /// The paired web app's notices (docs/adr/0009-*, 0010-*). FCM shows them
  /// here: the manifest's `default_notification_channel_id` names this id,
  /// since the server sends no channel of its own.
  static const String serverNoticesChannelId = 'server_notices';

  /// Channels of earlier builds to remove. FCM's own fallback
  /// ("Miscellaneous") is always removed, by the use case.
  static const List<String> retiredChannelIds = <String>[];

  /// The groups and channels, named in [l10n]'s language.
  static List<DeviceNotificationChannelGroup> groupsFor(
    AppLocalizations l10n,
  ) => <DeviceNotificationChannelGroup>[
    DeviceNotificationChannelGroup(
      id: appGroupId,
      name: l10n.appName,
      channels: <DeviceNotificationChannel>[
        DeviceNotificationChannel(
          id: serverNoticesChannelId,
          name: l10n.notificationChannelNotices,
          description: l10n.notificationChannelNoticesDescription,
        ),
      ],
    ),
  ];
}
