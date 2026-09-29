import 'package:flutter_test/flutter_test.dart';
import 'package:flutterbase/domain/entities/account.dart';
import 'package:flutterbase/domain/entities/app_notice.dart';
import 'package:flutterbase/domain/entities/app_release.dart';
import 'package:flutterbase/domain/errors/app_error.dart';
import 'package:flutterbase/presentation/providers/app_update_providers.dart';
import 'package:flutterbase/presentation/providers/notice_providers.dart';

import '../../support/fakes.dart';
import '../../support/test_harness.dart';

const Account kyon = Account(displayName: 'Kyon');

final AppRelease newer = AppRelease(
  version: '1.43.0',
  build: 43, // testAppInfo is build 42
  downloadUrl: Uri.parse('https://share.example.com/app.apk'),
);

TestScope signedIn({AppNoticeInbox? inbox}) => TestScope(
  authSession: FakeAuthSession(signedIn: kyon),
  appReleaseRepository: FakeAppReleaseRepository(newer),
  noticeRepository: FakeAppNoticeRepository(inbox),
);

AppNoticeInbox twoNotices() => AppNoticeInbox(
  items: [
    testNotice(id: 2, channels: {NoticeChannel.banner}, linkUrl: '/items'),
    testNotice(id: 1, linkUrl: 'https://other.example.com/'),
  ],
  unreadCount: 1,
);

void main() {
  group('availableUpdateProvider', () {
    test('does nothing in a build without the sign-in', () async {
      final scope = TestScope();
      await scope.container.read(availableUpdateProvider.notifier).refresh();
      expect(scope.container.read(availableUpdateProvider), isNull);
      expect(scope.appReleaseRepository.calls, 0);
    });

    test('shows nothing while nobody is signed in', () async {
      final scope = TestScope(
        authSession: FakeAuthSession(),
        appReleaseRepository: FakeAppReleaseRepository(newer),
      );
      await scope.container.read(availableUpdateProvider.notifier).refresh();
      expect(scope.container.read(availableUpdateProvider), isNull);
      expect(scope.appReleaseRepository.calls, 0);
    });

    test('holds a newer build for the signed-in person', () async {
      final scope = signedIn();
      await scope.container.read(availableUpdateProvider.notifier).refresh();
      expect(scope.container.read(availableUpdateProvider), newer);
    });

    test('automatic checks are debounced; forced ones are not', () async {
      final scope = signedIn();
      final notifier = scope.container.read(availableUpdateProvider.notifier);
      await notifier.refresh();
      await notifier.refresh();
      expect(scope.appReleaseRepository.calls, 1);

      await notifier.refresh(force: true);
      expect(scope.appReleaseRepository.calls, 2);

      scope.now = scope.now.add(AppUpdateNotifier.minInterval);
      await notifier.refresh();
      expect(scope.appReleaseRepository.calls, 3);
    });

    test('closing remembers the build and hides the banner', () async {
      final scope = signedIn();
      final notifier = scope.container.read(availableUpdateProvider.notifier);
      await notifier.refresh();
      await notifier.dismiss();
      expect(scope.container.read(availableUpdateProvider), isNull);
      expect(scope.dismissedUpdateRepository.build, 43);

      await notifier.refresh(force: true);
      expect(scope.container.read(availableUpdateProvider), isNull);
    });

    test('downloading opens the link', () async {
      final scope = signedIn();
      final notifier = scope.container.read(availableUpdateProvider.notifier);
      expect(await notifier.openDownload(), isFalse);
      await notifier.refresh();
      expect(await notifier.openDownload(), isTrue);
      expect(scope.linkLauncher.opened, [newer.downloadUrl]);
    });

    test('dismissing with nothing shown does nothing', () async {
      final scope = signedIn();
      await scope.container.read(availableUpdateProvider.notifier).dismiss();
      expect(scope.dismissedUpdateRepository.build, isNull);
    });

    test('clear forgets the release and allows the next check', () async {
      final scope = signedIn();
      final notifier = scope.container.read(availableUpdateProvider.notifier);
      await notifier.refresh();
      notifier.clear();
      expect(scope.container.read(availableUpdateProvider), isNull);
      await notifier.refresh();
      expect(scope.appReleaseRepository.calls, 2);
    });
  });

  group('noticeInboxProvider', () {
    test('does nothing in a build without the sign-in', () async {
      final scope = TestScope();
      final ok = await scope.container
          .read(noticeInboxProvider.notifier)
          .refresh();
      expect(ok, isTrue);
      expect(scope.noticeRepository.listCalls, 0);
    });

    test('is empty while nobody is signed in', () async {
      final scope = TestScope(
        authSession: FakeAuthSession(),
        noticeRepository: FakeAppNoticeRepository(twoNotices()),
      );
      await scope.container.read(noticeInboxProvider.notifier).refresh();
      expect(scope.container.read(noticeInboxProvider).items, isEmpty);
      expect(scope.noticeRepository.listCalls, 0);
    });

    test('loads, and debounces automatic reloads', () async {
      final scope = signedIn(inbox: twoNotices());
      final notifier = scope.container.read(noticeInboxProvider.notifier);
      expect(await notifier.refresh(), isTrue);
      expect(scope.container.read(noticeInboxProvider).items, hasLength(2));
      await notifier.refresh();
      expect(scope.noticeRepository.listCalls, 1);
      await notifier.refresh(force: true);
      expect(scope.noticeRepository.listCalls, 2);
    });

    test('a failed load keeps what was shown and may retry', () async {
      final scope = signedIn(inbox: twoNotices());
      final notifier = scope.container.read(noticeInboxProvider.notifier);
      await notifier.refresh();
      scope.noticeRepository.failure = const InfrastructureError('offline');
      expect(await notifier.refresh(force: true), isFalse);
      expect(scope.container.read(noticeInboxProvider).items, hasLength(2));

      scope.noticeRepository.failure = null;
      await notifier.refresh();
      expect(scope.noticeRepository.listCalls, 3);
    });

    test('reading changes the state only after the server agreed', () async {
      final scope = signedIn(inbox: twoNotices());
      final notifier = scope.container.read(noticeInboxProvider.notifier);
      await notifier.refresh();
      final notice = scope.container.read(noticeInboxProvider).items[1];

      scope.noticeRepository.failure = const InfrastructureError('offline');
      expect(await notifier.markRead(notice), isFalse);
      expect(scope.container.read(noticeInboxProvider).unreadCount, 1);

      scope.noticeRepository.failure = null;
      expect(await notifier.markRead(notice), isTrue);
      final inbox = scope.container.read(noticeInboxProvider);
      expect(inbox.unreadCount, 0);
      expect(inbox.items[1].readAt, scope.now);
      expect(scope.noticeRepository.read, [1]);
    });

    test('reading all clears the badge', () async {
      final scope = signedIn(inbox: twoNotices());
      final notifier = scope.container.read(noticeInboxProvider.notifier);
      await notifier.refresh();
      await notifier.markAllRead();
      expect(scope.container.read(noticeInboxProvider).unreadCount, 0);
      expect(scope.noticeRepository.readAllCalls, 1);
    });

    test('opening from the bell reads and follows the link', () async {
      final scope = signedIn(inbox: twoNotices());
      final notifier = scope.container.read(noticeInboxProvider.notifier);
      await notifier.refresh();
      final notice = scope.container.read(noticeInboxProvider).items[1];
      expect(await notifier.open(notice), isTrue);
      expect(scope.noticeRepository.read, [1]);
      expect(scope.linkLauncher.opened, [
        Uri.parse('https://other.example.com/'),
      ]);
    });

    test('opening a notice without a link only reads it', () async {
      final scope = signedIn(
        inbox: AppNoticeInbox(items: [testNotice()], unreadCount: 1),
      );
      final notifier = scope.container.read(noticeInboxProvider.notifier);
      await notifier.refresh();
      expect(await notifier.open(testNotice()), isTrue);
      expect(scope.linkLauncher.opened, isEmpty);
      expect(scope.noticeRepository.read, [1]);
    });

    test('the banner tap follows the link and dismisses', () async {
      final scope = signedIn(inbox: twoNotices());
      final notifier = scope.container.read(noticeInboxProvider.notifier);
      await notifier.refresh();
      final banner = scope.container.read(noticeInboxProvider).banner!;
      expect(await notifier.openBanner(banner), isTrue);
      expect(scope.linkLauncher.opened, [
        Uri.parse('https://web.example.com/items'),
      ]);
      expect(scope.noticeRepository.dismissed, [2]);
      expect(scope.container.read(noticeInboxProvider).banner, isNull);
    });

    test('clear empties the inbox', () async {
      final scope = signedIn(inbox: twoNotices());
      final notifier = scope.container.read(noticeInboxProvider.notifier);
      await notifier.refresh();
      notifier.clear();
      expect(scope.container.read(noticeInboxProvider).items, isEmpty);
    });
  });
}
