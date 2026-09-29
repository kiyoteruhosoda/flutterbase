import 'package:flutter_test/flutter_test.dart';
import 'package:flutterbase/domain/entities/app_notice.dart';

import '../../support/fakes.dart';

final Uri base = Uri.parse('https://web.example.com');
final DateTime at = DateTime.utc(2026, 9, 29, 9);

void main() {
  group('AppNotice channels', () {
    test('a bell notice is listed and counted while unread', () {
      final notice = testNotice();
      expect(notice.isInBell, isTrue);
      expect(notice.countsAsUnread, isTrue);
      expect(notice.markedRead(at).countsAsUnread, isFalse);
    });

    test('a banner-only notice is not under the bell', () {
      final notice = testNotice(channels: {NoticeChannel.banner});
      expect(notice.isInBell, isFalse);
      expect(notice.countsAsUnread, isFalse);
      expect(notice.wantsBanner, isTrue);
    });

    test('a dismissed banner no longer wants showing', () {
      final notice = testNotice(channels: {NoticeChannel.banner});
      expect(notice.markedDismissed(at).wantsBanner, isFalse);
    });
  });

  group('AppNotice.linkTarget', () {
    test('no link leads nowhere', () {
      expect(testNotice().linkTarget(base), isNull);
      expect(testNotice(linkUrl: '  ').linkTarget(base), isNull);
    });

    test('a path of the web app opens on the web app', () {
      expect(
        testNotice(linkUrl: '/items?x=1').linkTarget(base),
        Uri.parse('https://web.example.com/items?x=1'),
      );
    });

    test('an absolute https link is kept', () {
      expect(
        testNotice(linkUrl: 'https://other.example.com/a').linkTarget(base),
        Uri.parse('https://other.example.com/a'),
      );
    });

    test('anything but https is refused', () {
      for (final link in [
        'http://web.example.com/a',
        'javascript:alert(1)',
        '//evil.example.com/a',
        'items',
        'https://',
      ]) {
        expect(
          testNotice(linkUrl: link).linkTarget(base),
          isNull,
          reason: link,
        );
      }
    });
  });

  group('AppNotice read and dismiss', () {
    test('reading keeps the first read time', () {
      final first = testNotice().markedRead(at);
      final again = first.markedRead(at.add(const Duration(hours: 1)));
      expect(again.readAt, at);
      expect(identical(first, again), isTrue);
    });

    test('dismissing also reads', () {
      final dismissed = testNotice().markedDismissed(at);
      expect(dismissed.readAt, at);
      expect(dismissed.dismissedAt, at);
    });

    test('dismissing a read notice keeps when it was read', () {
      final earlier = at.subtract(const Duration(days: 1));
      final dismissed = testNotice(readAt: earlier).markedDismissed(at);
      expect(dismissed.readAt, earlier);
    });

    test('equality covers every field, channels in any order', () {
      final a = testNotice(
        channels: {NoticeChannel.bell, NoticeChannel.banner},
      );
      final b = testNotice(
        channels: {NoticeChannel.banner, NoticeChannel.bell},
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(a.markedRead(at)));
      expect(a.toString(), 'AppNotice(#1)');
    });
  });

  group('AppNoticeInbox', () {
    final inbox = AppNoticeInbox(
      items: [
        testNotice(id: 3, channels: {NoticeChannel.banner}),
        testNotice(id: 2, channels: {NoticeChannel.bell, NoticeChannel.banner}),
        testNotice(id: 1, readAt: at),
      ],
      unreadCount: 1,
    );

    test('lists only bell notices under the bell', () {
      expect(inbox.bellItems.map((n) => n.id), [2, 1]);
    });

    test('the banner is the newest not yet dismissed', () {
      expect(inbox.banner?.id, 3);
      expect(inbox.markedDismissed(3, at).banner?.id, 2);
      expect(
        inbox.markedDismissed(3, at).markedDismissed(2, at).banner,
        isNull,
      );
    });

    test('reading an unread bell notice lowers the count', () {
      expect(inbox.markedRead(2, at).unreadCount, 0);
    });

    test('reading a notice that was not counted keeps the count', () {
      expect(inbox.markedRead(3, at).unreadCount, 1);
      expect(inbox.markedRead(1, at).unreadCount, 1);
      expect(inbox.markedRead(99, at).unreadCount, 1);
    });

    test('dismissing an unread bell notice lowers the count', () {
      expect(inbox.markedDismissed(2, at).unreadCount, 0);
    });

    test('the count never goes below zero', () {
      final off = AppNoticeInbox(items: [testNotice()], unreadCount: 0);
      expect(off.markedRead(1, at).unreadCount, 0);
    });

    test('reading all clears the count and reads every notice', () {
      final all = inbox.allMarkedRead(at);
      expect(all.unreadCount, 0);
      expect(all.items.every((n) => n.isRead), isTrue);
    });

    test('empty has nothing', () {
      const empty = AppNoticeInbox.empty();
      expect(empty.items, isEmpty);
      expect(empty.unreadCount, 0);
      expect(empty.banner, isNull);
    });
  });
}
