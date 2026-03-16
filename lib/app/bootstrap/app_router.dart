import 'package:flutter/material.dart';
import 'package:flutterbase/presentation/pages/main_page.dart';
import 'package:flutterbase/presentation/pages/splash_page.dart';
import 'package:flutterbase/presentation/pages/system/about_page.dart';
import 'package:flutterbase/presentation/pages/system/debug_page.dart';
import 'package:flutterbase/presentation/pages/system/licenses_page.dart';

/// アプリルーティング
class AppRouter {
  AppRouter._();

  static const String splash = '/';
  static const String main = '/main';
  static const String about = '/about';
  static const String licenses = '/licenses';
  static const String debug = '/debug';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    return switch (settings.name) {
      splash => MaterialPageRoute<void>(
          builder: (_) => const SplashPage(),
          settings: settings,
        ),
      main => MaterialPageRoute<void>(
          builder: (_) => const MainPage(),
          settings: settings,
        ),
      about => MaterialPageRoute<void>(
          builder: (_) => const AboutPage(),
          settings: settings,
        ),
      licenses => MaterialPageRoute<void>(
          builder: (_) => const LicensesPage(),
          settings: settings,
        ),
      debug => MaterialPageRoute<void>(
          builder: (_) => const DebugPage(),
          settings: settings,
        ),
      _ => MaterialPageRoute<void>(
          builder: (_) => const _NotFoundPage(),
          settings: settings,
        ),
    };
  }
}

class _NotFoundPage extends StatelessWidget {
  const _NotFoundPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ページが見つかりません')),
      body: const Center(
        child: Text('404 - ページが見つかりません'),
      ),
    );
  }
}
