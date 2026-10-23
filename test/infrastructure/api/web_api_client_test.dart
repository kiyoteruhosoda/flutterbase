import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutterbase/application/ports/auth_session.dart';
import 'package:flutterbase/domain/entities/account.dart';
import 'package:flutterbase/domain/entities/service_outage.dart';
import 'package:flutterbase/domain/errors/app_error.dart';
import 'package:flutterbase/infrastructure/api/web_api_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Hands out `at-0`, then `at-1` after each forced refresh.
final class _TokenSession implements AuthSession {
  int refreshes = 0;
  Exception? failure;

  @override
  Future<String> accessToken({bool forceRefresh = false}) async {
    final error = failure;
    if (error != null) throw error;
    if (forceRefresh) refreshes++;
    return 'at-$refreshes';
  }

  @override
  Future<Account?> currentAccount() async => null;

  @override
  Future<Account> signIn() => throw UnimplementedError();

  @override
  Future<void> signOut() async {}
}

final Uri base = Uri.parse('https://web.example.com');

/// What the edge answers while a maintenance is declared (with the title and
/// body #663 added).
http.Response maintenance503() => http.Response.bytes(
  utf8.encode(
    jsonEncode({
      'error': 'service_unavailable',
      'reason': 'maintenance',
      'until': '2026-10-28T19:30:00Z',
      'message': 'DB の作り直し',
      'title': 'Scheduled maintenance',
      'body': 'We are moving the database.',
    }),
  ),
  503,
  headers: {'content-type': 'application/json', 'retry-after': '300'},
);

void main() {
  late _TokenSession session;
  late List<http.Request> requests;

  WebApiClient client(
    Future<http.Response> Function(http.Request) handler, {
    Duration timeout = const Duration(seconds: 5),
  }) {
    return WebApiClient(
      session,
      base,
      timeout: timeout,
      httpClient: MockClient((request) {
        requests.add(request);
        return handler(request);
      }),
    );
  }

  setUp(() {
    session = _TokenSession();
    requests = <http.Request>[];
  });

  test('sends the access token and decodes JSON', () async {
    final api = client(
      (_) async => http.Response.bytes(utf8.encode('{"a": "ä"}'), 200),
    );
    expect(await api.getJson('/api/x'), {'a': 'ä'});
    final request = requests.single;
    expect(request.method, 'GET');
    expect(request.url, Uri.parse('https://web.example.com/api/x'));
    expect(request.headers['Authorization'], 'Bearer at-0');
  });

  test('a 401 is retried once with a refreshed token', () async {
    final api = client(
      (r) async => r.headers['Authorization'] == 'Bearer at-0'
          ? http.Response('', 401)
          : http.Response('', 204),
    );
    await api.post('/api/y');
    expect(requests, hasLength(2));
    expect(requests.last.method, 'POST');
    expect(requests.last.headers['Authorization'], 'Bearer at-1');
    expect(session.refreshes, 1);
  });

  test('a second 401 is a failure, not a loop', () async {
    final api = client((_) async => http.Response('', 401));
    await expectLater(api.post('/api/y'), throwsA(isA<InfrastructureError>()));
    expect(requests, hasLength(2));
  });

  test('a server error is an InfrastructureError', () async {
    final api = client((_) async => http.Response('boom', 500));
    await expectLater(
      api.getJson('/api/x'),
      throwsA(
        isA<InfrastructureError>().having(
          (e) => e.message,
          'message',
          contains('500'),
        ),
      ),
    );
  });

  test('a body that is not JSON is an InfrastructureError', () async {
    final api = client((_) async => http.Response('<html>', 200));
    await expectLater(
      api.getJson('/api/x'),
      throwsA(isA<InfrastructureError>()),
    );
  });

  test('a network failure is an InfrastructureError', () async {
    final api = client((_) async => throw http.ClientException('offline'));
    await expectLater(
      api.getJson('/api/x'),
      throwsA(isA<InfrastructureError>()),
    );
  });

  test('a request that never answers times out', () async {
    final api = client(
      (_) => Completer<http.Response>().future,
      timeout: const Duration(milliseconds: 10),
    );
    await expectLater(
      api.getJson('/api/x'),
      throwsA(isA<InfrastructureError>()),
    );
  });

  test('no sign-in reaches the caller as SignInRequiredError', () async {
    session.failure = const SignInRequiredError('signed out');
    final api = client((_) async => http.Response('{}', 200));
    await expectLater(
      api.getJson('/api/x'),
      throwsA(isA<SignInRequiredError>()),
    );
    expect(requests, isEmpty);
  });

  group('the edge\'s 503 (docs/adr/0011-*)', () {
    test('maintenance is a ServiceUnavailableError with every field', () async {
      final api = client((_) async => maintenance503());
      final seen = <ServiceOutage>[];
      final subscription = api.outages.listen(seen.add);
      addTearDown(subscription.cancel);

      await expectLater(
        api.getJson('/api/x'),
        throwsA(
          isA<ServiceUnavailableError>().having(
            (e) => e.outage,
            'outage',
            ServiceOutage(
              reason: ServiceOutageReason.maintenance,
              title: 'Scheduled maintenance',
              body: 'We are moving the database.',
              message: 'DB の作り直し',
              until: DateTime.utc(2026, 10, 28, 19, 30),
            ),
          ),
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(seen.single.reason, ServiceOutageReason.maintenance);
      // Not retried: a 503 is not a stale token.
      expect(requests, hasLength(1));
    });

    test('stopped carries no text, and a missing title/body is null', () async {
      final api = client(
        (_) async => http.Response(
          '{"error":"service_unavailable","reason":"stopped",'
          '"host":"web.example.com"}',
          503,
        ),
      );
      await expectLater(
        api.post('/api/y'),
        throwsA(
          isA<ServiceUnavailableError>().having(
            (e) => e.outage,
            'outage',
            const ServiceOutage(reason: ServiceOutageReason.stopped),
          ),
        ),
      );
    });

    test('an older edge without title/body still counts', () async {
      final api = client(
        (_) async => http.Response(
          '{"error":"service_unavailable","reason":"maintenance",'
          '"until":"2026-10-28T19:30:00Z","message":"","title":null}',
          503,
        ),
      );
      await expectLater(
        api.getJson('/api/x'),
        throwsA(
          isA<ServiceUnavailableError>().having(
            (e) => e.outage,
            'outage',
            ServiceOutage(
              reason: ServiceOutageReason.maintenance,
              until: DateTime.utc(2026, 10, 28, 19, 30),
            ),
          ),
        ),
      );
    });

    for (final (name, body) in [
      ('HTML', '<html>Maintenance</html>'),
      ('empty', ''),
      ('another JSON shape', '{"detail":"Service Unavailable"}'),
      ('an unknown reason', '{"error":"service_unavailable","reason":"x"}'),
    ]) {
      test('a 503 with $name is an ordinary InfrastructureError', () async {
        final api = client((_) async => http.Response(body, 503));
        final seen = <ServiceOutage>[];
        final subscription = api.outages.listen(seen.add);
        addTearDown(subscription.cancel);

        await expectLater(
          api.getJson('/api/x'),
          throwsA(
            isA<InfrastructureError>().having(
              (e) => e.message,
              'message',
              contains('503'),
            ),
          ),
        );
        await Future<void>.delayed(Duration.zero);
        expect(seen, isEmpty);
      });
    }

    test('maintenance JSON with another status is not an outage', () async {
      final api = client(
        (_) async => http.Response(
          '{"error":"service_unavailable","reason":"maintenance"}',
          500,
        ),
      );
      await expectLater(
        api.getJson('/api/x'),
        throwsA(
          isA<InfrastructureError>().having(
            (e) => e.message,
            'message',
            contains('500'),
          ),
        ),
      );
    });
  });

  group('check', () {
    test('asks without a token and answers the outage', () async {
      final api = client((_) async => maintenance503());
      expect(
        await api.check(),
        isA<ServiceOutage>().having(
          (o) => o.reason,
          'reason',
          ServiceOutageReason.maintenance,
        ),
      );
      final request = requests.single;
      expect(request.url, base.resolve(WebApiClient.checkPath));
      expect(request.headers, isNot(contains('Authorization')));
    });

    test('any other answer is "back in service"', () async {
      final api = client((_) async => http.Response('', 401));
      expect(await api.check(), isNull);
    });

    test('a network failure is an InfrastructureError', () async {
      final api = client((_) async => throw http.ClientException('offline'));
      await expectLater(api.check(), throwsA(isA<InfrastructureError>()));
    });

    test('close stops the outage stream', () async {
      final api = client((_) async => http.Response('', 204));
      final done = Completer<void>();
      api.outages.listen(null, onDone: done.complete);
      await api.close();
      await done.future;
    });
  });
}
