import 'package:flutter_test/flutter_test.dart';
import 'package:flutterbase/application/ports/push_messaging.dart';
import 'package:flutterbase/domain/entities/account.dart';
import 'package:flutterbase/presentation/providers/auth_providers.dart';
import 'package:flutterbase/presentation/providers/push_providers.dart';

import '../../support/fakes.dart';
import '../../support/test_harness.dart';

const Account kyon = Account(displayName: 'Kyon');

TestScope withPush({Account? signedIn = kyon}) => TestScope(
  authSession: FakeAuthSession(signedIn: signedIn),
  pushMessaging: FakePushMessaging(),
);

Future<void> settle() => Future<void>.delayed(Duration.zero);

void main() {
  test('does nothing in a build without FCM', () async {
    final scope = TestScope(authSession: FakeAuthSession(signedIn: kyon));
    final notifier = scope.container.read(pushRegistrationProvider.notifier);
    await notifier.start();
    expect(await notifier.register(), isFalse);
    await notifier.unregister();
    expect(scope.deviceRegistrations.registered, isEmpty);
  });

  test('registers the signed-in person\'s device', () async {
    final scope = withPush();
    final notifier = scope.container.read(pushRegistrationProvider.notifier);
    expect(await notifier.register(), isTrue);
    expect(scope.container.read(pushRegistrationProvider), isTrue);
    expect(scope.deviceRegistrations.registered, ['fcm-token-1']);
  });

  test('registers nothing while nobody is signed in', () async {
    final scope = withPush(signedIn: null);
    final notifier = scope.container.read(pushRegistrationProvider.notifier);
    expect(await notifier.register(), isFalse);
    expect(scope.pushMessaging!.permissionRequests, 0);
  });

  test('a new token from FCM is registered again', () async {
    final scope = withPush();
    await scope.container.read(pushRegistrationProvider.notifier).start();
    scope.pushMessaging!.tokenController.add('fcm-token-2');
    await settle();
    await settle();
    expect(scope.deviceRegistrations.registered, ['fcm-token-2']);
  });

  test('a tapped notification reads the notice, opens it, and reloads the '
      'bell', () async {
    final scope = withPush();
    await scope.container.read(pushRegistrationProvider.notifier).start();
    scope.pushMessaging!.tapController.add(
      const PushTap(noticeId: 7, linkUrl: '/items'),
    );
    await settle();
    await settle();
    await settle();
    expect(scope.noticeRepository.read, [7]);
    expect(scope.linkLauncher.opened, [
      Uri.parse('https://web.example.com/items'),
    ]);
    expect(scope.noticeRepository.listCalls, 1);
  });

  test('the notification that launched the app is answered on start', () async {
    final scope = withPush();
    scope.pushMessaging!.launchTap = const PushTap(noticeId: 3);
    await scope.container.read(pushRegistrationProvider.notifier).start();
    expect(scope.noticeRepository.read, [3]);
  });

  test('a message in the foreground reloads the bell', () async {
    final scope = withPush();
    await scope.container.read(pushRegistrationProvider.notifier).start();
    scope.pushMessaging!.foregroundController.add(null);
    await settle();
    await settle();
    expect(scope.noticeRepository.listCalls, 1);
  });

  test('signing out takes the device off the list first', () async {
    final scope = withPush();
    await scope.container.read(accountProvider.future);
    await scope.container.read(accountProvider.notifier).signOut();
    expect(scope.deviceRegistrations.unregistered, ['fcm-token-1']);
    expect(scope.authSession!.signOuts, 1);
    expect(scope.container.read(pushRegistrationProvider), isFalse);
  });
}
