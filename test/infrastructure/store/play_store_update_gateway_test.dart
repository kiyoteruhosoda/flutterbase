import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutterbase/application/ports/store_update_gateway.dart';
import 'package:flutterbase/domain/value_objects/log_level.dart';
import 'package:flutterbase/infrastructure/store/play_store_update_gateway.dart';

import '../../support/recording_app_logger.dart';

/// The `in_app_update` plugin's method channel.
const MethodChannel channel = MethodChannel('de.ffuf.in_app_update/methods');

/// What Play answers to `checkForUpdate`, in the plugin's wire format.
Map<String, Object?> playAnswer({
  int availability = 1, // updateNotAvailable
  bool flexibleAllowed = false,
  int installStatus = 0, // unknown
}) => <String, Object?>{
  'updateAvailability': availability,
  'immediateAllowed': false,
  'flexibleAllowed': flexibleAllowed,
  'availableVersionCode': 43,
  'installStatus': installStatus,
  'packageName': 'com.example.app',
  'clientVersionStalenessDays': null,
  'updatePriority': 0,
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late RecordingAppLogger logger;
  late PlayStoreUpdateGateway gateway;
  final calls = <String>[];

  void answer(Object? Function(MethodCall call) handler) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call.method);
          return handler(call);
        });
  }

  setUp(() {
    calls.clear();
    logger = RecordingAppLogger();
    gateway = PlayStoreUpdateGateway(logger);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('check', () {
    test('a newer build that may download in the background', () async {
      answer((_) => playAnswer(availability: 2, flexibleAllowed: true));
      expect(await gateway.check(), StoreUpdateStatus.available);
      expect(logger.messagesAt(LogLevel.info).single, contains('43'));
    });

    test('a newer build only offered as an immediate update is none', () async {
      answer((_) => playAnswer(availability: 2));
      expect(await gateway.check(), StoreUpdateStatus.none);
    });

    test('a build already downloaded waits to be installed', () async {
      answer((_) => playAnswer(installStatus: 11));
      expect(await gateway.check(), StoreUpdateStatus.downloaded);
    });

    test('no newer build is none', () async {
      answer((_) => playAnswer());
      expect(await gateway.check(), StoreUpdateStatus.none);
    });

    test('a copy Play did not install is none, not an error', () async {
      answer((_) => throw PlatformException(code: 'TASK_FAILURE'));
      expect(await gateway.check(), StoreUpdateStatus.none);
      expect(logger.messagesAt(LogLevel.debug).single, contains('Play'));
    });

    test('no platform implementation is none', () async {
      // No handler on the channel: the test host has no plugin.
      expect(await gateway.check(), StoreUpdateStatus.none);
    });
  });

  group('download', () {
    test('true when Play has fetched it', () async {
      answer((_) => null);
      expect(await gateway.download(), isTrue);
      expect(calls, ['startFlexibleUpdate']);
    });

    test('false when the person declined', () async {
      answer((_) => throw PlatformException(code: 'USER_DENIED_UPDATE'));
      expect(await gateway.download(), isFalse);
      expect(logger.messagesAt(LogLevel.info).single, contains('did not'));
    });

    test('false when Play refused', () async {
      answer((_) => throw PlatformException(code: 'TASK_FAILURE'));
      expect(await gateway.download(), isFalse);
      expect(logger.messagesAt(LogLevel.warning).single, contains('refused'));
    });

    test('false with no platform implementation', () async {
      expect(await gateway.download(), isFalse);
    });
  });

  group('install', () {
    test('asks Play to finish the update', () async {
      answer((_) => null);
      await gateway.install();
      expect(calls, ['completeFlexibleUpdate']);
    });

    test('a refusal is logged, not thrown', () async {
      answer((_) => throw PlatformException(code: 'TASK_FAILURE'));
      await gateway.install();
      expect(logger.messagesAt(LogLevel.warning).single, contains('install'));
    });

    test('no platform implementation is not thrown', () async {
      await gateway.install();
    });
  });
}
