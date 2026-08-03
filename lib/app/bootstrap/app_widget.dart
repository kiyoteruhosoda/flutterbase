import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutterbase/app/bootstrap/app_router.dart';
import 'package:flutterbase/app/di/service_locator.dart';
import 'package:flutterbase/application/ports/app_logger.dart';
import 'package:flutterbase/presentation/app_scope.dart';
import 'package:flutterbase/presentation/l10n/app_localizations.dart';
import 'package:flutterbase/presentation/pages/main_page.dart';
import 'package:flutterbase/presentation/theme/app_theme.dart';
import 'package:flutterbase/presentation/viewmodels/about_viewmodel.dart';
import 'package:flutterbase/presentation/viewmodels/debug_settings_viewmodel.dart';
import 'package:flutterbase/presentation/viewmodels/debug_viewmodel.dart';
import 'package:flutterbase/presentation/viewmodels/language_viewmodel.dart';
import 'package:flutterbase/presentation/viewmodels/theme_viewmodel.dart';

/// Root widget.
///
/// Resolves the wired objects from the service locator once and publishes
/// them to the widget tree via [AppScope], so no Presentation file has to
/// import the composition root itself.
class AppWidget extends StatefulWidget {
  const AppWidget({super.key});

  @override
  State<AppWidget> createState() => _AppWidgetState();
}

class _AppWidgetState extends State<AppWidget> with WidgetsBindingObserver {
  late final AppLogger _logger;
  late final ThemeViewModel _themeViewModel;
  late final LanguageViewModel _languageViewModel;
  late final DebugSettingsViewModel _debugSettingsViewModel;

  @override
  void initState() {
    super.initState();
    _logger = sl<AppLogger>();
    _themeViewModel = sl<ThemeViewModel>();
    _languageViewModel = sl<LanguageViewModel>();
    _debugSettingsViewModel = sl<DebugSettingsViewModel>();
    WidgetsBinding.instance.addObserver(this);
    _logger.info('[App] AppWidget initialised');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _logger.debug('[App] Lifecycle → ${state.name}');
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      logger: _logger,
      themeViewModel: _themeViewModel,
      languageViewModel: _languageViewModel,
      debugSettingsViewModel: _debugSettingsViewModel,
      createAboutViewModel: sl.call<AboutViewModel>,
      createDebugViewModel: sl.call<DebugViewModel>,
      child: ListenableBuilder(
        listenable: Listenable.merge([_themeViewModel, _languageViewModel]),
        builder: (context, _) {
          return MaterialApp(
            onGenerateTitle: (context) => AppLocalizations.of(context).appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: _themeViewModel.themeMode,
            locale: _languageViewModel.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            onGenerateRoute: AppRouter.onGenerateRoute,
            home: const MainPage(),
          );
        },
      ),
    );
  }
}
