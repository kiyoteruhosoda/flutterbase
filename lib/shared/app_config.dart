/// Single source of truth for per-app identity values that live in Dart.
///
/// When forking the template for a new app, edit the values in this file
/// and follow `docs/CUSTOMISATION.md` for the surfaces that cannot be
/// centralised here (bundle IDs, launcher icons, font binaries).
///
/// Conventions (mirrors [AppColors]):
///   - `class` + private ctor + `static const` fields
///   - no state, no DI, importable anywhere
class AppConfig {
  AppConfig._();

  // ─── Identity ─────────────────────────────────────────────────────
  /// Display name shown in the MaterialApp title, drawer header,
  /// and About page.
  static const String appName = 'FlutterBase';

  /// One-line description shown on the About page.
  static const String appDescription =
      'Flutter base app following the DADS design system';

  /// Short tagline rendered under the app name in the drawer.
  static const String appTagline = 'DADS Design System';

  // ─── Home page copy ───────────────────────────────────────────────
  static const String homeSubtitle = 'DADS Design System App';
  static const String homeCardTitle = 'DADS Design System';

  // ─── Deep links (App Links) ───────────────────────────────────────
  /// Domain that Android verifies against
  /// `https://<appLinkHost>/.well-known/assetlinks.json`.
  ///
  /// Must match the `android:host` of the `autoVerify` intent filter in
  /// `android/app/src/main/AndroidManifest.xml`. Change both together, or
  /// verification silently fails and links open in the browser instead.
  /// See `docs/DEEP_LINKS.md`.
  static const String appLinkHost = 'flutterbase.example.com';

  /// Scheme of the verified App Link. Android only verifies `https`.
  static const String appLinkScheme = 'https';

  /// Unverified fallback scheme, e.g. `flutterbase://bookmarks/1`.
  ///
  /// Any app may claim a custom scheme, so this is for local testing and for
  /// platforms without App Links — never for links a stranger can send.
  static const String customLinkScheme = 'flutterbase';

  /// The verified `https` link that opens [path] inside the app.
  static Uri appLink(String path) =>
      Uri.parse('$appLinkScheme://$appLinkHost$path');

  /// The custom-scheme equivalent of [appLink].
  ///
  /// Produces the three-slash form (`flutterbase:///bookmarks/1`) on purpose.
  /// Android's Flutter embedding builds the in-app route from the incoming
  /// URI's *path* and discards its authority, so `flutterbase://bookmarks/1`
  /// would arrive as the route `/1` — with an empty authority the whole
  /// `/bookmarks/1` survives and matches the same route the App Link does.
  static Uri customLink(String path) => Uri.parse('$customLinkScheme://$path');

  // ─── Sign-in (optional; assay, OpenID Connect) ─────────────────────
  // All three come from `--dart-define` and are empty by default. **If any is
  // empty, the sign-in is off** — no menu entry, no screen. The release
  // pipeline passes them for apps that pair with a web app; see
  // `docs/adr/0007-optional-assay-sign-in.md` and `docs/RELEASE.md`.

  /// assay's issuer, e.g. `https://identity.nolumia.com/<tenant>`. Must equal
  /// the paired web app's `OIDC_ISSUER`, or its API rejects the app's tokens.
  static const String oidcIssuer = String.fromEnvironment('OIDC_ISSUER');

  /// The app's public client (PKCE) in assay. The paired web app accepts only
  /// tokens issued to a client listed in its `APP_CLIENT_IDS`.
  static const String oidcClientId = String.fromEnvironment('OIDC_CLIENT_ID');

  /// Host of the paired web app, which serves `/.well-known/assetlinks.json`
  /// for this app. The sign-in redirect returns through an App Link on it.
  ///
  /// ⚠ Not [appLinkHost]: that one is the template's own deep-link domain.
  /// The Android side of this value is the Gradle property `appLinkHost`
  /// (`-PappLinkHost=...`), which fills the redirect's intent filter.
  static const String signInLinkHost = String.fromEnvironment('APP_LINK_HOST');

  // ─── Typography ───────────────────────────────────────────────────
  /// Must exactly match the `family:` entry in `pubspec.yaml`'s fonts
  /// section. Both values are the contract between Flutter's font loader
  /// and the declared assets — drift causes silent fallback to system fonts.
  static const String fontFamily = 'NotoSansJP';

  // ─── Design system attribution (About + LicenseRegistry) ──────────
  static const String designSystemLabel = 'DADS v2.10.3';
  static const String designSystemName = 'Digital Agency Design System (DADS)';
  static const String designSystemUrl = 'https://design.digital.go.jp/';
  static const String designSystemLicense = 'CC BY 4.0';
}
