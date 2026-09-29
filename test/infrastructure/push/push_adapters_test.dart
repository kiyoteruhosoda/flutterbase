import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutterbase/application/ports/push_messaging.dart';
import 'package:flutterbase/infrastructure/api/web_api_client.dart';
import 'package:flutterbase/infrastructure/push/firebase_push_messaging.dart';
import 'package:flutterbase/infrastructure/repositories/web_api_device_registration_repository.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../support/fakes.dart';

void main() {
  group('pushTapFromData', () {
    test('reads what the web app puts in data', () {
      expect(
        pushTapFromData({'notification_id': '7', 'url': '/items'}),
        const PushTap(noticeId: 7, linkUrl: '/items'),
      );
    });

    test('tolerates a missing or odd id and link', () {
      expect(
        pushTapFromData({'notification_id': 'x', 'url': '  '}),
        const PushTap(noticeId: null),
      );
      expect(pushTapFromData({}), const PushTap(noticeId: null));
      expect(pushTapFromData({'notification_id': 3}).noticeId, 3);
    });
  });

  group('WebApiDeviceRegistrationRepository', () {
    late List<http.Request> requests;
    late WebApiDeviceRegistrationRepository repository;

    setUp(() {
      requests = [];
      repository = WebApiDeviceRegistrationRepository(
        WebApiClient(
          FakeAuthSession(),
          Uri.parse('https://web.example.com'),
          httpClient: MockClient((request) async {
            requests.add(request);
            return http.Response('', 204);
          }),
        ),
      );
    });

    test('registers the token as an android device', () async {
      await repository.register('fcm-token-1');
      final request = requests.single;
      expect(request.method, 'POST');
      expect(
        request.url.toString(),
        'https://web.example.com/api/notifications/device/register',
      );
      expect(request.headers['Authorization'], 'Bearer token');
      expect(request.headers['Content-Type'], startsWith('application/json'));
      expect(jsonDecode(request.body), {
        'token': 'fcm-token-1',
        'platform': 'android',
      });
    });

    test('unregisters the token', () async {
      await repository.unregister('fcm-token-1');
      final request = requests.single;
      expect(request.url.path, '/api/notifications/device/unregister');
      expect(jsonDecode(request.body), {'token': 'fcm-token-1'});
    });
  });
}
