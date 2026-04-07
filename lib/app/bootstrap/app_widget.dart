import 'package:flutter/material.dart';
import 'package:flutterbase/app/bootstrap/app_router.dart';
import 'package:flutterbase/app/di/service_locator.dart';
import 'package:flutterbase/presentation/pages/main_page.dart';
import 'package:flutterbase/presentation/pages/splash_page.dart';
import 'package:flutterbase/presentation/viewmodels/theme_viewmodel.dart';
import 'package:flutterbase/shared/l10n/app_strings.dart';
import 'package:flutterbase/shared/theme/app_theme.dart';

/// Root widget. Listens to [ThemeViewModel] for live theme switching.
class AppWidget extends StatefulWidget {
  const AppWidget({super.key});

  @override
  State<AppWidget> createState() => _AppWidgetState();
}

class _AppWidgetState extends State<AppWidget> {
  bool _showSplash = true;

  void _onSplashComplete() {
    setState(() => _showSplash = false);
  }

  @override
  Widget build(BuildContext context) {
    final themeViewModel = sl<ThemeViewModel>();
    return ListenableBuilder(
      listenable: themeViewModel,
      builder: (context, _) {
        return MaterialApp(
          title: AppStrings.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeViewModel.themeMode,
          onGenerateRoute: AppRouter.onGenerateRoute,
          home: _showSplash
              ? SplashPage(onComplete: _onSplashComplete)
              : const MainPage(),
        );
      },
    );
  }
}
