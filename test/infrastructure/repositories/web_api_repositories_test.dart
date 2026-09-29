import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutterbase/domain/entities/app_notice.dart';
import 'package:flutterbase/domain/entities/app_release.dart';
import 'package:flutterbase/domain/errors/app_error.dart';
import 'package:flutterbase/infrastructure/api/web_api_client.dart';
import 'package:flutterbase/infrastructure/repositories/web_api_app_notice_repository.dart';
import 'package:flutterbase/infrastructure/repositories/web_api_app_release_repository.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../support/fakes.dart';

void main() {
  group('appReleaseFromJson', () {
    test('reads the full contract', () {
      final release = appReleaseFromJson({
        'latest': {
          'version': '1.53.0',
          'build': 356,
          'download_url': 'https://share.example.com/app-1.53.0.apk',
          'built_at': '2026-09-27T01:02:03Z',
        },
      });
      expect(
        release,
        AppRelease(
          version: '1.53.0',
          build: 356,
          downloadUrl: Uri.parse('https://share.example.com/app-1.53.0.apk'),
          builtAt: DateTime.utc(2026, 9, 27, 1, 2, 3),
        ),
      );
      expect(release!.builtAt!.isUtc, isTrue);
    });

    test('null latest is "nothing published"', () {
      expect(appReleaseFromJson({'latest': null}), isNull);
    });

    test('optional fields may be null', () {
      final release = appReleaseFromJson({
        'latest': {
          'version': '1.0.0',
          'build': 1,
          'download_url': null,
          'built_at': null,
        },
      });
      expect(release!.downloadUrl, isNull);
      expect(release.builtAt, isNull);
    });

    test('a download link that is not https is dropped', () {
      final release = appReleaseFromJson({
        'latest': {
          'version': '1.0.0',
          'build': 1,
          'download_url': 'http://share.example.com/app.apk',
        },
      });
      expect(release!.downloadUrl, isNull);
    });

    test('a body off the contract is an InfrastructureError', () {
      for (final body in <Object?>[
        null,
        <String, Object?>{},
        {'latest': 'x'},
        {
          'latest': {'version': '1.0.0', 'build': '1'},
        },
        {
          'latest': {'version': '', 'build': 1},
        },
      ]) {
        expect(
          () => appReleaseFromJson(body),
          throwsA(isA<InfrastructureError>()),
          reason: '$body',
        );
      }
    });
  });

  group('appNoticeInboxFromJson', () {
    final item = <String, Object?>{
      'id': 1,
      'title': 'Maintenance',
      'body': 'Tonight',
      'link_url': '/items',
      'channels': ['banner', 'bell', 'webpush'],
      'sent_at': '2026-09-28T03:04:05Z',
      'read_at': null,
      'dismissed_at': '2026-09-28T04:00:00Z',
    };

    test('reads items and the unread count', () {
      final inbox = appNoticeInboxFromJson({
        'items': [item],
        'unread_count': 3,
      });
      expect(inbox.unreadCount, 3);
      final notice = inbox.items.single;
      expect(notice.id, 1);
      expect(notice.title, 'Maintenance');
      expect(notice.body, 'Tonight');
      expect(notice.linkUrl, '/items');
      expect(notice.channels, {NoticeChannel.banner, NoticeChannel.bell});
      expect(notice.sentAt, DateTime.utc(2026, 9, 28, 3, 4, 5));
      expect(notice.readAt, isNull);
      expect(notice.dismissedAt, DateTime.utc(2026, 9, 28, 4));
    });

    test('an item the app cannot read is skipped, not fatal', () {
      final inbox = appNoticeInboxFromJson({
        'items': [
          {'id': 'x'},
          'nonsense',
          {...item, 'sent_at': 'yesterday'},
          {...item, 'id': 2, 'link_url': '', 'channels': null},
        ],
        'unread_count': 0,
      });
      final notice = inbox.items.single;
      expect(notice.id, 2);
      expect(notice.linkUrl, isNull);
      expect(notice.channels, isEmpty);
    });

    test('a negative count reads as zero', () {
      final inbox = appNoticeInboxFromJson({
        'items': <Object?>[],
        'unread_count': -1,
      });
      expect(inbox.unreadCount, 0);
    });

    test('a body off the contract is an InfrastructureError', () {
      for (final body in <Object?>[
        null,
        <Object?>[],
        {'items': <Object?>[]},
        {'unread_count': 0},
      ]) {
        expect(
          () => appNoticeInboxFromJson(body),
          throwsA(isA<InfrastructureError>()),
          reason: '$body',
        );
      }
    });
  });

  group('over HTTP', () {
    late List<http.Request> requests;
    late WebApiClient api;

    setUp(() {
      requests = <http.Request>[];
      api = WebApiClient(
        FakeAuthSession(),
        Uri.parse('https://web.example.com'),
        httpClient: MockClient((request) async {
          requests.add(request);
          return switch (request.url.path) {
            '/api/app-release/latest' => http.Response(
              jsonEncode({
                'latest': {'version': '2.0.0', 'build': 7},
              }),
              200,
            ),
            '/api/notifications' => http.Response(
              jsonEncode({'items': <Object?>[], 'unread_count': 0}),
              200,
            ),
            _ => http.Response('', 204),
          };
        }),
      );
    });

    test('the release comes from /api/app-release/latest', () async {
      final release = await WebApiAppReleaseRepository(api).latest();
      expect(release?.build, 7);
      expect(requests.single.url.path, '/api/app-release/latest');
    });

    test('notices use /api/notifications and its actions', () async {
      final repo = WebApiAppNoticeRepository(api);
      await repo.list();
      await repo.markRead(5);
      await repo.markAllRead();
      await repo.dismiss(6);
      expect(requests.map((r) => '${r.method} ${r.url.path}'), [
        'GET /api/notifications',
        'POST /api/notifications/5/read',
        'POST /api/notifications/read-all',
        'POST /api/notifications/6/dismiss',
      ]);
      expect(
        requests.every((r) => r.headers['Authorization'] == 'Bearer token'),
        isTrue,
      );
    });
  });
}
