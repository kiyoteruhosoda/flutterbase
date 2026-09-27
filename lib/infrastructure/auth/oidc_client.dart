import 'package:flutter/services.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutterbase/domain/errors/app_error.dart';
import 'package:flutterbase/domain/value_objects/sign_in_settings.dart';

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
  /// Authorization Code + PKCE in the browser (Custom Tabs).
  Future<OidcTokens> authorize();

  /// Trades [refreshToken] for new tokens.
  Future<OidcTokens> refresh(String refreshToken);
}

/// [OidcClient] over AppAuth.
///
/// assay registers only http(s) redirect URIs, so the redirect is an App
/// Link that AppAuth's `RedirectUriReceiverActivity` claims (see
/// `AndroidManifest.xml` and `docs/adr/0007-optional-assay-sign-in.md`).
final class FlutterAppAuthOidcClient implements OidcClient {
  const FlutterAppAuthOidcClient(
    this._settings, {
    this.scopes = const ['openid', 'profile', 'email', 'offline_access'],
    this._appAuth = const FlutterAppAuth(),
  });

  final SignInSettings _settings;
  final List<String> scopes;
  final FlutterAppAuth _appAuth;

  @override
  Future<OidcTokens> authorize() {
    return _call(
      () => _appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          _settings.clientId,
          _settings.redirectUri,
          issuer: _settings.issuer,
          scopes: scopes,
        ),
      ),
    );
  }

  @override
  Future<OidcTokens> refresh(String refreshToken) {
    return _call(
      () => _appAuth.token(
        TokenRequest(
          _settings.clientId,
          _settings.redirectUri,
          issuer: _settings.issuer,
          scopes: scopes,
          refreshToken: refreshToken,
        ),
      ),
    );
  }

  Future<OidcTokens> _call(Future<TokenResponse> Function() request) async {
    final TokenResponse response;
    try {
      response = await request();
    } on FlutterAppAuthUserCancelledException {
      throw const SignInCancelledError('Sign-in was cancelled.');
    } on FlutterAppAuthPlatformException catch (e) {
      throw oidcFailure(e.platformErrorDetails.error, e);
    } on PlatformException catch (e) {
      throw InfrastructureError('Sign-in failed: ${e.code}', cause: e);
    }
    final accessToken = response.accessToken;
    if (accessToken == null) {
      throw const SignInRequiredError('The sign-in returned no access token.');
    }
    return OidcTokens(
      accessToken: accessToken,
      expiresAt:
          response.accessTokenExpirationDateTime?.toUtc() ??
          DateTime.now().toUtc().add(const Duration(minutes: 5)),
      refreshToken: response.refreshToken,
      idToken: response.idToken,
    );
  }
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
