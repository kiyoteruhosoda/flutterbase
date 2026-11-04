import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutterbase/infrastructure/auth/dpop/device_key.dart';
import 'package:flutterbase/infrastructure/auth/dpop/server_clock.dart';

/// Makes the DPoP proofs (RFC 9449) that bind the sign-in to this phone
/// (docs/adr/0015-dpop-device-key.md).
///
/// One proof per request: `typ` `dpop+jwt`, `alg` ES256, the public key as
/// `jwk`, and the claims `jti` (random), `htm`, `htu` (no query or fragment),
/// `iat` (the [ServerClock]'s now) and, towards a resource, `ath`.
///
/// ⚠ **No key, no proof.** When the Keystore cannot be used the signer answers
/// null and the app goes on with plain Bearer tokens, as before.
final class DpopProofSigner {
  DpopProofSigner(this._key, this.clock, {Random? random})
    : _random = random ?? Random.secure();

  final DeviceKey _key;

  /// Shared with every HTTP client that talks to assay or the web app, so
  /// each answer's `Date` keeps it right.
  final ServerClock clock;
  final Random _random;

  Future<Map<String, String>?>? _jwk;

  /// A proof for [method] on [url], or null when the key is unavailable.
  /// Pass [accessToken] when calling a resource (not the token endpoint).
  Future<String?> proof(String method, Uri url, {String? accessToken}) async {
    final jwk = await _publicJwk();
    if (jwk == null) return null;
    final header = <String, Object?>{
      'typ': 'dpop+jwt',
      'alg': 'ES256',
      'jwk': jwk,
    };
    final claims = <String, Object?>{
      'jti': _jti(),
      'htm': method.toUpperCase(),
      'htu': proofTarget(url),
      'iat': clock.now().millisecondsSinceEpoch ~/ 1000,
      if (accessToken != null) 'ath': accessTokenHash(accessToken),
    };
    final signingInput =
        '${_b64(utf8.encode(jsonEncode(header)))}.'
        '${_b64(utf8.encode(jsonEncode(claims)))}';
    final Uint8List der;
    try {
      der = await _key.signDer(Uint8List.fromList(ascii.encode(signingInput)));
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
    return '$signingInput.${_b64(joseSignatureFromDer(der))}';
  }

  /// Forgets the key, so the next sign-in binds to a new one.
  Future<void> forgetKey() async {
    _jwk = null;
    try {
      await _key.delete();
    } on PlatformException {
      // Nothing to forget.
    } on MissingPluginException {
      // No Keystore here.
    }
  }

  Future<Map<String, String>?> _publicJwk() =>
      _jwk ??= _readPublicJwk().then((jwk) {
        // Not cached when unavailable: the Keystore may be back next time.
        if (jwk == null) _jwk = null;
        return jwk;
      });

  Future<Map<String, String>?> _readPublicJwk() async {
    final DevicePublicKey key;
    try {
      key = await _key.publicKey();
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
    return <String, String>{
      'kty': 'EC',
      'crv': 'P-256',
      'x': _b64(key.x),
      'y': _b64(key.y),
    };
  }

  String _jti() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    return _b64(bytes);
  }
}

/// `htu`: the URL without its query and fragment (RFC 9449 §4.2).
String proofTarget(Uri url) => Uri(
  scheme: url.scheme,
  userInfo: url.userInfo,
  host: url.host,
  port: url.hasPort ? url.port : null,
  path: url.path,
).toString();

/// `ath`: base64url(SHA-256(access token)), no padding.
String accessTokenHash(String accessToken) =>
    _b64(sha256.convert(ascii.encode(accessToken)).bytes);

/// Turns the Keystore's DER `ECDSA-Sig-Value` into JOSE's `r || s`
/// (32 bytes each, RFC 7518 §3.4).
Uint8List joseSignatureFromDer(Uint8List der) {
  var index = 0;
  int byte() {
    if (index >= der.length) {
      throw const FormatException('The DER signature ended early.');
    }
    return der[index++];
  }

  int length() {
    final first = byte();
    if (first < 0x80) return first;
    var value = 0;
    for (var i = 0; i < (first & 0x7f); i++) {
      value = (value << 8) | byte();
    }
    return value;
  }

  Uint8List integer() {
    if (byte() != 0x02) throw const FormatException('Expected an INTEGER.');
    final size = length();
    if (index + size > der.length) {
      throw const FormatException('The INTEGER runs past the signature.');
    }
    var bytes = der.sublist(index, index + size);
    index += size;
    // Strip the sign byte(s), then left-pad to 32.
    var start = 0;
    while (bytes.length - start > 32 && bytes[start] == 0) {
      start++;
    }
    bytes = bytes.sublist(start);
    if (bytes.length > 32) throw const FormatException('INTEGER too long.');
    return Uint8List(32)..setRange(32 - bytes.length, 32, bytes);
  }

  if (byte() != 0x30) throw const FormatException('Expected a SEQUENCE.');
  length();
  final r = integer();
  final s = integer();
  return Uint8List(64)
    ..setRange(0, 32, r)
    ..setRange(32, 64, s);
}

String _b64(List<int> bytes) => base64Url.encode(bytes).replaceAll('=', '');
