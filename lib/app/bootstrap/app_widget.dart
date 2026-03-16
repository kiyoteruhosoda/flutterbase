import 'package:flutter/material.dart';
import 'package:flutterbase/app/bootstrap/app_router.dart';
import 'package:flutterbase/presentation/pages/main_page.dart';
import 'package:flutterbase/presentation/pages/splash_page.dart';
import 'package:flutterbase/shared/theme/app_theme.dart';

/// アプリのルートウィジェット
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
    return MaterialApp(
      title: 'FlutterBase',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      onGenerateRoute: AppRouter.onGenerateRoute,
      home: _showSplash
          ? SplashPage(onComplete: _onSplashComplete)
          : const MainPage(),
    );
  }
}
