import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutterbase/application/ports/notification_channels.dart';

/// [NotificationChannels] on `flutter_local_notifications`
/// (docs/adr/0014-notification-channel-groups.md).
///
/// Only creates and removes channels; the app posts nothing itself — FCM
/// shows the notifications, in the channel the manifest names by default.
/// Creating a channel needs neither the plugin's `initialize` nor the
/// notification permission.
final class LocalNotificationChannels implements NotificationChannels {
  LocalNotificationChannels({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  static Importance importanceOf(DeviceNotificationImportance importance) =>
      switch (importance) {
        DeviceNotificationImportance.high => Importance.high,
        DeviceNotificationImportance.normal => Importance.defaultImportance,
        DeviceNotificationImportance.low => Importance.low,
      };

  /// The channel Android keeps for [channel], inside [group].
  static AndroidNotificationChannel androidChannelOf(
    DeviceNotificationChannelGroup group,
    DeviceNotificationChannel channel,
  ) => AndroidNotificationChannel(
    channel.id,
    channel.name,
    description: channel.description,
    groupId: group.id,
    importance: importanceOf(channel.importance),
    playSound: channel.importance != DeviceNotificationImportance.low,
    enableVibration: channel.importance != DeviceNotificationImportance.low,
  );

  @override
  Future<void> prepare(
    List<DeviceNotificationChannelGroup> groups, {
    List<String> retiredChannelIds = const <String>[],
  }) async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) return;
    for (final group in groups) {
      // ⚠ Before its channels: a channel names its group, which must exist.
      await android.createNotificationChannelGroup(
        AndroidNotificationChannelGroup(group.id, group.name),
      );
      for (final channel in group.channels) {
        await android.createNotificationChannel(
          androidChannelOf(group, channel),
        );
      }
    }
    for (final id in retiredChannelIds) {
      await android.deleteNotificationChannel(channelId: id);
    }
  }
}
