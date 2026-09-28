import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:flutterbase/domain/errors/app_error.dart';
import 'package:flutterbase/domain/value_objects/sign_in_settings.dart';
import 'package:http/http.dart' as http;

/// The tokens one sign-in or refresh produced.
final class OidcTokens {
  const OidcTokens({
    required this.accessToken,
    required this.expiresAt,
    this.refreshToken,
    this.idToken,
  });

  final String accessToken;

  /// UTC.
  final DateTime expiresAt;

  /// assay rotates it on every refresh; null when the provider sent none.
  final String? refreshToken;
  final String? idToken;
}

/// The OpenID Connect calls the session needs, behind a seam so the
/// session's logic can be tested without the platform plugin.
abstract interface class OidcClient {
  /// Authorization Code + PKCE in the browser (Chrome's Auth Tab).
  Future<OidcTokens> authorize();

  /// Trades [refreshToken] for new tokens.
  Future<OidcTokens> refresh(String refreshToken);
}

/// Opens [url] in the browser and returns the full redirect URL it ended on.
///
/// The default ([openAuthTab]) is flutter_web_auth_2; tests pass a fake.
typedef BrowserSignIn = Future<String> Function(
  Uri url,
  SignInSettings settings,
);

/// The browser half over flutter_web_auth_2: on Android, Chrome's Auth Tab.
///
/// ⚠ **Why not a plain Custom Tab** (docs/adr/0008-auth-tab-sign-in.md): a
/// Custom Tab only hands an https redirect to the app when the navigation
/// follows a tap, so it strands the sign-in whenever assay redirects on its
/// own (already signed in, after a passkey). The Auth Tab returns the redirect
/// for [SignInSettings.linkHost] + [SignInSettings.redirectPath] to the app
/// directly, after checking the web app's `assetlinks.json`.
Future<String> openAuthTab(Uri url, SignInSettings settings) {
  return FlutterWebAuth2.authenticate(
    url: url.toString(),
    callbackUrlScheme: 'https',
    options: FlutterWebAuth2Options(
      httpsHost: settings.linkHost.trim(),
      httpsPath: SignInSettings.redirectPath,
    ),
  );
}

/// [OidcClient] written against assay's endpoints directly: flutter_web_auth_2
/// only opens the browser, so PKCE, the redirect checks and the token requests
/// live here.
final class WebAuthOidcClient implements OidcClient {
  WebAuthOidcClient(
    this._settings, {
    this.scopes = const ['openid', 'profile', 'email', 'offline_access'],
    http.Client? httpClient,
    this.browser = openAuthTab,
    Random? random,
    this.timeout = const Duration(seconds: 20),
  }) : _http = httpClient ?? http.Client(),
       _random = random ?? Random.secure();

  final SignInSettings _settings;
  final List<String> scopes;
  final http.Client _http;

  /// Opens the browser; flutter_web_auth_2 unless a test passes a fake.
  final BrowserSignIn browser;
  final Random _random;
  final Duration timeout;

  _Endpoints? _endpoints;

  @override
  Future<OidcTokens> authorize() async {
    final endpoints = await _discover();
    final verifier = _randomToken(64);
    final state = _randomToken(32);
    final url = endpoints.authorization.replace(
      queryParameters: {
        ...endpoints.authorization.queryParameters,
        'response_type': 'code',
        'client_id': _settings.clientId.trim(),
        'redirect_uri': _settings.redirectUri,
        'scope': scopes.join(' '),
        'state': state,
        'code_challenge': codeChallenge(verifier),
        'code_challenge_method': 'S256',
      },
    );
    final String returned;
    try {
      returned = await browser(url, _settings);
    } on PlatformException catch (e) {
      if (e.code == 'CANCELED') {
        throw const SignInCancelledError('Sign-in was cancelled.');
      }
      throw InfrastructureError('Sign-in failed: ${e.code}', cause: e);
    }
    final code = redirectCode(Uri.parse(returned), _settings, state);
    return _token(endpoints, {
      'grant_type': 'authorization_code',
      'code': code,
      'redirect_uri': _settings.redirectUri,
      'client_id': _settings.clientId.trim(),
      'code_verifier': verifier,
    });
  }

  @override
  Future<OidcTokens> refresh(String refreshToken) async {
    final endpoints = await _discover();
    return _token(endpoints, {
      'grant_type': 'refresh_token',
      'refresh_token': refreshToken,
      'client_id': _settings.clientId.trim(),
    });
  }

  Future<_Endpoints> _discover() async {
    final cached = _endpoints;
    if (cached != null) return cached;
    final issuer = _settings.issuer.trim().replaceAll(RegExp(r'/+$'), '');
    final body = await _json(
      () => _http.get(Uri.parse('$issuer/.well-known/openid-configuration')),
      'discovery',
    );
    final authorization = body['authorization_endpoint'];
    final token = body['token_endpoint'];
    if (authorization is! String || token is! String) {
      throw const InfrastructureError(
        'The identity provider did not name its endpoints.',
      );
    }
    return _endpoints = _Endpoints(Uri.parse(authorization), Uri.parse(token));
  }

  Future<OidcTokens> _token(
    _Endpoints endpoints,
    Map<String, String> form,
  ) async {
    final body = await _json(
      () => _http.post(
        endpoints.token,
        headers: const {'Accept': 'application/json'},
        body: form,
      ),
      'token',
      oauthErrors: true,
    );
    final accessToken = body['access_token'];
    if (accessToken is! String || accessToken.isEmpty) {
      throw const SignInRequiredError('The sign-in returned no access token.');
    }
    final expiresIn = body['expires_in'];
    return OidcTokens(
      accessToken: accessToken,
      expiresAt: DateTime.now().toUtc().add(
        Duration(seconds: expiresIn is num ? expiresIn.toInt() : 300),
      ),
      refreshToken: body['refresh_token'] as String?,
      idToken: body['id_token'] as String?,
    );
  }

  /// Sends [request] and decodes the JSON object it answers with.
  ///
  /// An OAuth error body (`{"error": ...}`) becomes [oidcFailure] when
  /// [oauthErrors] is set; anything else that is not a 200 is a network-ish
  /// failure worth retrying.
  Future<Map<String, Object?>> _json(
    Future<http.Response> Function() request,
    String what, {
    bool oauthErrors = false,
  }) async {
    final http.Response response;
    try {
      response = await request().timeout(timeout);
    } on TimeoutException catch (e) {
      throw InfrastructureError('The $what request timed out.', cause: e);
    } on http.ClientException catch (e) {
      throw InfrastructureError('The $what request failed.', cause: e);
    }
    Object? decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      decoded = null;
    }
    final body = decoded is Map<String, Object?> ? decoded : null;
    if (response.statusCode == 200 && body != null) return body;
    final error = body?['error'];
    if (oauthErrors && error is String) throw oidcFailure(error, response.body);
    throw InfrastructureError(
      'The $what request answered ${response.statusCode}.',
    );
  }

  String _randomToken(int length) {
    const alphabet =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    return List.generate(
      length,
      (_) => alphabet[_random.nextInt(alphabet.length)],
    ).join();
  }
}

final class _Endpoints {
  const _Endpoints(this.authorization, this.token);

  final Uri authorization;
  final Uri token;
}

/// PKCE S256: base64url(SHA-256(verifier)) without padding (RFC 7636 §4.2).
String codeChallenge(String verifier) {
  final digest = sha256.convert(ascii.encode(verifier));
  return base64Url.encode(digest.bytes).replaceAll('=', '');
}

/// The authorization code out of the redirect the browser returned.
///
/// ⚠ Checks, in this order: the redirect is ours (https, [SignInSettings.
/// linkHost], [SignInSettings.redirectPath]); the `state` is the one this
/// sign-in sent (otherwise the response belongs to another attempt, or was
/// forged); the provider did not answer with an `error`.
String redirectCode(Uri redirect, SignInSettings settings, String state) {
  if (redirect.scheme != 'https' ||
      redirect.host != settings.linkHost.trim() ||
      redirect.path != SignInSettings.redirectPath) {
    throw const InfrastructureError('The sign-in returned to an unknown page.');
  }
  final params = redirect.queryParameters;
  if (params['state'] != state) {
    throw const InfrastructureError('The sign-in answer did not match.');
  }
  final error = params['error'];
  if (error != null) {
    if (error == 'access_denied') {
      throw const SignInCancelledError('Sign-in was declined.');
    }
    throw oidcFailure(error, redirect);
  }
  final code = params['code'];
  if (code == null || code.isEmpty) {
    throw const InfrastructureError('The sign-in returned no code.');
  }
  return code;
}

/// Classifies an OAuth error: the ones that mean "this sign-in is over"
/// require signing in again; anything else may be the network and is worth
/// retrying.
AppError oidcFailure(String? oauthError, Object cause) {
  return switch (oauthError) {
    'invalid_grant' || 'invalid_client' || 'unauthorized_client' =>
      SignInRequiredError('The sign-in is no longer valid ($oauthError).'),
    _ => InfrastructureError(
      'Sign-in failed (${oauthError ?? 'unknown'}).',
      cause: cause,
    ),
  };
}
