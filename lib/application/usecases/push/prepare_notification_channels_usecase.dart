import 'package:flutterbase/application/ports/app_logger.dart';
import 'package:flutterbase/application/ports/notification_channels.dart';

/// Creates the device's notification channels, in named groups, on each
/// start and after a change of language (docs/adr/0014-*).
///
/// FCM shows a message in the channel the manifest (or the server) names only
/// once the app has created it; before that it falls back to a channel of its
/// own, "Miscellaneous", listed under a nameless "Other" in the settings.
final class PrepareNotificationChannelsUseCase {
  const PrepareNotificationChannelsUseCase(this._channels, this._logger);

  /// FCM's own fallback channel (`fcm_fallback_notification_channel`, named
  /// "Miscellaneous"), where the template's notifications went before
  /// docs/adr/0014. Removed, so the settings no longer list it under "Other".
  static const String fcmFallbackChannelId =
      'fcm_fallback_notification_channel';

  final NotificationChannels _channels;
  final AppLogger _logger;

  /// Never throws: the app works without the channels, and FCM falls back to
  /// its own.
  Future<void> execute(
    List<DeviceNotificationChannelGroup> groups, {
    List<String> retiredChannelIds = const <String>[],
  }) async {
    try {
      await _channels.prepare(
        groups,
        retiredChannelIds: <String>[fcmFallbackChannelId, ...retiredChannelIds],
      );
      final count = groups.fold(0, (sum, g) => sum + g.channels.length);
      _logger.info(
        '[Notifications] $count channels ready in ${groups.length} groups',
      );
    } on Exception catch (e) {
      _logger.error('[Notifications] channels not created', error: e);
    }
  }
}
