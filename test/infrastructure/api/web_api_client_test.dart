import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutterbase/application/ports/auth_session.dart';
import 'package:flutterbase/domain/entities/account.dart';
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
}
