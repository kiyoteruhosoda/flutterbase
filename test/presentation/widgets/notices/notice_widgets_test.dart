import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutterbase/domain/entities/account.dart';
import 'package:flutterbase/domain/entities/app_notice.dart';
import 'package:flutterbase/domain/entities/app_release.dart';
import 'package:flutterbase/domain/errors/app_error.dart';
import 'package:flutterbase/presentation/l10n/app_localizations_en.dart';
import 'package:flutterbase/presentation/l10n/app_localizations_ja.dart';
import 'package:flutterbase/presentation/pages/main_page.dart';
import 'package:flutterbase/presentation/providers/app_update_providers.dart';
import 'package:flutterbase/presentation/providers/auth_providers.dart';

import '../../../support/fakes.dart';
import '../../../support/test_harness.dart';

const l10n = AppLocalizationsEn();
const Account kyon = Account(displayName: 'Kyon');

AppRelease newer({bool link = true}) => AppRelease(
  version: '1.43.0',
  build: 43, // testAppInfo is build 42
  downloadUrl: link ? Uri.parse('https://share.example.com/app.apk') : null,
);

final AppNotice bannerNotice = testNotice(
  id: 2,
  title: 'Planned maintenance',
  body: 'Tonight at 23:00',
  channels: {NoticeChannel.banner},
  linkUrl: '/status',
);

final AppNotice bellNotice = testNotice(
  id: 1,
  title: 'New feature',
  body: 'Try the new list',
  linkUrl: 'https://other.example.com/news',
);

TestScope scopeWith({
  AppRelease? release,
  List<AppNotice> notices = const [],
  int unread = 0,
  bool signedIn = true,
}) {
  return TestScope(
    authSession: FakeAuthSession(signedIn: signedIn ? kyon : null),
    appReleaseRepository: FakeAppReleaseRepository(release),
    noticeRepository: FakeAppNoticeRepository(
      AppNoticeInbox(items: notices, unreadCount: unread),
    ),
  );
}

Finder get bell => find.byIcon(Icons.notifications_outlined);

/// The dot that marks an unread notice in the list.
Finder get unreadDot => find.byIcon(Icons.circle);

/// Sends the app to the background and back, one legal step at a time.
Future<void> leaveAndReturn(WidgetTester tester) async {
  for (final state in const [
    AppLifecycleState.inactive,
    AppLifecycleState.hidden,
    AppLifecycleState.paused,
    AppLifecycleState.hidden,
    AppLifecycleState.inactive,
    AppLifecycleState.resumed,
  ]) {
    tester.binding.handleAppLifecycleStateChanged(state);
  }
  await tester.pumpAndSettle();
}

void main() {
  group('update banner', () {
    testWidgets('announces a newer build and downloads it', (tester) async {
      final scope = scopeWith(release: newer());
      await pumpInScope(tester, const MainPage(), scope: scope);

      expect(find.text(l10n.updateAvailable('1.43.0')), findsOneWidget);
      await tester.tap(find.text(l10n.updateDownload));
      await tester.pumpAndSettle();
      expect(scope.linkLauncher.opened, [newer().downloadUrl]);
    });

    testWidgets('closing hides it for that build', (tester) async {
      final scope = scopeWith(release: newer());
      await pumpInScope(tester, const MainPage(), scope: scope);

      await tester.tap(find.text(l10n.commonClose));
      await tester.pumpAndSettle();
      expect(find.text(l10n.updateAvailable('1.43.0')), findsNothing);
      expect(scope.dismissedUpdateRepository.build, 43);
    });

    testWidgets('has no download without a link', (tester) async {
      await pumpInScope(
        tester,
        const MainPage(),
        scope: scopeWith(release: newer(link: false)),
      );
      expect(find.text(l10n.updateAvailable('1.43.0')), findsOneWidget);
      expect(find.text(l10n.updateDownload), findsNothing);
    });

    testWidgets('a failed download is reported', (tester) async {
      final scope = scopeWith(release: newer());
      scope.linkLauncher.result = false;
      await pumpInScope(tester, const MainPage(), scope: scope);
      await tester.tap(find.text(l10n.updateDownload));
      await tester.pumpAndSettle();
      expect(find.text(l10n.updateOpenFailed), findsOneWidget);
    });

    testWidgets('never shows while nobody is signed in', (tester) async {
      final scope = scopeWith(release: newer(), signedIn: false);
      await pumpInScope(tester, const MainPage(), scope: scope);
      expect(find.byType(MaterialBanner), findsNothing);
      expect(scope.appReleaseRepository.calls, 0);
    });

    testWidgets('wins over a notice banner', (tester) async {
      await pumpInScope(
        tester,
        const MainPage(),
        scope: scopeWith(release: newer(), notices: [bannerNotice]),
      );
      expect(find.byType(MaterialBanner), findsOneWidget);
      expect(find.text(l10n.updateAvailable('1.43.0')), findsOneWidget);

      await tester.tap(find.text(l10n.commonClose));
      await tester.pumpAndSettle();
      expect(find.text('Planned maintenance'), findsOneWidget);
    });
  });

  group('notice banner', () {
    testWidgets('tapping it opens the link on the web app and dismisses', (
      tester,
    ) async {
      final scope = scopeWith(notices: [bannerNotice]);
      await pumpInScope(tester, const MainPage(), scope: scope);

      await tester.tap(find.text('Planned maintenance'));
      await tester.pumpAndSettle();
      expect(scope.linkLauncher.opened, [
        Uri.parse('https://web.example.com/status'),
      ]);
      expect(scope.noticeRepository.dismissed, [2]);
      expect(find.byType(MaterialBanner), findsNothing);
    });

    testWidgets('closing dismisses without opening', (tester) async {
      final scope = scopeWith(notices: [bannerNotice]);
      await pumpInScope(tester, const MainPage(), scope: scope);

      await tester.tap(find.text(l10n.commonClose));
      await tester.pumpAndSettle();
      expect(scope.linkLauncher.opened, isEmpty);
      expect(scope.noticeRepository.dismissed, [2]);
      expect(find.byType(MaterialBanner), findsNothing);
    });

    testWidgets('a dismissed notice has no banner', (tester) async {
      await pumpInScope(
        tester,
        const MainPage(),
        scope: scopeWith(
          notices: [
            testNotice(
              channels: {NoticeChannel.banner},
              dismissedAt: testNoticeSentAt,
            ),
          ],
        ),
      );
      expect(find.byType(MaterialBanner), findsNothing);
    });
  });

  group('bell', () {
    testWidgets('shows the unread count', (tester) async {
      await pumpInScope(
        tester,
        const MainPage(),
        scope: scopeWith(notices: [bellNotice], unread: 3),
      );
      expect(bell, findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('has no badge with nothing unread', (tester) async {
      await pumpInScope(tester, const MainPage(), scope: scopeWith());
      expect(bell, findsOneWidget);
      expect(find.text('0'), findsNothing);
    });

    testWidgets('is absent while nobody is signed in', (tester) async {
      await pumpInScope(
        tester,
        const MainPage(),
        scope: scopeWith(signedIn: false),
      );
      expect(bell, findsNothing);
    });

    testWidgets('opens the list, reloading it', (tester) async {
      final scope = scopeWith(notices: [bellNotice, bannerNotice], unread: 1);
      await pumpInScope(tester, const MainPage(), scope: scope);
      final loadsBefore = scope.noticeRepository.listCalls;

      await tester.tap(bell);
      await tester.pumpAndSettle();
      expect(scope.noticeRepository.listCalls, loadsBefore + 1);
      expect(find.text(l10n.noticesTitle), findsOneWidget);
      expect(find.text('New feature'), findsOneWidget);
      expect(find.text('Try the new list'), findsOneWidget);
      // Banner-only notices are not under the bell.
      expect(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.text('Planned maintenance'),
        ),
        findsNothing,
      );
      expect(unreadDot, findsOneWidget);
    });

    testWidgets('tapping a notice reads it and opens its link', (tester) async {
      final scope = scopeWith(notices: [bellNotice], unread: 1);
      await pumpInScope(tester, const MainPage(), scope: scope);
      await tester.tap(bell);
      await tester.pumpAndSettle();

      await tester.tap(find.text('New feature'));
      await tester.pumpAndSettle();
      expect(scope.noticeRepository.read, [1]);
      expect(scope.linkLauncher.opened, [
        Uri.parse('https://other.example.com/news'),
      ]);
      expect(unreadDot, findsNothing);
    });

    testWidgets('a link that cannot open is reported', (tester) async {
      final scope = scopeWith(notices: [bellNotice], unread: 1);
      scope.linkLauncher.result = false;
      await pumpInScope(tester, const MainPage(), scope: scope);
      await tester.tap(bell);
      await tester.pumpAndSettle();
      await tester.tap(find.text('New feature'));
      await tester.pumpAndSettle();
      expect(find.text(l10n.noticeOpenFailed), findsOneWidget);
    });

    testWidgets('mark all as read clears the badge', (tester) async {
      final scope = scopeWith(notices: [bellNotice], unread: 1);
      await pumpInScope(tester, const MainPage(), scope: scope);
      await tester.tap(bell);
      await tester.pumpAndSettle();

      await tester.tap(find.text(l10n.noticesMarkAllRead));
      await tester.pumpAndSettle();
      expect(scope.noticeRepository.readAllCalls, 1);
      expect(unreadDot, findsNothing);
    });

    testWidgets('an empty list says so', (tester) async {
      await pumpInScope(tester, const MainPage(), scope: scopeWith());
      await tester.tap(bell);
      await tester.pumpAndSettle();
      expect(find.text(l10n.noticesEmpty), findsOneWidget);
    });

    testWidgets('a failed load is reported and can be retried', (tester) async {
      final scope = scopeWith(notices: [bellNotice], unread: 1);
      await pumpInScope(tester, const MainPage(), scope: scope);
      scope.noticeRepository.failure = const InfrastructureError('offline');
      await tester.tap(bell);
      await tester.pumpAndSettle();
      expect(find.text(l10n.noticesLoadFailed), findsOneWidget);
      // What was loaded before stays visible.
      expect(find.text('New feature'), findsOneWidget);

      scope.noticeRepository.failure = null;
      await tester.tap(find.text(l10n.commonRetry));
      await tester.pumpAndSettle();
      expect(find.text(l10n.noticesLoadFailed), findsNothing);
    });

    testWidgets('fits in Japanese on a phone-sized screen', (tester) async {
      final scope = scopeWith(
        release: newer(),
        notices: [bellNotice],
        unread: 1,
      );
      await pumpInScope(
        tester,
        const MainPage(),
        scope: scope,
        locale: const Locale('ja'),
        surfaceSize: const Size(393, 852),
      );
      const ja = AppLocalizationsJa();
      expect(find.text(ja.updateAvailable('1.43.0')), findsOneWidget);
      await tester.tap(bell);
      await tester.pumpAndSettle();
      expect(find.text(ja.noticesTitle), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('when it asks the server', () {
    testWidgets('a sign-in fetches at once', (tester) async {
      final scope = scopeWith(
        release: newer(),
        notices: [bannerNotice],
        signedIn: false,
      );
      await pumpInScope(tester, const MainPage(), scope: scope);
      expect(find.byType(MaterialBanner), findsNothing);

      await scope.container.read(accountProvider.notifier).signIn();
      await tester.pumpAndSettle();
      expect(find.text(l10n.updateAvailable('1.43.0')), findsOneWidget);
      expect(bell, findsOneWidget);
    });

    testWidgets('a sign-out forgets what was shown', (tester) async {
      final scope = scopeWith(release: newer(), notices: [bellNotice]);
      await pumpInScope(tester, const MainPage(), scope: scope);
      expect(find.byType(MaterialBanner), findsOneWidget);

      await scope.container.read(accountProvider.notifier).signOut();
      await tester.pumpAndSettle();
      expect(find.byType(MaterialBanner), findsNothing);
      expect(bell, findsNothing);
      expect(scope.container.read(availableUpdateProvider), isNull);
    });

    testWidgets('returning to the app checks again after the interval', (
      tester,
    ) async {
      final scope = scopeWith();
      await pumpInScope(tester, const MainPage(), scope: scope);
      expect(scope.appReleaseRepository.calls, 1);

      await leaveAndReturn(tester);
      expect(scope.appReleaseRepository.calls, 1, reason: 'debounced');

      scope.now = scope.now.add(AppUpdateNotifier.minInterval);
      await leaveAndReturn(tester);
      expect(scope.appReleaseRepository.calls, 2);
    });
  });
}
