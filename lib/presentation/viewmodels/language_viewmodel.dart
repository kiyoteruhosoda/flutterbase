import 'package:flutter/material.dart';
import 'package:flutterbase/app/di/service_locator.dart';
import 'package:flutterbase/application/usecases/language/get_language_preference_usecase.dart';
import 'package:flutterbase/application/usecases/language/set_language_preference_usecase.dart';
import 'package:flutterbase/shared/logging/app_logger.dart';
import 'package:flutterbase/shared/value_objects/app_language.dart';

/// Manages the app-wide language preference and resolves it to a Flutter
/// [Locale]. [AppLanguage.system] yields `null`, which instructs
/// [MaterialApp] to follow the device system locale.
class LanguageViewModel extends ChangeNotifier {
  LanguageViewModel(
    this._getLanguagePreference,
    this._setLanguagePreference,
  ) {
    _language = _getLanguagePreference.execute();
    sl<AppLogger>()
        .debug('[LanguageViewModel] init — language: ${_language.name}');
  }

  final GetLanguagePreferenceUseCase _getLanguagePreference;
  final SetLanguagePreferenceUseCase _setLanguagePreference;

  late AppLanguage _language;

  AppLanguage get language => _language;

  /// Returns the [Locale] to pass to [MaterialApp.locale], or `null` when
  /// the user wants to follow the OS language.
  Locale? get locale => switch (_language) {
        AppLanguage.english => const Locale('en'),
        AppLanguage.japanese => const Locale('ja'),
        AppLanguage.system => null,
      };

  Future<void> setLanguage(AppLanguage language) async {
    if (_language == language) return;
    sl<AppLogger>().debug('[LanguageViewModel] setLanguage: ${language.name}');
    _language = language;
    await _setLanguagePreference.execute(language);
    notifyListeners();
  }
}
