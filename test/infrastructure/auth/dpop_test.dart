import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutterbase/domain/errors/app_error.dart';
import 'package:flutterbase/domain/value_objects/sign_in_settings.dart';
import 'package:flutterbase/infrastructure/auth/dpop/device_key.dart';
import 'package:flutterbase/infrastructure/auth/dpop/dpop_proof_signer.dart';
import 'package:flutterbase/infrastructure/auth/dpop/server_clock.dart';
import 'package:flutterbase/infrastructure/auth/oidc_auth_session.dart';
import 'package:flutterbase/infrastructure/auth/oidc_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'oidc_auth_session_test.dart' show MemorySecretStore;

/// A Keystore stand-in: a fixed public key and a fixed DER signature.
final class _FakeDeviceKey implements DeviceKey {
  Exception? failure;
  int deletes = 0;
  final List<Uint8List> signed = <Uint8List>[];

  static final Uint8List x = Uint8List.fromList(List.filled(32, 1));
  static final Uint8List y = Uint8List.fromList(List.filled(32, 2));

  @override
  Future<DevicePublicKey> publicKey() async {
    final error = failure;
    if (error != null) throw error;
    return DevicePublicKey(x, y);
  }

  @override
  Future<Uint8List> signDer(Uint8List message) async {
    final error = failure;
    if (error != null) throw error;
    signed.add(message);
    // SEQUENCE { INTEGER 0x00 0x80.. (33 bytes), INTEGER 0x05 (1 byte) }
    return Uint8List.fromList([
      0x30, 0x26, //
      0x02, 0x21, 0x00, ...List.filled(32, 0x80),
      0x02, 0x01, 0x05,
    ]);
  }

  @override
  Future<void> delete() async => deletes++;
}

Map<String, Object?> _part(String jwt, int index) => jsonDecode(
  utf8.decode(base64Url.decode(base64Url.normalize(jwt.split('.')[index]))),
) as Map<String, Object?>;

DpopProofSigner _signer(_FakeDeviceKey key, {DateTime? now}) => DpopProofSigner(
  key,
  ServerClock(now: () => now ?? DateTime.utc(2026, 11, 4, 12)),
);

void main() {
  group('joseSignatureFromDer', () {
    test('drops the sign byte and left-pads to 32 bytes each', () {
      final jose = joseSignatureFromDer(
        Uint8List.fromList([
          0x30, 0x26, //
          0x02, 0x21, 0x00, ...List.filled(32, 0x80),
          0x02, 0x01, 0x05,
        ]),
      );
      expect(jose.length, 64);
      expect(jose.sublist(0, 32), List.filled(32, 0x80));
      expect(jose.sublist(32, 63), List.filled(31, 0));
      expect(jose[63], 0x05);
    });

    test('refuses what is not a DER signature', () {
      expect(
        () => joseSignatureFromDer(Uint8List.fromList([0x31, 0x00])),
        throwsFormatException,
      );
    });
  });

  test('htu leaves out the query and the fragment', () {
    expect(
      proofTarget(Uri.parse('https://web.example.com/api/app/me?x=1#y')),
      'https://web.example.com/api/app/me',
    );
  });

  test('ath is base64url(SHA-256) without padding', () {
    expect(
      accessTokenHash('at-0'),
      'Gs7cQ5aHRrDprDne1_0xLMy2ySAWHsa8_qMPVzdQmoU',
    );
  });

  group('DpopProofSigner', () {
    test('signs a dpop+jwt with the device key', () async {
      final key = _FakeDeviceKey();
      final proof = await _signer(key).proof(
        'get',
        Uri.parse('https://web.example.com/api/app/me?x=1'),
        accessToken: 'at-0',
      );

      final header = _part(proof!, 0);
      expect(header['typ'], 'dpop+jwt');
      expect(header['alg'], 'ES256');
      expect(header['jwk'], {
        'kty': 'EC',
        'crv': 'P-256',
        'x': base64Url.encode(_FakeDeviceKey.x).replaceAll('=', ''),
        'y': base64Url.encode(_FakeDeviceKey.y).replaceAll('=', ''),
      });
      final claims = _part(proof, 1);
      expect(claims['htm'], 'GET');
      expect(claims['htu'], 'https://web.example.com/api/app/me');
      expect(
        claims['iat'],
        DateTime.utc(2026, 11, 4, 12).millisecondsSinceEpoch ~/ 1000,
      );
      expect(claims['ath'], accessTokenHash('at-0'));
      expect((claims['jti']! as String).length, greaterThanOrEqualTo(16));
      // The signature is JOSE r||s, signed over `header.claims`.
      final signature = base64Url.decode(
        base64Url.normalize(proof.split('.')[2]),
      );
      expect(signature.length, 64);
      final input = proof.substring(0, proof.lastIndexOf('.'));
      expect(utf8.decode(key.signed.single), input);
    });

    test('every proof has its own jti', () async {
      final signer = _signer(_FakeDeviceKey());
      final url = Uri.parse('https://identity.example.com/tenant/token');
      final a = _part((await signer.proof('POST', url))!, 1);
      final b = _part((await signer.proof('POST', url))!, 1);
      expect(a['jti'], isNot(b['jti']));
      expect(a.containsKey('ath'), isFalse);
    });

    test('no Keystore, no proof', () async {
      final url = Uri.parse('https://web.example.com/');
      final missing = _FakeDeviceKey()..failure = MissingPluginException();
      expect(await _signer(missing).proof('GET', url), isNull);
      final broken = _FakeDeviceKey()..failure = PlatformException(code: 'x');
      expect(await _signer(broken).proof('GET', url), isNull);
    });
  });

  group('ServerClock', () {
    test('follows a server whose clock differs by minutes', () {
      final local = DateTime.utc(2026, 11, 4, 12);
      final clock = ServerClock(now: () => local)
        ..observe({'date': 'Wed, 04 Nov 2026 12:10:00 GMT'});
      expect(clock.now(), DateTime.utc(2026, 11, 4, 12, 10));
    });

    test('ignores a few seconds and unreadable dates', () {
      final local = DateTime.utc(2026, 11, 4, 12);
      final clock = ServerClock(now: () => local)
        ..observe({'date': 'Wed, 04 Nov 2026 12:00:03 GMT'})
        ..observe({'date': 'yesterday'});
      expect(clock.now(), local);
    });
  });

  group('the token endpoint with DPoP', () {
    const settings = SignInSettings(
      issuer: 'https://identity.example.com/tenant',
      clientId: 'app-client',
      linkHost: 'web.example.com',
    );

    MockClient assay(List<http.Request> seen, List<http.Response> answers) {
      return MockClient((request) async {
        seen.add(request);
        if (request.url.path.endsWith('/.well-known/openid-configuration')) {
          return http.Response(
            jsonEncode({
              'authorization_endpoint': '${settings.issuer}/authorize',
              'token_endpoint': '${settings.issuer}/token',
            }),
            200,
          );
        }
        return answers.removeAt(0);
      });
    }

    test('sends a proof and reads token_type DPoP', () async {
      final seen = <http.Request>[];
      final client = WebAuthOidcClient(
        settings,
        dpop: _signer(_FakeDeviceKey()),
        httpClient: assay(seen, [
          http.Response(
            jsonEncode({
              'access_token': 'at',
              'token_type': 'DPoP',
              'expires_in': 300,
              'refresh_token': 'rt2',
            }),
            200,
          ),
        ]),
      );

      final tokens = await client.refresh('rt');

      expect(tokens.boundToKey, isTrue);
      final proof = seen.last.headers['DPoP']!;
      expect(_part(proof, 1)['htm'], 'POST');
      expect(_part(proof, 1)['htu'], '${settings.issuer}/token');
    });

    test('retries once with a fresh proof after invalid_dpop_proof', () async {
      final seen = <http.Request>[];
      final client = WebAuthOidcClient(
        settings,
        dpop: _signer(_FakeDeviceKey()),
        httpClient: assay(seen, [
          http.Response(jsonEncode({'error': 'invalid_dpop_proof'}), 400),
          http.Response(
            jsonEncode({
              'access_token': 'at',
              'token_type': 'DPoP',
              'refresh_token': 'rt2',
            }),
            200,
          ),
        ]),
      );

      expect((await client.refresh('rt')).accessToken, 'at');
      final proofs = seen
          .where((r) => r.url.path.endsWith('/token'))
          .map((r) => r.headers['DPoP']);
      expect(proofs.length, 2);
      expect(proofs.first, isNot(proofs.last));
    });

    test('a second refusal is worth retrying later, not a sign-out', () async {
      final client = WebAuthOidcClient(
        settings,
        dpop: _signer(_FakeDeviceKey()),
        httpClient: assay([], [
          http.Response(jsonEncode({'error': 'invalid_dpop_proof'}), 400),
          http.Response(jsonEncode({'error': 'invalid_dpop_proof'}), 400),
        ]),
      );
      await expectLater(
        client.refresh('rt'),
        throwsA(isA<InfrastructureError>()),
      );
    });

    test('without a signer nothing changes (Bearer)', () async {
      final seen = <http.Request>[];
      final client = WebAuthOidcClient(
        settings,
        httpClient: assay(seen, [
          http.Response(
            jsonEncode({'access_token': 'at', 'token_type': 'Bearer'}),
            200,
          ),
        ]),
      );
      expect((await client.refresh('rt')).boundToKey, isFalse);
      expect(seen.last.headers.containsKey('DPoP'), isFalse);
    });
  });

  group('OidcAuthSession with DPoP', () {
    final api = Uri.parse('https://web.example.com/api/app/me');

    OidcAuthSession session(_FakeDeviceKey key, String tokenType) {
      return OidcAuthSession(
        _OneShotClient(tokenType),
        MemorySecretStore(),
        now: () => DateTime.utc(2026, 11, 4, 12),
        dpop: _signer(key),
      );
    }

    test('a bound sign-in sends DPoP, a proof and the ID token', () async {
      final key = _FakeDeviceKey();
      final signedIn = session(key, 'DPoP');
      await signedIn.signIn();

      final headers = await signedIn.requestHeaders('GET', api);

      expect(headers['Authorization'], 'DPoP at-0');
      expect(_part(headers['DPoP']!, 1)['ath'], accessTokenHash('at-0'));
      expect(headers['X-ID-Token'], _OneShotClient.idToken);
    });

    test('an unbound sign-in stays Bearer', () async {
      final signedIn = session(_FakeDeviceKey(), 'Bearer');
      await signedIn.signIn();

      expect(await signedIn.requestHeaders('GET', api), {
        'Authorization': 'Bearer at-0',
      });
    });

    test('signing out forgets the key', () async {
      final key = _FakeDeviceKey();
      final signedIn = session(key, 'DPoP');
      await signedIn.signIn();
      await signedIn.signOut();
      expect(key.deletes, 1);
    });
  });
}

final class _OneShotClient implements OidcClient {
  _OneShotClient(this.tokenType);

  final String tokenType;

  static const String idToken = 'eyJhbGciOiJSUzI1NiJ9.eyJuYW1lIjoiS3lvbiJ9.sig';

  @override
  Future<OidcTokens> authorize() async => OidcTokens(
    accessToken: 'at-0',
    expiresAt: DateTime.utc(2026, 11, 4, 12, 5),
    refreshToken: 'rt-0',
    idToken: idToken,
    tokenType: tokenType,
  );

  @override
  Future<OidcTokens> refresh(String refreshToken) => throw UnimplementedError();
}
