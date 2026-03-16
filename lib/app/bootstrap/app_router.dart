import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/pages/splash/splash_page.dart';
import '../../presentation/pages/main/main_page.dart';
import '../../presentation/pages/system/version_info_page.dart';
import '../../presentation/pages/system/licenses_page.dart';
import '../../presentation/pages/system/debug_info_page.dart';

/// Route name constants
abstract final class AppRoutes {
  static const String splash = '/';
  static const String main = '/main';
  static const String versionInfo = '/system/version';
  static const String licenses = '/system/licenses';
  static const String debugInfo = '/system/debug';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: SplashPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.main,
        name: 'main',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: MainPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.versionInfo,
        name: 'versionInfo',
        builder: (context, state) => const VersionInfoPage(),
      ),
      GoRoute(
        path: AppRoutes.licenses,
        name: 'licenses',
        builder: (context, state) => const LicensesPage(),
      ),
      GoRoute(
        path: AppRoutes.debugInfo,
        name: 'debugInfo',
        builder: (context, state) => const DebugInfoPage(),
      ),
    ],
  );
});
