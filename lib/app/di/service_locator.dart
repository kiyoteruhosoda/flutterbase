import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutterbase/presentation/viewmodels/main_viewmodel.dart';
import 'package:flutterbase/presentation/viewmodels/theme_viewmodel.dart';
import 'package:flutterbase/shared/logging/app_logger.dart';

final GetIt sl = GetIt.instance;

/// Initialises all dependencies at app startup.
Future<void> setupServiceLocator() async {
  // ─── Infrastructure singletons ───────────────────────────────────────
  final prefs = await SharedPreferences.getInstance();
  sl.registerSingleton<SharedPreferences>(prefs);

  // ─── Logging ─────────────────────────────────────────────────────────
  await AppLogger.instance.init();

  // ─── ViewModels ──────────────────────────────────────────────────────
  sl.registerSingleton<ThemeViewModel>(ThemeViewModel(prefs));
  sl.registerFactory<MainViewModel>(() => MainViewModel());

  // ─── Infrastructure (DB, Repositories) ──────────────────────────────
  // TODO: add when features are implemented
  // sl.registerSingleton<AppDatabase>(AppDatabase());
  // sl.registerFactory<SomeRepository>(() => SqliteSomeRepository(sl<AppDatabase>()));

  // ─── Application (UseCases) ─────────────────────────────────────────
  // TODO: add when features are implemented
  // sl.registerFactory<SomeUseCase>(() => SomeUseCase(sl<SomeRepository>()));
}
