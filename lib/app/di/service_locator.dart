import 'package:get_it/get_it.dart';
import 'package:flutterbase/presentation/viewmodels/main_viewmodel.dart';

final GetIt sl = GetIt.instance;

/// 依存性注入の初期化
Future<void> setupServiceLocator() async {
  // ─── ViewModels ──────────────────────────────────────────────────
  sl.registerFactory<MainViewModel>(() => MainViewModel());

  // ─── Infrastructure (DB, Repositories) ──────────────────────────
  // TODO: 機能追加時にここに追加する
  // sl.registerSingleton<AppDatabase>(AppDatabase());
  // sl.registerFactory<SomeRepository>(() => SqliteSomeRepository(sl<AppDatabase>()));

  // ─── Application (UseCases) ─────────────────────────────────────
  // TODO: 機能追加時にここに追加する
  // sl.registerFactory<SomeUseCase>(() => SomeUseCase(sl<SomeRepository>()));
}
