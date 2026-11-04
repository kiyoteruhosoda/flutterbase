import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutterbase/application/ports/notification_channels.dart';
import 'package:flutterbase/infrastructure/notifications/local_notification_channels.dart';

const MethodChannel channel = MethodChannel(
  'dexterous.com/flutter/local_notifications',
);

const List<DeviceNotificationChannelGroup> groups = [
  DeviceNotificationChannelGroup(
    id: 'app',
    name: 'フラッターベース',
    channels: [
      DeviceNotificationChannel(
        id: 'server_notices',
        name: 'お知らせ',
        description: 'Web 版から届くお知らせ',
      ),
      DeviceNotificationChannel(
        id: 'quiet_digest',
        name: 'まとめ',
        importance: DeviceNotificationImportance.low,
      ),
    ],
  ),
  DeviceNotificationChannelGroup(
    id: 'reminders',
    name: 'リマインダー',
    channels: [
      DeviceNotificationChannel(
        id: 'reminder_due',
        name: '期限',
        importance: DeviceNotificationImportance.high,
      ),
    ],
  ),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late List<MethodCall> calls;

  setUp(() {
    calls = <MethodCall>[];
    // The Android side of the plugin, as the app registers it on a device.
    FlutterLocalNotificationsPlatform.instance =
        AndroidFlutterLocalNotificationsPlugin();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  Map<String, Object?> argsOf(MethodCall call) =>
      Map<String, Object?>.from(call.arguments as Map<Object?, Object?>);

  test('creates each group before the channels that name it', () async {
    await LocalNotificationChannels().prepare(groups);

    expect(calls.map((c) => '${c.method} ${argsOf(c)['id']}').toList(), [
      'createNotificationChannelGroup app',
      'createNotificationChannel server_notices',
      'createNotificationChannel quiet_digest',
      'createNotificationChannelGroup reminders',
      'createNotificationChannel reminder_due',
    ]);
  });

  test('names the groups and channels, and puts each channel in its '
      'group', () async {
    await LocalNotificationChannels().prepare(groups);

    final made = calls.map(argsOf).toList();
    expect(made[0], containsPair('name', 'フラッターベース'));
    expect(made[1], containsPair('name', 'お知らせ'));
    expect(made[1], containsPair('description', 'Web 版から届くお知らせ'));
    expect(made[1], containsPair('groupId', 'app'));
    expect(made[4], containsPair('groupId', 'reminders'));
  });

  test('rings by importance; a low channel makes no sound', () async {
    await LocalNotificationChannels().prepare(groups);

    final made = calls.map(argsOf).toList();
    expect(
      made[1],
      containsPair('importance', Importance.defaultImportance.value),
    );
    expect(made[1], containsPair('playSound', true));
    expect(made[2], containsPair('importance', Importance.low.value));
    expect(made[2], containsPair('playSound', false));
    expect(made[2], containsPair('enableVibration', false));
    expect(made[4], containsPair('importance', Importance.high.value));
  });

  test('removes the retired channels after creating the new ones', () async {
    await LocalNotificationChannels().prepare(
      groups,
      retiredChannelIds: ['fcm_fallback_notification_channel', 'old'],
    );

    final deletes = calls
        .where((c) => c.method == 'deleteNotificationChannel')
        .map((c) => c.arguments)
        .toList();
    expect(deletes, ['fcm_fallback_notification_channel', 'old']);
    expect(calls.last.method, 'deleteNotificationChannel');
    expect(calls.first.method, 'createNotificationChannelGroup');
  });

  test('never initializes the plugin: it posts nothing itself', () async {
    await LocalNotificationChannels().prepare(groups);
    expect(calls.map((c) => c.method), isNot(contains('initialize')));
  });
}
