import 'package:flutterbase/application/ports/app_logger.dart';
import 'package:flutterbase/application/ports/auth_session.dart';
import 'package:flutterbase/application/ports/external_link_launcher.dart';
import 'package:flutterbase/application/ports/push_messaging.dart';
import 'package:flutterbase/application/usecases/app_info/get_app_info_usecase.dart';
import 'package:flutterbase/application/usecases/app_update/check_for_update_usecase.dart';
import 'package:flutterbase/application/usecases/app_update/dismiss_update_usecase.dart';
import 'package:flutterbase/application/usecases/app_update/open_update_download_usecase.dart';
import 'package:flutterbase/application/usecases/auth/get_current_account_usecase.dart';
import 'package:flutterbase/application/usecases/auth/sign_in_usecase.dart';
import 'package:flutterbase/application/usecases/auth/sign_out_usecase.dart';
import 'package:flutterbase/application/usecases/bookmark/add_bookmark_usecase.dart';
import 'package:flutterbase/application/usecases/bookmark/get_bookmark_usecase.dart';
import 'package:flutterbase/application/usecases/bookmark/list_bookmarks_usecase.dart';
import 'package:flutterbase/application/usecases/bookmark/open_bookmark_usecase.dart';
import 'package:flutterbase/application/usecases/bookmark/remove_bookmark_usecase.dart';
import 'package:flutterbase/application/usecases/debug/get_debug_settings_usecase.dart';
import 'package:flutterbase/application/usecases/debug/set_debug_mode_usecase.dart';
import 'package:flutterbase/application/usecases/debug/set_log_level_usecase.dart';
import 'package:flutterbase/application/usecases/language/get_language_preference_usecase.dart';
import 'package:flutterbase/application/usecases/language/set_language_preference_usecase.dart';
import 'package:flutterbase/application/usecases/notices/dismiss_notice_usecase.dart';
import 'package:flutterbase/application/usecases/notices/list_notices_usecase.dart';
import 'package:flutterbase/application/usecases/notices/mark_all_notices_read_usecase.dart';
import 'package:flutterbase/application/usecases/notices/mark_notice_read_usecase.dart';
import 'package:flutterbase/application/usecases/notices/open_notice_link_usecase.dart';
import 'package:flutterbase/application/usecases/push/open_push_tap_usecase.dart';
import 'package:flutterbase/application/usecases/push/register_for_push_usecase.dart';
import 'package:flutterbase/application/usecases/push/unregister_from_push_usecase.dart';
import 'package:flutterbase/application/usecases/theme/get_theme_preference_usecase.dart';
import 'package:flutterbase/application/usecases/theme/set_theme_preference_usecase.dart';
import 'package:flutterbase/domain/repositories/app_info_repository.dart';
import 'package:flutterbase/domain/repositories/app_notice_repository.dart';
import 'package:flutterbase/domain/repositories/app_release_repository.dart';
import 'package:flutterbase/domain/repositories/bookmark_repository.dart';
import 'package:flutterbase/domain/repositories/debug_settings_repository.dart';
import 'package:flutterbase/domain/repositories/device_registration_repository.dart';
import 'package:flutterbase/domain/repositories/dismissed_update_repository.dart';
import 'package:flutterbase/domain/repositories/language_preference_repository.dart';
import 'package:flutterbase/domain/repositories/theme_preference_repository.dart';
import 'package:flutterbase/domain/value_objects/push_settings.dart';
import 'package:flutterbase/domain/value_objects/sign_in_settings.dart';
import 'package:flutterbase/infrastructure/infrastructure_module.dart';
import 'package:flutterbase/shared/app_config.dart';
import 'package:get_it/get_it.dart';

/// Composition root.
///
/// This is the only place allowed to see every layer at once: it binds Domain
/// interfaces to Infrastructure adapters and registers the use cases built on
/// top of them. `provider_overrides.dart` is what hands those objects to
/// Presentation. Nothing outside `lib/app/` may import this file —
/// `tool/check_architecture.dart` enforces that.
final GetIt sl = GetIt.instance;

/// Wires up all dependencies. Call once at app startup before `runApp`.
Future<void> setupServiceLocator() async {
  // ─── Infrastructure adapters ─────────────────────────────────────────
  // The module hands back Domain interfaces and Application ports only, so
  // no storage technology is named here.

  // The optional sign-in: on only when the build carries all three
  // `--dart-define`s (docs/adr/0007-optional-assay-sign-in.md).
  const signIn = SignInSettings(
    issuer: AppConfig.oidcIssuer,
    clientId: AppConfig.oidcClientId,
    linkHost: AppConfig.signInLinkHost,
  );
  sl.registerSingleton<SignInSettings>(signIn);

  // The optional notifications through FCM: on only when the build carries
  // all four `FIREBASE_*` `--dart-define`s *and* the sign-in
  // (docs/adr/0010-notifications-through-fcm.md).
  const push = PushSettings(
    apiKey: AppConfig.firebaseApiKey,
    appId: AppConfig.firebaseAppId,
    messagingSenderId: AppConfig.firebaseMessagingSenderId,
    projectId: AppConfig.firebaseProjectId,
  );

  final infrastructure = await InfrastructureModule.create(
    signIn: signIn,
    push: push,
  );

  sl
    ..registerSingleton<AppLogger>(infrastructure.appLogger)
    ..registerSingleton<DebugSettingsRepository>(infrastructure.debugSettings)
    ..registerSingleton<ThemePreferenceRepository>(
      infrastructure.themePreference,
    )
    ..registerSingleton<LanguagePreferenceRepository>(
      infrastructure.languagePreference,
    )
    ..registerSingleton<AppInfoRepository>(infrastructure.appInfo)
    ..registerSingleton<BookmarkRepository>(infrastructure.bookmarks)
    ..registerSingleton<ExternalLinkLauncher>(infrastructure.externalLinks);

  sl<AppLogger>().info(
    '[DI] Infrastructure ready '
    '(minLogLevel: ${infrastructure.appLogger.minLevel.name})',
  );

  // ─── Use cases ───────────────────────────────────────────────────────

  sl.registerFactory<GetThemePreferenceUseCase>(
    () => GetThemePreferenceUseCase(sl<ThemePreferenceRepository>()),
  );
  sl.registerFactory<SetThemePreferenceUseCase>(
    () => SetThemePreferenceUseCase(sl<ThemePreferenceRepository>()),
  );
  sl.registerFactory<GetLanguagePreferenceUseCase>(
    () => GetLanguagePreferenceUseCase(sl<LanguagePreferenceRepository>()),
  );
  sl.registerFactory<SetLanguagePreferenceUseCase>(
    () => SetLanguagePreferenceUseCase(sl<LanguagePreferenceRepository>()),
  );
  sl.registerFactory<GetAppInfoUseCase>(
    () => GetAppInfoUseCase(sl<AppInfoRepository>()),
  );
  sl.registerFactory<GetDebugSettingsUseCase>(
    () => GetDebugSettingsUseCase(sl<DebugSettingsRepository>()),
  );
  sl.registerFactory<SetDebugModeUseCase>(
    () => SetDebugModeUseCase(sl<DebugSettingsRepository>()),
  );
  sl.registerFactory<SetLogLevelUseCase>(
    () => SetLogLevelUseCase(sl<DebugSettingsRepository>(), sl<AppLogger>()),
  );
  sl.registerFactory<ListBookmarksUseCase>(
    () => ListBookmarksUseCase(sl<BookmarkRepository>()),
  );
  sl.registerFactory<GetBookmarkUseCase>(
    () => GetBookmarkUseCase(sl<BookmarkRepository>()),
  );
  sl.registerFactory<AddBookmarkUseCase>(
    () => AddBookmarkUseCase(sl<BookmarkRepository>(), sl<AppLogger>()),
  );
  sl.registerFactory<RemoveBookmarkUseCase>(
    () => RemoveBookmarkUseCase(sl<BookmarkRepository>(), sl<AppLogger>()),
  );
  sl.registerFactory<OpenBookmarkUseCase>(
    () => OpenBookmarkUseCase(sl<ExternalLinkLauncher>(), sl<AppLogger>()),
  );

  sl.registerSingleton<DismissedUpdateRepository>(
    infrastructure.dismissedUpdates,
  );

  final web = infrastructure.web;
  if (web != null) {
    sl
      ..registerSingleton<AuthSession>(web.authSession)
      ..registerSingleton<AppReleaseRepository>(web.appReleases)
      ..registerSingleton<AppNoticeRepository>(web.notices)
      // The update notice and the notices call the paired web app with the
      // signed-in person's token (docs/adr/0009-*).
      ..registerFactory<CheckForUpdateUseCase>(
        () => CheckForUpdateUseCase(
          sl<AppReleaseRepository>(),
          sl<AppInfoRepository>(),
          sl<DismissedUpdateRepository>(),
          sl<AppLogger>(),
        ),
      )
      ..registerFactory<DismissUpdateUseCase>(
        () => DismissUpdateUseCase(
          sl<DismissedUpdateRepository>(),
          sl<AppLogger>(),
        ),
      )
      ..registerFactory<OpenUpdateDownloadUseCase>(
        () => OpenUpdateDownloadUseCase(
          sl<ExternalLinkLauncher>(),
          sl<AppLogger>(),
        ),
      )
      ..registerFactory<ListNoticesUseCase>(
        () => ListNoticesUseCase(sl<AppNoticeRepository>(), sl<AppLogger>()),
      )
      ..registerFactory<MarkNoticeReadUseCase>(
        () => MarkNoticeReadUseCase(sl<AppNoticeRepository>(), sl<AppLogger>()),
      )
      ..registerFactory<MarkAllNoticesReadUseCase>(
        () => MarkAllNoticesReadUseCase(
          sl<AppNoticeRepository>(),
          sl<AppLogger>(),
        ),
      )
      ..registerFactory<DismissNoticeUseCase>(
        () => DismissNoticeUseCase(sl<AppNoticeRepository>(), sl<AppLogger>()),
      )
      ..registerFactory<OpenNoticeLinkUseCase>(
        () => OpenNoticeLinkUseCase(
          sl<ExternalLinkLauncher>(),
          signIn.webBaseUrl,
          sl<AppLogger>(),
        ),
      )
      ..registerFactory<GetCurrentAccountUseCase>(
        () => GetCurrentAccountUseCase(sl<AuthSession>()),
      )
      ..registerFactory<SignInUseCase>(
        () => SignInUseCase(sl<AuthSession>(), sl<AppLogger>()),
      )
      ..registerFactory<SignOutUseCase>(
        () => SignOutUseCase(sl<AuthSession>(), sl<AppLogger>()),
      );

    final pushMessaging = web.pushMessaging;
    if (pushMessaging != null) {
      sl
        ..registerSingleton<PushMessaging>(pushMessaging)
        ..registerSingleton<DeviceRegistrationRepository>(
          web.deviceRegistrations,
        )
        ..registerFactory<RegisterForPushUseCase>(
          () => RegisterForPushUseCase(
            sl<PushMessaging>(),
            sl<DeviceRegistrationRepository>(),
            sl<AppLogger>(),
          ),
        )
        ..registerFactory<UnregisterFromPushUseCase>(
          () => UnregisterFromPushUseCase(
            sl<PushMessaging>(),
            sl<DeviceRegistrationRepository>(),
            sl<AppLogger>(),
          ),
        )
        ..registerFactory<OpenPushTapUseCase>(
          () => OpenPushTapUseCase(
            sl<AppNoticeRepository>(),
            sl<ExternalLinkLauncher>(),
            signIn.webBaseUrl,
            sl<AppLogger>(),
          ),
        );
    }
  }
  sl<AppLogger>().info(
    '[DI] Notifications through FCM '
    '${sl.isRegistered<PushMessaging>() ? 'on' : 'off'}',
  );
  sl<AppLogger>().info(
    '[DI] Sign-in ${signIn.isEnabled ? 'on (${signIn.issuer})' : 'off'}',
  );

  sl<AppLogger>().info('[DI] Service locator setup complete');
}
