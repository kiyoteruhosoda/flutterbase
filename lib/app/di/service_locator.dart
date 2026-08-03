import 'package:flutterbase/application/ports/app_logger.dart';
import 'package:flutterbase/application/usecases/app_info/get_app_info_usecase.dart';
import 'package:flutterbase/application/usecases/debug/get_debug_settings_usecase.dart';
import 'package:flutterbase/application/usecases/debug/set_debug_mode_usecase.dart';
import 'package:flutterbase/application/usecases/debug/set_log_level_usecase.dart';
import 'package:flutterbase/application/usecases/language/get_language_preference_usecase.dart';
import 'package:flutterbase/application/usecases/language/set_language_preference_usecase.dart';
import 'package:flutterbase/application/usecases/theme/get_theme_preference_usecase.dart';
import 'package:flutterbase/application/usecases/theme/set_theme_preference_usecase.dart';
import 'package:flutterbase/domain/repositories/app_info_repository.dart';
import 'package:flutterbase/domain/repositories/debug_settings_repository.dart';
import 'package:flutterbase/domain/repositories/language_preference_repository.dart';
import 'package:flutterbase/domain/repositories/theme_preference_repository.dart';
import 'package:flutterbase/infrastructure/logging/persistent_app_logger.dart';
import 'package:flutterbase/infrastructure/repositories/package_info_app_info_repository.dart';
import 'package:flutterbase/infrastructure/repositories/shared_preferences_debug_settings_repository.dart';
import 'package:flutterbase/infrastructure/repositories/shared_preferences_language_preference_repository.dart';
import 'package:flutterbase/infrastructure/repositories/shared_preferences_theme_preference_repository.dart';
import 'package:flutterbase/presentation/viewmodels/about_viewmodel.dart';
import 'package:flutterbase/presentation/viewmodels/debug_settings_viewmodel.dart';
import 'package:flutterbase/presentation/viewmodels/debug_viewmodel.dart';
import 'package:flutterbase/presentation/viewmodels/language_viewmodel.dart';
import 'package:flutterbase/presentation/viewmodels/theme_viewmodel.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Composition root.
///
/// This is the only place allowed to see every layer at once: it binds Domain
/// interfaces to Infrastructure adapters and hands the wired objects down to
/// Presentation through `AppScope`. Nothing outside `lib/app/` may import
/// this file — `tool/check_architecture.dart` enforces that.
final GetIt sl = GetIt.instance;

/// Wires up all dependencies. Call once at app startup before `runApp`.
Future<void> setupServiceLocator() async {
  // ─── Infrastructure singletons ───────────────────────────────────────

  final prefs = await SharedPreferences.getInstance();
  sl.registerSingleton<SharedPreferences>(prefs);

  // ─── Debug settings repository (needed before logger init) ──────────
  final debugSettingsRepo = SharedPreferencesDebugSettingsRepository(prefs);
  sl.registerSingleton<DebugSettingsRepository>(debugSettingsRepo);

  // Logging — restore saved level so filtering is correct from first log
  final logger = PersistentAppLogger();
  await logger.init(savedLevel: debugSettingsRepo.getMinLogLevel());
  sl.registerSingleton<AppLogger>(logger);
  logger.info('[DI] Logger ready (minLevel: ${logger.minLevel.name})');

  // ─── Repository bindings ─────────────────────────────────────────────

  sl.registerSingleton<ThemePreferenceRepository>(
    SharedPreferencesThemePreferenceRepository(prefs),
  );

  sl.registerSingleton<LanguagePreferenceRepository>(
    SharedPreferencesLanguagePreferenceRepository(prefs),
  );

  sl.registerSingleton<AppInfoRepository>(const PackageInfoAppInfoRepository());

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

  // ─── ViewModels ──────────────────────────────────────────────────────

  sl.registerSingleton<ThemeViewModel>(
    ThemeViewModel(
      sl<GetThemePreferenceUseCase>(),
      sl<SetThemePreferenceUseCase>(),
      sl<AppLogger>(),
    ),
  );
  sl.registerSingleton<LanguageViewModel>(
    LanguageViewModel(
      sl<GetLanguagePreferenceUseCase>(),
      sl<SetLanguagePreferenceUseCase>(),
      sl<AppLogger>(),
    ),
  );
  sl.registerSingleton<DebugSettingsViewModel>(
    DebugSettingsViewModel(
      sl<GetDebugSettingsUseCase>(),
      sl<SetDebugModeUseCase>(),
      sl<SetLogLevelUseCase>(),
      sl<AppLogger>(),
    ),
  );
  sl.registerFactory<AboutViewModel>(
    () => AboutViewModel(sl<GetAppInfoUseCase>(), sl<AppLogger>()),
  );
  sl.registerFactory<DebugViewModel>(
    () => DebugViewModel(sl<GetAppInfoUseCase>(), sl<AppLogger>()),
  );

  sl<AppLogger>().info('[DI] Service locator setup complete');
}
