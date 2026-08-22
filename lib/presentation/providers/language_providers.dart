import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutterbase/application/usecases/language/get_language_preference_usecase.dart';
import 'package:flutterbase/application/usecases/language/set_language_preference_usecase.dart';
import 'package:flutterbase/domain/value_objects/app_language.dart';
import 'package:flutterbase/presentation/providers/app_providers.dart';

// ─── Use-case seams ────────────────────────────────────────────────────────

final Provider<GetLanguagePreferenceUseCase>
getLanguagePreferenceUseCaseProvider = Provider<GetLanguagePreferenceUseCase>((
  ref,
) {
  throw UnimplementedError(
    missingOverrideMessage('getLanguagePreferenceUseCaseProvider'),
  );
});

final Provider<SetLanguagePreferenceUseCase>
setLanguagePreferenceUseCaseProvider = Provider<SetLanguagePreferenceUseCase>((
  ref,
) {
  throw UnimplementedError(
    missingOverrideMessage('setLanguagePreferenceUseCaseProvider'),
  );
});

// ─── App-wide state ────────────────────────────────────────────────────────

/// The language the user picked, as a domain value.
///
/// The Settings tab watches this one; `MaterialApp` wants a [Locale], which
/// [appLocaleProvider] derives.
final NotifierProvider<AppLanguageNotifier, AppLanguage> appLanguageProvider =
    NotifierProvider<AppLanguageNotifier, AppLanguage>(AppLanguageNotifier.new);

/// Loads the stored language preference and writes changes back to it.
class AppLanguageNotifier extends Notifier<AppLanguage> {
  @override
  AppLanguage build() {
    final language = ref.read(getLanguagePreferenceUseCaseProvider).execute();
    ref
        .read(appLoggerProvider)
        .debug('[Language] init — language: ${language.name}');
    return language;
  }

  /// Persists [language], then adopts it.
  ///
  /// As with the theme, state moves only after the write lands, so a failed
  /// write cannot leave the UI showing a language nobody saved.
  Future<void> setLanguage(AppLanguage language) async {
    if (state == language) return;
    ref
        .read(appLoggerProvider)
        .debug('[Language] setLanguage: ${language.name}');
    await ref.read(setLanguagePreferenceUseCaseProvider).execute(language);
    state = language;
  }
}

/// The [Locale] to hand [MaterialApp].
///
/// [AppLanguage.system] yields null, which is how `MaterialApp` is told to
/// follow the device language.
final Provider<Locale?> appLocaleProvider = Provider<Locale?>((ref) {
  return switch (ref.watch(appLanguageProvider)) {
    AppLanguage.english => const Locale('en'),
    AppLanguage.japanese => const Locale('ja'),
    AppLanguage.system => null,
  };
});
