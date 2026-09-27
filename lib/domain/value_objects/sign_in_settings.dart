/// Where the optional sign-in (assay, OpenID Connect) goes — or that there is
/// none.
///
/// The template ships without a sign-in: all three values come from
/// `--dart-define` at build time (`OIDC_ISSUER`, `OIDC_CLIENT_ID`,
/// `APP_LINK_HOST`) and default to empty. **If any one is empty the sign-in is
/// off**: no menu entry, no screen, no plugin call. See
/// `docs/adr/0007-optional-assay-sign-in.md`.
///
/// Pure Dart, like every value object here; the composition root builds one
/// from `AppConfig` and hands it to both Infrastructure and Presentation.
final class SignInSettings {
  const SignInSettings({
    required this.issuer,
    required this.clientId,
    required this.linkHost,
  });

  /// No sign-in — what a build without the three `--dart-define`s gets.
  const SignInSettings.disabled() : issuer = '', clientId = '', linkHost = '';

  /// Path of the sign-in redirect on [linkHost].
  ///
  /// assay only registers http(s) redirect URIs, so the browser returns to the
  /// app through a verified App Link on this path — never a custom scheme,
  /// which any other app could claim. `AndroidManifest.xml` hands exactly this
  /// path to AppAuth's `RedirectUriReceiverActivity`.
  static const String redirectPath = '/app/oauth2redirect';

  /// The identity provider's issuer, e.g.
  /// `https://identity.nolumia.com/<tenant>`.
  final String issuer;

  /// The app's public client (PKCE, no secret) registered at [issuer].
  final String clientId;

  /// Host of the web app this app pairs with, e.g. `recipebox.nolumia.com`.
  /// It serves `/.well-known/assetlinks.json`, which is what lets Android
  /// verify the redirect below.
  final String linkHost;

  /// True only when all three values are present.
  bool get isEnabled =>
      issuer.trim().isNotEmpty &&
      clientId.trim().isNotEmpty &&
      linkHost.trim().isNotEmpty;

  /// The redirect URI registered at [issuer] for [clientId].
  String get redirectUri => 'https://${linkHost.trim()}$redirectPath';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SignInSettings &&
          other.issuer == issuer &&
          other.clientId == clientId &&
          other.linkHost == linkHost);

  @override
  int get hashCode => Object.hash(issuer, clientId, linkHost);

  @override
  String toString() =>
      isEnabled ? 'SignInSettings($issuer, $clientId)' : 'SignInSettings(off)';
}
