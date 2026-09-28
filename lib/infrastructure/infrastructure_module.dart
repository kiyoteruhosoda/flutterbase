import 'package:flutterbase/application/ports/app_logger.dart';
import 'package:flutterbase/application/ports/auth_session.dart';
import 'package:flutterbase/application/ports/external_link_launcher.dart';
import 'package:flutterbase/domain/repositories/app_info_repository.dart';
import 'package:flutterbase/domain/repositories/bookmark_repository.dart';
import 'package:flutterbase/domain/repositories/debug_settings_repository.dart';
import 'package:flutterbase/domain/repositories/language_preference_repository.dart';
import 'package:flutterbase/domain/repositories/theme_preference_repository.dart';
import 'package:flutterbase/domain/value_objects/sign_in_settings.dart';
import 'package:flutterbase/infrastructure/auth/oidc_auth_session.dart';
import 'package:flutterbase/infrastructure/auth/oidc_client.dart';
import 'package:flutterbase/infrastructure/auth/secret_store.dart';
import 'package:flutterbase/infrastructure/database/app_database.dart';
import 'package:flutterbase/infrastructure/links/url_launcher_external_link_launcher.dart';
import 'package:flutterbase/infrastructure/logging/persistent_app_logger.dart';
import 'package:flutterbase/infrastructure/repositories/package_info_app_info_repository.dart';
import 'package:flutterbase/infrastructure/repositories/shared_preferences_debug_settings_repository.dart';
import 'package:flutterbase/infrastructure/repositories/shared_preferences_language_preference_repository.dart';
import 'package:flutterbase/infrastructure/repositories/shared_preferences_theme_preference_repository.dart';
import 'package:flutterbase/infrastructure/repositories/sqflite_bookmark_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Everything Infrastructure offers the rest of the app, exposed only as
/// Domain interfaces and Application ports.
///
/// [create] owns the whole adapter set-up sequence — opening the key-value
/// store, restoring the saved log level, opening the first log file, opening
/// the SQLite database — so that the composition root never has to name a
/// storage technology. That is what keeps `SharedPreferences`, `Database`,
/// `dart:io`, and friends confined to this layer, which
/// `tool/check_architecture.dart` verifies.
final class InfrastructureModule {
  const InfrastructureModule._({
    required this.appLogger,
    required this.debugSettings,
    required this.themePreference,
    required this.languagePreference,
    required this.appInfo,
    required this.bookmarks,
    required this.externalLinks,
    required this.authSession,
  });

  /// Opens every adapter and returns them wired and ready.
  ///
  /// Ordering matters: the debug-settings store has to be readable before the
  /// logger starts, so the very first log line is already filtered at the
  /// level the user chose. The database opens after the logger so that a
  /// migration failure is recorded rather than swallowed.
  ///
  /// [signIn] is the optional sign-in: when it is off (the template's default)
  /// no auth adapter is built at all and [authSession] is null.
  static Future<InfrastructureModule> create({
    SignInSettings signIn = const SignInSettings.disabled(),
  }) async {
    final preferences = await SharedPreferences.getInstance();

    final debugSettings = SharedPreferencesDebugSettingsRepository(preferences);

    final logger = PersistentAppLogger();
    await logger.init(savedLevel: debugSettings.getMinLogLevel());

    final database = await AppDatabase.open();
    logger.info(
      '[Infrastructure] SQLite ready — ${AppDatabase.fileName} '
      'v${AppDatabase.schemaVersion}',
    );

    return InfrastructureModule._(
      appLogger: logger,
      debugSettings: debugSettings,
      themePreference: SharedPreferencesThemePreferenceRepository(preferences),
      languagePreference: SharedPreferencesLanguagePreferenceRepository(
        preferences,
      ),
      appInfo: const PackageInfoAppInfoRepository(),
      bookmarks: SqfliteBookmarkRepository(database),
      externalLinks: const UrlLauncherExternalLinkLauncher(),
      authSession: authSessionFor(signIn),
    );
  }

  /// The sign-in adapter for [settings], or null when the sign-in is off.
  static AuthSession? authSessionFor(SignInSettings settings) {
    if (!settings.isEnabled) return null;
    return OidcAuthSession(
      WebAuthOidcClient(settings),
      const FlutterSecureStorageSecretStore(),
    );
  }

  final AppLogger appLogger;
  final DebugSettingsRepository debugSettings;
  final ThemePreferenceRepository themePreference;
  final LanguagePreferenceRepository languagePreference;
  final AppInfoRepository appInfo;
  final BookmarkRepository bookmarks;
  final ExternalLinkLauncher externalLinks;

  /// Null unless the build carries the sign-in settings.
  final AuthSession? authSession;
}
