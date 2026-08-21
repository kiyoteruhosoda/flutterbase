import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutterbase/app/bootstrap/app_router.dart';
import 'package:flutterbase/application/ports/app_logger.dart';
import 'package:flutterbase/presentation/l10n/app_localizations.dart';
import 'package:flutterbase/presentation/providers/app_providers.dart';
import 'package:flutterbase/presentation/providers/language_providers.dart';
import 'package:flutterbase/presentation/providers/theme_providers.dart';
import 'package:flutterbase/presentation/theme/app_theme.dart';
import 'package:go_router/go_router.dart';

/// Root widget.
///
/// Reads everything it needs from Riverpod: `main.dart` installs the
/// [ProviderScope] whose overrides carry the wired objects, so no Presentation
/// file has to import the composition root itself.
///
/// Uses `MaterialApp.router`: the Router API is what lets the platform push a
/// location into a running app, which is what makes an incoming App Link an
/// ordinary navigation instead of a special case.
class AppWidget extends ConsumerStatefulWidget {
  const AppWidget({super.key});

  @override
  ConsumerState<AppWidget> createState() => _AppWidgetState();
}

class _AppWidgetState extends ConsumerState<AppWidget>
    with WidgetsBindingObserver {
  late final AppLogger _logger;

  /// Built once: a router recreated on every rebuild would drop the
  /// navigation stack, including the screen a deep link just opened.
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _logger = ref.read(appLoggerProvider);
    _router = AppRouter.create(logger: _logger);
    WidgetsBinding.instance.addObserver(this);
    _logger.info('[App] AppWidget initialised');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _router.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _logger.debug('[App] Lifecycle → ${state.name}');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ref.watch(themeModeProvider),
      locale: ref.watch(appLocaleProvider),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: _router,
    );
  }
}
