import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutterbase/application/usecases/app_info/get_app_info_usecase.dart';
import 'package:flutterbase/application/usecases/theme/get_theme_preference_usecase.dart';
import 'package:flutterbase/application/usecases/theme/set_theme_preference_usecase.dart';
import 'package:flutterbase/domain/repositories/app_info_repository.dart';
import 'package:flutterbase/domain/repositories/theme_preference_repository.dart';
import 'package:flutterbase/infrastructure/logging/persistent_app_logger.dart';
import 'package:flutterbase/infrastructure/repositories/package_info_app_info_repository.dart';
import 'package:flutterbase/infrastructure/repositories/shared_preferences_theme_preference_repository.dart';
import 'package:flutterbase/presentation/viewmodels/about_viewmodel.dart';
import 'package:flutterbase/presentation/viewmodels/debug_viewmodel.dart';
import 'package:flutterbase/presentation/viewmodels/main_viewmodel.dart';
import 'package:flutterbase/presentation/viewmodels/theme_viewmodel.dart';
import 'package:flutterbase/shared/logging/app_logger.dart';

final GetIt sl = GetIt.instance;

/// Wires up all dependencies. Call once at app startup before [runApp].
Future<void> setupServiceLocator() async {
  // ─── Infrastructure singletons ───────────────────────────────────────

  final prefs = await SharedPreferences.getInstance();
  sl.registerSingleton<SharedPreferences>(prefs);

  // Logging — register interface bound to the concrete implementation
  final logger = PersistentAppLogger();
  await logger.init();
  sl.registerSingleton<AppLogger>(logger);

  // ─── Repository bindings ─────────────────────────────────────────────

  sl.registerSingleton<ThemePreferenceRepository>(
    SharedPreferencesThemePreferenceRepository(prefs),
  );

  sl.registerSingleton<AppInfoRepository>(
    const PackageInfoAppInfoRepository(),
  );

  // ─── Use cases ───────────────────────────────────────────────────────

  sl.registerFactory<GetThemePreferenceUseCase>(
    () => GetThemePreferenceUseCase(sl<ThemePreferenceRepository>()),
  );
  sl.registerFactory<SetThemePreferenceUseCase>(
    () => SetThemePreferenceUseCase(sl<ThemePreferenceRepository>()),
  );
  sl.registerFactory<GetAppInfoUseCase>(
    () => GetAppInfoUseCase(sl<AppInfoRepository>()),
  );

  // ─── ViewModels ──────────────────────────────────────────────────────

  sl.registerSingleton<ThemeViewModel>(
    ThemeViewModel(
      sl<GetThemePreferenceUseCase>(),
      sl<SetThemePreferenceUseCase>(),
    ),
  );
  sl.registerFactory<MainViewModel>(() => MainViewModel());
  sl.registerFactory<AboutViewModel>(
    () => AboutViewModel(sl<GetAppInfoUseCase>()),
  );
  sl.registerFactory<DebugViewModel>(
    () => DebugViewModel(sl<GetAppInfoUseCase>(), sl<AppLogger>()),
  );

  // ─── Infrastructure (DB, Repositories) ──────────────────────────────
  // TODO: add when features are implemented
  // sl.registerSingleton<AppDatabase>(AppDatabase());

  // ─── Application (UseCases) ─────────────────────────────────────────
  // TODO: add when features are implemented
}
