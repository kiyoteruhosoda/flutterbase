import 'package:flutter_test/flutter_test.dart';
import 'package:flutterbase/application/ports/push_messaging.dart';
import 'package:flutterbase/application/usecases/push/open_push_tap_usecase.dart';
import 'package:flutterbase/application/usecases/push/register_for_push_usecase.dart';
import 'package:flutterbase/application/usecases/push/unregister_from_push_usecase.dart';
import 'package:flutterbase/domain/errors/app_error.dart';
import 'package:flutterbase/domain/value_objects/log_level.dart';

import '../../../support/fakes.dart';
import '../../../support/recording_app_logger.dart';

final Uri base = Uri.parse('https://web.example.com');

void main() {
  late FakePushMessaging messaging;
  late FakeDeviceRegistrationRepository devices;
  late RecordingAppLogger logger;

  setUp(() {
    messaging = FakePushMessaging();
    devices = FakeDeviceRegistrationRepository();
    logger = RecordingAppLogger();
  });

  group('RegisterForPushUseCase', () {
    RegisterForPushUseCase useCase() =>
        RegisterForPushUseCase(messaging, devices, logger);

    test('asks for the permission and registers the token', () async {
      expect(await useCase().execute(), isTrue);
      expect(messaging.permissionRequests, 1);
      expect(devices.registered, ['fcm-token-1']);
    });

    test('registers a token FCM handed out later', () async {
      expect(await useCase().execute(token: 'fcm-token-2'), isTrue);
      expect(devices.registered, ['fcm-token-2']);
    });

    test('does not register when the permission is declined', () async {
      messaging.allowed = false;
      expect(await useCase().execute(), isFalse);
      expect(devices.registered, isEmpty);
    });

    test('does not register without a token', () async {
      messaging.currentToken = null;
      expect(await useCase().execute(), isFalse);
      expect(devices.registered, isEmpty);
      expect(logger.messagesAt(LogLevel.warning), hasLength(1));
    });

    test('logs a refused registration instead of throwing', () async {
      devices.failure = const InfrastructureError('503');
      expect(await useCase().execute(), isFalse);
      expect(logger.messagesAt(LogLevel.warning), hasLength(1));
    });
  });

  group('UnregisterFromPushUseCase', () {
    UnregisterFromPushUseCase useCase() =>
        UnregisterFromPushUseCase(messaging, devices, logger);

    test('takes the token off the list', () async {
      await useCase().execute();
      expect(devices.unregistered, ['fcm-token-1']);
    });

    test('never throws: signing out must go on', () async {
      devices.failure = const InfrastructureError('offline');
      await useCase().execute();
      expect(logger.messagesAt(LogLevel.warning), hasLength(1));
    });

    test('does nothing without a token', () async {
      messaging.currentToken = null;
      await useCase().execute();
      expect(devices.unregistered, isEmpty);
    });
  });

  group('OpenPushTapUseCase', () {
    late FakeAppNoticeRepository notices;
    late RecordingExternalLinkLauncher launcher;

    setUp(() {
      notices = FakeAppNoticeRepository();
      launcher = RecordingExternalLinkLauncher();
    });

    OpenPushTapUseCase useCase() =>
        OpenPushTapUseCase(notices, launcher, base, logger);

    test('reads the notice and opens a path on the web app', () async {
      final opened = await useCase().execute(
        const PushTap(noticeId: 7, linkUrl: '/items'),
      );
      expect(opened, isTrue);
      expect(notices.read, [7]);
      expect(launcher.opened, [Uri.parse('https://web.example.com/items')]);
    });

    test('opens an absolute https link as it is', () async {
      await useCase().execute(
        const PushTap(noticeId: 7, linkUrl: 'https://other.example.com/x'),
      );
      expect(launcher.opened, [Uri.parse('https://other.example.com/x')]);
    });

    test('refuses a link that is not https', () async {
      final opened = await useCase().execute(
        const PushTap(noticeId: 7, linkUrl: 'javascript:alert(1)'),
      );
      expect(opened, isFalse);
      expect(launcher.opened, isEmpty);
      expect(notices.read, [7]);
    });

    test('a failed read does not stop the link', () async {
      notices.failure = const InfrastructureError('offline');
      final opened = await useCase().execute(
        const PushTap(noticeId: 7, linkUrl: '/items'),
      );
      expect(opened, isTrue);
    });

    test('without a link only reads the notice', () async {
      expect(await useCase().execute(const PushTap(noticeId: 7)), isFalse);
      expect(notices.read, [7]);
      expect(launcher.opened, isEmpty);
    });
  });
}
