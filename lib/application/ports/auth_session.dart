import 'package:flutterbase/domain/entities/account.dart';

/// The optional sign-in (assay, OpenID Connect).
///
/// An outbound port: `infrastructure/auth/` supplies the implementation
/// (Chrome's Auth Tab + PKCE), which keeps the refresh token in the platform
/// keystore and hands out short-lived access tokens. Only registered when the
/// build carries the sign-in settings (`SignInSettings.isEnabled`).
abstract interface class AuthSession {
  /// The account signed in on this device, or null.
  Future<Account?> currentAccount();

  /// Opens the identity provider's sign-in page. Throws
  /// `SignInCancelledError` when the person backs out.
  Future<Account> signIn();

  /// Forgets the tokens on this device.
  Future<void> signOut();

  /// A valid access token for calling the paired web app's API, refreshed
  /// when it is about to expire (or when [forceRefresh] is set, e.g. after the
  /// server answered 401). Throws `SignInRequiredError` when there is no
  /// sign-in or it has run out.
  Future<String> accessToken({bool forceRefresh = false});

  /// The headers that authorize one [method] request to [url] on the paired
  /// web app: `Authorization: Bearer …`, or — when the sign-in is bound to
  /// this phone's key — `Authorization: DPoP …` with a fresh proof and the ID
  /// token (docs/adr/0015-dpop-device-key.md). [forceRefresh] as for
  /// [accessToken].
  Future<Map<String, String>> requestHeaders(
    String method,
    Uri url, {
    bool forceRefresh = false,
  });
}
