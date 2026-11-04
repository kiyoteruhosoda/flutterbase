import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutterbase/domain/entities/account.dart';
import 'package:flutterbase/presentation/pages/main_page.dart';

import '../../support/fakes.dart';
import '../../support/test_harness.dart';

/// The main screen names the notification channels in the app's language
/// (docs/adr/0014-notification-channel-groups.md).
void main() {
  const kyon = Account(displayName: 'Kyon');

  TestScope withPush() => TestScope(
    authSession: FakeAuthSession(signedIn: kyon),
    pushMessaging: FakePushMessaging(),
  );

  List<String> namesOf(TestScope scope) => [
    for (final group in scope.notificationChannels.prepared.last) ...[
      group.name,
      ...group.channels.map((c) => c.name),
    ],
  ];

  testWidgets('creates the channels once, under the app\'s name', (
    tester,
  ) async {
    final scope = await pumpInScope(
      tester,
      const MainPage(),
      scope: withPush(),
      locale: const Locale('ja'),
    );

    expect(scope.notificationChannels.prepared, hasLength(1));
    expect(namesOf(scope), ['フラッターベース', 'お知らせ']);
    expect(scope.notificationChannels.retired.single, [
      'fcm_fallback_notification_channel',
    ]);
  });

  testWidgets('renames them when the language changes, and only then', (
    tester,
  ) async {
    final locale = ValueNotifier<Locale>(const Locale('ja'));
    addTearDown(locale.dispose);
    final scope = await pumpInScope(
      tester,
      ValueListenableBuilder<Locale>(
        valueListenable: locale,
        builder: (context, value, _) => Localizations.override(
          context: context,
          locale: value,
          child: const MainPage(),
        ),
      ),
      scope: withPush(),
      locale: const Locale('ja'),
    );
    expect(scope.notificationChannels.prepared, hasLength(1));

    locale.value = const Locale('en');
    await tester.pumpAndSettle();
    expect(scope.notificationChannels.prepared, hasLength(2));
    expect(namesOf(scope), ['FlutterBase', 'Notices']);

    // Another rebuild in the same language asks nothing again.
    await tester.tap(find.byType(NavigationDestination).at(1));
    await tester.pumpAndSettle();
    expect(scope.notificationChannels.prepared, hasLength(2));
  });

  testWidgets('creates nothing in a build without FCM', (tester) async {
    final scope = await pumpInScope(
      tester,
      const MainPage(),
      scope: TestScope(authSession: FakeAuthSession(signedIn: kyon)),
    );
    expect(scope.notificationChannels.prepared, isEmpty);
  });
}
