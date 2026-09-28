import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutterbase/domain/errors/app_error.dart';
import 'package:flutterbase/domain/value_objects/sign_in_settings.dart';
import 'package:flutterbase/infrastructure/auth/oidc_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _settings = SignInSettings(
  issuer: 'https://identity.example.com/tenant',
  clientId: 'app-client',
  linkHost: 'web.example.com',
);

const _discovery = {
  'authorization_endpoint': 'https://identity.example.com/tenant/authorize',
  'token_endpoint': 'https://identity.example.com/tenant/token',
};

/// assay stand-in: discovery, and the token endpoint answering [token].
MockClient _assay(
  List<http.Request> seen, {
  Map<String, Object?> token = const {
    'access_token': 'at',
    'expires_in': 300,
    'refresh_token': 'rt',
    'id_token': 'it',
  },
  int tokenStatus = 200,
}) {
  return MockClient((request) async {
    seen.add(request);
    if (request.url.path.endsWith('/.well-known/openid-configuration')) {
      return http.Response(jsonEncode(_discovery), 200);
    }
    return http.Response(jsonEncode(token), tokenStatus);
  });
}

/// A browser that answers with the redirect [answer] builds from the
/// authorization URL it was given.
BrowserSignIn _browser(String Function(Uri url) answer, List<Uri> opened) {
  return (url, settings) async {
    opened.add(url);
    return answer(url);
  };
}

String _redirectWith(Uri url, {String? code = 'the-code', String? error}) {
  final state = url.queryParameters['state']!;
  return Uri(
    scheme: 'https',
    host: 'web.example.com',
    path: '/app/oauth2redirect',
    queryParameters: {'state': state, 'code': ?code, 'error': ?error},
  ).toString();
}

void main() {
  group('PKCE', () {
    test('the S256 challenge is base64url(SHA-256) without padding', () {
      // Expected value computed independently (Python):
      //   base64.urlsafe_b64encode(hashlib.sha256(v.encode()).digest())
      //     .rstrip(b'=')
      expect(
        codeChallenge('dBjftJeZ4CVP-mJ92K9mRtkmIa5btcF8gxLSf3xkzB0'),
        'zeE156BKGYk79C_7VLiBzvqr6Gsl5lwoM44npGNBY5Q',
      );
    });
  });

  group('authorize', () {
    test('sends PKCE and exchanges the code for tokens', () async {
      final seen = <http.Request>[];
      final opened = <Uri>[];
      final client = WebAuthOidcClient(
        _settings,
        httpClient: _assay(seen),
        browser: _browser(_redirectWith, opened),
        random: Random(1),
      );

      final tokens = await client.authorize();

      expect(tokens.accessToken, 'at');
      expect(tokens.refreshToken, 'rt');
      expect(tokens.idToken, 'it');

      final url = opened.single;
      expect(url.path, '/tenant/authorize');
      expect(url.queryParameters['response_type'], 'code');
      expect(url.queryParameters['client_id'], 'app-client');
      expect(
        url.queryParameters['redirect_uri'],
        'https://web.example.com/app/oauth2redirect',
      );
      expect(url.queryParameters['code_challenge_method'], 'S256');
      expect(url.queryParameters['scope'], contains('offline_access'));

      final exchange = seen.last;
      expect(exchange.method, 'POST');
      expect(exchange.url.path, '/tenant/token');
      final form = exchange.bodyFields;
      expect(form['grant_type'], 'authorization_code');
      expect(form['code'], 'the-code');
      expect(form['client_id'], 'app-client');
      expect(form.containsKey('client_secret'), isFalse);
      // The verifier sent now is the one the challenge was made from.
      expect(
        codeChallenge(form['code_verifier']!),
        url.queryParameters['code_challenge'],
      );
    });

    test('refuses an answer whose state is not ours', () async {
      final client = WebAuthOidcClient(
        _settings,
        httpClient: _assay([]),
        browser: _browser(
          (url) =>
              'https://web.example.com/app/oauth2redirect?state=other&code=x',
          [],
        ),
      );
      await expectLater(
        client.authorize(),
        throwsA(isA<InfrastructureError>()),
      );
    });

    test('refuses a redirect to another page', () async {
      final client = WebAuthOidcClient(
        _settings,
        httpClient: _assay([]),
        browser: _browser(
          (url) =>
              _redirectWith(url)
                  .replaceFirst('web.example.com', 'evil.example.com'),
          [],
        ),
      );
      await expectLater(
        client.authorize(),
        throwsA(isA<InfrastructureError>()),
      );
    });

    test('access_denied is a decline, not a failure to report', () async {
      final client = WebAuthOidcClient(
        _settings,
        httpClient: _assay([]),
        browser: _browser(
          (url) => _redirectWith(url, code: null, error: 'access_denied'),
          [],
        ),
      );
      await expectLater(
        client.authorize(),
        throwsA(isA<SignInCancelledError>()),
      );
    });

    test('closing the browser is a cancellation', () async {
      final client = WebAuthOidcClient(
        _settings,
        httpClient: _assay([]),
        browser: (url, settings) async =>
            throw PlatformException(code: 'CANCELED'),
      );
      await expectLater(
        client.authorize(),
        throwsA(isA<SignInCancelledError>()),
      );
    });

    test(
      'an invalid_grant from the token endpoint means sign in again',
      () async {
        final client = WebAuthOidcClient(
          _settings,
          httpClient: _assay(
            [],
            token: const {'error': 'invalid_grant'},
            tokenStatus: 400,
          ),
          browser: _browser(_redirectWith, []),
        );
        await expectLater(
          client.authorize(),
          throwsA(isA<SignInRequiredError>()),
        );
      },
    );
  });

  group('refresh', () {
    test('trades the refresh token without a secret', () async {
      final seen = <http.Request>[];
      final client = WebAuthOidcClient(
        _settings,
        httpClient: _assay(
          seen,
          token: const {
            'access_token': 'at2',
            'expires_in': 300,
            'refresh_token': 'rt2',
          },
        ),
        browser: (url, settings) async => fail('the browser must not open'),
      );

      final tokens = await client.refresh('rt');

      expect(tokens.accessToken, 'at2');
      expect(tokens.refreshToken, 'rt2');
      final form = seen.last.bodyFields;
      expect(form['grant_type'], 'refresh_token');
      expect(form['refresh_token'], 'rt');
      expect(form['client_id'], 'app-client');
      expect(form.containsKey('client_secret'), isFalse);
    });

    test('a server error is worth retrying, not a sign-out', () async {
      final client = WebAuthOidcClient(
        _settings,
        httpClient: _assay([], token: const {}, tokenStatus: 503),
      );
      await expectLater(
        client.refresh('rt'),
        throwsA(isA<InfrastructureError>()),
      );
    });
  });
}
