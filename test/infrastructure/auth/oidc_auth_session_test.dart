import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutterbase/domain/errors/app_error.dart';
import 'package:flutterbase/infrastructure/auth/oidc_auth_session.dart';
import 'package:flutterbase/infrastructure/auth/oidc_client.dart';
import 'package:flutterbase/infrastructure/auth/secret_store.dart';

final class MemorySecretStore implements SecretStore {
  final Map<String, String> values = <String, String>{};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);
}

final class FakeOidcClient implements OidcClient {
  final List<String> refreshedWith = <String>[];
  int authorizations = 0;
  AppError? failure;
  Completer<void>? gate;
  String? idToken = idTokenWith({'name': 'Kyon', 'email': 'kyon@example.com'});
  bool sendRefreshToken = true;
  DateTime expiresAt = DateTime.utc(2026, 9, 27, 12, 5);

  @override
  Future<OidcTokens> authorize() async {
    final error = failure;
    if (error != null) throw error;
    authorizations++;
    return OidcTokens(
      accessToken: 'at-0',
      expiresAt: expiresAt,
      refreshToken: sendRefreshToken ? 'rt-0' : null,
      idToken: idToken,
    );
  }

  @override
  Future<OidcTokens> refresh(String refreshToken) async {
    refreshedWith.add(refreshToken);
    await gate?.future;
    final error = failure;
    if (error != null) throw error;
    final n = refreshedWith.length;
    return OidcTokens(
      accessToken: 'at-$n',
      expiresAt: expiresAt,
      refreshToken: 'rt-$n',
    );
  }
}

String idTokenWith(Map<String, Object?> claims) {
  String part(Object? json) =>
      base64Url.encode(utf8.encode(jsonEncode(json))).replaceAll('=', '');
  return '${part({'alg': 'RS256'})}.${part(claims)}.sig';
}

void main() {
  late FakeOidcClient client;
  late MemorySecretStore secrets;
  late DateTime now;
  late OidcAuthSession session;

  setUp(() {
    client = FakeOidcClient();
    secrets = MemorySecretStore();
    now = DateTime.utc(2026, 9, 27, 12);
    session = OidcAuthSession(client, secrets, now: () => now);
  });

  test('starts signed out', () async {
    expect(await session.currentAccount(), isNull);
    await expectLater(
      session.accessToken(),
      throwsA(isA<SignInRequiredError>()),
    );
  });

  test('sign-in stores the refresh token and the name', () async {
    final account = await session.signIn();

    expect(account.displayName, 'Kyon');
    expect(account.email, 'kyon@example.com');
    expect(secrets.values[OidcAuthSession.refreshTokenKey], 'rt-0');
    expect(await session.currentAccount(), account);
    expect(await session.accessToken(), 'at-0');
    expect(client.refreshedWith, isEmpty);
  });

  test('refreshes shortly before expiry and keeps the rotated token', () async {
    await session.signIn();
    now = client.expiresAt.subtract(const Duration(seconds: 10));

    expect(await session.accessToken(), 'at-1');
    expect(client.refreshedWith, ['rt-0']);
    expect(secrets.values[OidcAuthSession.refreshTokenKey], 'rt-1');
  });

  test('forceRefresh refreshes even a fresh token', () async {
    await session.signIn();
    expect(await session.accessToken(forceRefresh: true), 'at-1');
  });

  test('concurrent callers share one refresh', () async {
    await session.signIn();
    now = client.expiresAt;
    client.gate = Completer<void>();

    final first = session.accessToken();
    final second = session.accessToken();
    client.gate!.complete();

    expect(await first, 'at-1');
    expect(await second, 'at-1');
    // Reusing a rotated refresh token would revoke the whole family.
    expect(client.refreshedWith, ['rt-0']);
  });

  test('a refused refresh signs the person out', () async {
    await session.signIn();
    now = client.expiresAt;
    client.failure = const SignInRequiredError('invalid_grant');

    await expectLater(
      session.accessToken(),
      throwsA(isA<SignInRequiredError>()),
    );
    expect(await session.currentAccount(), isNull);
    expect(secrets.values, isEmpty);
  });

  test('a network failure during refresh keeps the sign-in', () async {
    await session.signIn();
    now = client.expiresAt;
    client.failure = const InfrastructureError('offline');

    await expectLater(
      session.accessToken(),
      throwsA(isA<InfrastructureError>()),
    );
    expect(await session.currentAccount(), isNotNull);
  });

  test('a sign-in without a refresh token is refused', () async {
    client.sendRefreshToken = false;
    await expectLater(session.signIn(), throwsA(isA<SignInRequiredError>()));
    expect(secrets.values, isEmpty);
  });

  test('sign-out forgets everything', () async {
    await session.signIn();
    await session.signOut();

    expect(await session.currentAccount(), isNull);
    await expectLater(
      session.accessToken(),
      throwsA(isA<SignInRequiredError>()),
    );
  });

  test('the account needs the refresh token to count as signed in', () async {
    await session.signIn();
    secrets.values.remove(OidcAuthSession.refreshTokenKey);
    expect(await session.currentAccount(), isNull);
  });

  group('accountFromIdToken', () {
    test('prefers name, then preferred_username, email, sub', () {
      expect(accountFromIdToken(idTokenWith({'name': ' A '})).displayName, 'A');
      expect(
        accountFromIdToken(
          idTokenWith({'preferred_username': 'b', 'email': 'c@x'}),
        ).displayName,
        'b',
      );
      expect(
        accountFromIdToken(idTokenWith({'email': 'c@x'})).displayName,
        'c@x',
      );
      expect(accountFromIdToken(idTokenWith({'sub': 'd'})).displayName, 'd');
    });

    test('survives a missing or unreadable token', () {
      expect(accountFromIdToken(null).displayName, '?');
      expect(accountFromIdToken('a.!!!.c').displayName, '?');
    });
  });

  group('oidcFailure', () {
    test('invalid_grant and friends mean signing in again', () {
      for (final error in [
        'invalid_grant',
        'invalid_client',
        'unauthorized_client',
      ]) {
        expect(oidcFailure(error, 'x'), isA<SignInRequiredError>());
      }
    });

    test('anything else may be the network', () {
      expect(oidcFailure(null, 'x'), isA<InfrastructureError>());
      expect(oidcFailure('server_error', 'x'), isA<InfrastructureError>());
    });
  });
}
