import 'package:flutter_test/flutter_test.dart';
import 'package:flutterbase/application/ports/notification_channels.dart';
import 'package:flutterbase/application/usecases/push/prepare_notification_channels_usecase.dart';
import 'package:flutterbase/domain/value_objects/log_level.dart';

import '../../../support/fakes.dart';
import '../../../support/recording_app_logger.dart';

const List<DeviceNotificationChannelGroup> groups = [
  DeviceNotificationChannelGroup(
    id: 'app',
    name: 'FlutterBase',
    channels: [
      DeviceNotificationChannel(id: 'server_notices', name: 'Notices'),
    ],
  ),
];

void main() {
  late FakeNotificationChannels channels;
  late RecordingAppLogger logger;
  late PrepareNotificationChannelsUseCase useCase;

  setUp(() {
    channels = FakeNotificationChannels();
    logger = RecordingAppLogger();
    useCase = PrepareNotificationChannelsUseCase(channels, logger);
  });

  test('creates the groups as given', () async {
    await useCase.execute(groups);
    expect(channels.prepared, [groups]);
    expect(
      logger.messagesAt(LogLevel.info),
      contains('[Notifications] 1 channels ready in 1 groups'),
    );
  });

  test('always removes FCM\'s own fallback channel, before the app\'s '
      'retired ones', () async {
    await useCase.execute(groups, retiredChannelIds: ['old_channel']);
    expect(channels.retired.single, [
      'fcm_fallback_notification_channel',
      'old_channel',
    ]);
  });

  test('logs a failure instead of throwing', () async {
    channels.failure = Exception('no notification manager');
    await useCase.execute(groups);
    expect(
      logger.messagesAt(LogLevel.error),
      contains('[Notifications] channels not created'),
    );
  });
}
