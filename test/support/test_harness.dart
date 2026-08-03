import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutterbase/application/usecases/app_info/get_app_info_usecase.dart';
import 'package:flutterbase/application/usecases/debug/get_debug_settings_usecase.dart';
import 'package:flutterbase/application/usecases/debug/set_debug_mode_usecase.dart';
import 'package:flutterbase/application/usecases/debug/set_log_level_usecase.dart';
import 'package:flutterbase/application/usecases/language/get_language_preference_usecase.dart';
import 'package:flutterbase/application/usecases/language/set_language_preference_usecase.dart';
import 'package:flutterbase/application/usecases/theme/get_theme_preference_usecase.dart';
import 'package:flutterbase/application/usecases/theme/set_theme_preference_usecase.dart';
import 'package:flutterbase/presentation/app_scope.dart';
import 'package:flutterbase/presentation/l10n/app_localizations.dart';
import 'package:flutterbase/presentation/theme/app_theme.dart';
import 'package:flutterbase/presentation/viewmodels/about_viewmodel.dart';
import 'package:flutterbase/presentation/viewmodels/debug_settings_viewmodel.dart';
import 'package:flutterbase/presentation/viewmodels/debug_viewmodel.dart';
import 'package:flutterbase/presentation/viewmodels/language_viewmodel.dart';
import 'package:flutterbase/presentation/viewmodels/theme_viewmodel.dart';

import 'fakes.dart';
import 'recording_app_logger.dart';

/// A fully wired Presentation dependency set, built from in-memory fakes.
///
/// Mirrors what `app/di/service_locator.dart` assembles at runtime, so a
/// widget test exercises the same ViewModel wiring the app ships — without
/// any platform channel.
class TestScope {
  TestScope({
    FakeThemePreferenceRepository? themeRepository,
    FakeLanguagePreferenceRepository? languageRepository,
    FakeDebugSettingsRepository? debugSettingsRepository,
    FakeAppInfoRepository? appInfoRepository,
    RecordingAppLogger? logger,
  }) : themeRepository = themeRepository ?? FakeThemePreferenceRepository(),
       languageRepository =
           languageRepository ?? FakeLanguagePreferenceRepository(),
       debugSettingsRepository =
           debugSettingsRepository ?? FakeDebugSettingsRepository(),
       appInfoRepository = appInfoRepository ?? FakeAppInfoRepository(),
       logger = logger ?? RecordingAppLogger() {
    themeViewModel = ThemeViewModel(
      GetThemePreferenceUseCase(this.themeRepository),
      SetThemePreferenceUseCase(this.themeRepository),
      this.logger,
    );
    languageViewModel = LanguageViewModel(
      GetLanguagePreferenceUseCase(this.languageRepository),
      SetLanguagePreferenceUseCase(this.languageRepository),
      this.logger,
    );
    debugSettingsViewModel = DebugSettingsViewModel(
      GetDebugSettingsUseCase(this.debugSettingsRepository),
      SetDebugModeUseCase(this.debugSettingsRepository),
      SetLogLevelUseCase(this.debugSettingsRepository, this.logger),
      this.logger,
    );
  }

  final FakeThemePreferenceRepository themeRepository;
  final FakeLanguagePreferenceRepository languageRepository;
  final FakeDebugSettingsRepository debugSettingsRepository;
  final FakeAppInfoRepository appInfoRepository;
  final RecordingAppLogger logger;

  late final ThemeViewModel themeViewModel;
  late final LanguageViewModel languageViewModel;
  late final DebugSettingsViewModel debugSettingsViewModel;

  /// Number of times a per-screen ViewModel has been requested.
  int aboutViewModelsCreated = 0;
  int debugViewModelsCreated = 0;

  AboutViewModel createAboutViewModel() {
    aboutViewModelsCreated++;
    return AboutViewModel(GetAppInfoUseCase(appInfoRepository), logger);
  }

  DebugViewModel createDebugViewModel() {
    debugViewModelsCreated++;
    return DebugViewModel(GetAppInfoUseCase(appInfoRepository), logger);
  }

  /// Wraps [child] in the same scope, theme, and localisations the real app
  /// installs, so a widget under test sees production conditions.
  Widget wrap(
    Widget child, {
    Locale? locale,
    List<NavigatorObserver>? observers,
  }) {
    return AppScope(
      logger: logger,
      themeViewModel: themeViewModel,
      languageViewModel: languageViewModel,
      debugSettingsViewModel: debugSettingsViewModel,
      createAboutViewModel: createAboutViewModel,
      createDebugViewModel: createDebugViewModel,
      child: MaterialApp(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeViewModel.themeMode,
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        navigatorObservers: observers ?? const <NavigatorObserver>[],
        // Named routes resolve to a labelled placeholder: tests assert that
        // navigation happened, not what the destination screen looks like.
        onGenerateRoute: (settings) => MaterialPageRoute<void>(
          settings: settings,
          builder: (_) =>
              Scaffold(body: Center(child: Text('route:${settings.name}'))),
        ),
        home: child,
      ),
    );
  }
}

/// A viewport tall enough that a full screen fits without scrolling.
///
/// The default 800x600 test surface hides most of every page behind a scroll,
/// which turns "does this row exist" assertions into scroll choreography.
const Size tallSurface = Size(1000, 2400);

/// Pumps [child] inside a [TestScope] and settles the frame.
Future<TestScope> pumpInScope(
  WidgetTester tester,
  Widget child, {
  TestScope? scope,
  Locale? locale,
  List<NavigatorObserver>? observers,
  Size surfaceSize = tallSurface,
}) async {
  tester.view
    ..physicalSize = surfaceSize
    ..devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final resolved = scope ?? TestScope();
  await tester.pumpWidget(
    resolved.wrap(child, locale: locale, observers: observers),
  );
  await tester.pumpAndSettle();
  return resolved;
}

/// Pumps a bare widget with theme and localisations but no [AppScope].
///
/// For leaf UI components that must not reach for app state.
///
/// Pass `settle: false` when the widget runs a continuous animation (a
/// progress spinner, for example) — `pumpAndSettle` never returns for those.
Future<void> pumpComponent(
  WidgetTester tester,
  Widget child, {
  ThemeData? theme,
  Locale? locale,
  bool settle = true,
  bool wrapInScaffold = true,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: theme ?? AppTheme.light,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: wrapInScaffold ? Scaffold(body: child) : child,
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

/// Records the routes a test pushes, so navigation can be asserted without a
/// real destination screen.
class RouteRecorder extends NavigatorObserver {
  final List<String?> pushed = <String?>[];
  final List<String?> popped = <String?>[];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushed.add(route.settings.name);
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    popped.add(route.settings.name);
    super.didPop(route, previousRoute);
  }
}
