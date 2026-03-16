import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../bootstrap/app_router.dart';
import '../../shared/theme/app_theme.dart';

/// Root application widget.
///
/// Responsible for:
/// - Wiring [GoRouter] for navigation
/// - Providing light / dark [ThemeData] from [AppTheme]
/// - Responding to system-level theme changes
class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Flutterbase',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
