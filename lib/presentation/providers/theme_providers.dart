import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutterbase/application/usecases/theme/get_theme_preference_usecase.dart';
import 'package:flutterbase/application/usecases/theme/set_theme_preference_usecase.dart';
import 'package:flutterbase/domain/value_objects/app_theme_mode.dart';
import 'package:flutterbase/presentation/providers/app_providers.dart';

// ─── Use-case seams ────────────────────────────────────────────────────────

final Provider<GetThemePreferenceUseCase> getThemePreferenceUseCaseProvider =
    Provider<GetThemePreferenceUseCase>((ref) {
      throw UnimplementedError(
        missingOverrideMessage('getThemePreferenceUseCaseProvider'),
      );
    });

final Provider<SetThemePreferenceUseCase> setThemePreferenceUseCaseProvider =
    Provider<SetThemePreferenceUseCase>((ref) {
      throw UnimplementedError(
        missingOverrideMessage('setThemePreferenceUseCaseProvider'),
      );
    });

// ─── App-wide state ────────────────────────────────────────────────────────

/// The [ThemeMode] the whole app renders with.
///
/// Read by `AppWidget` for `MaterialApp.themeMode` and by the Settings tab
/// for the selected radio row, so both see one value rather than two copies
/// of the same preference.
final NotifierProvider<ThemeModeNotifier, ThemeMode> themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

/// Loads the stored theme preference and writes changes back to it.
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final mode = _toFlutterMode(
      ref.read(getThemePreferenceUseCaseProvider).execute(),
    );
    ref.read(appLoggerProvider).debug('[Theme] init — themeMode: ${mode.name}');
    return mode;
  }

  /// Persists [mode], then adopts it.
  ///
  /// State moves only after the write lands: storage is the source of truth,
  /// so a failed write must not leave the app rendering a theme nobody saved.
  Future<void> setThemeMode(ThemeMode mode) async {
    if (state == mode) return;
    ref.read(appLoggerProvider).debug('[Theme] setThemeMode: ${mode.name}');
    await ref.read(setThemePreferenceUseCaseProvider).execute(_toAppMode(mode));
    state = mode;
  }
}

// ── Mapping helpers ────────────────────────────────────────────────────────

ThemeMode _toFlutterMode(AppThemeMode mode) => switch (mode) {
  AppThemeMode.light => ThemeMode.light,
  AppThemeMode.dark => ThemeMode.dark,
  AppThemeMode.system => ThemeMode.system,
};

AppThemeMode _toAppMode(ThemeMode mode) => switch (mode) {
  ThemeMode.light => AppThemeMode.light,
  ThemeMode.dark => AppThemeMode.dark,
  ThemeMode.system => AppThemeMode.system,
};
