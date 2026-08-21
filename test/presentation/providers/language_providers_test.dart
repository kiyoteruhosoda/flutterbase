import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutterbase/domain/value_objects/app_language.dart';
import 'package:flutterbase/domain/value_objects/log_level.dart';
import 'package:flutterbase/presentation/providers/language_providers.dart';

import '../../support/fakes.dart';
import '../../support/recording_app_logger.dart';
import '../../support/test_harness.dart';

void main() {
  group('AppLanguageNotifier', () {
    test('reads the stored language on first build', () {
      final scope = TestScope(
        languageRepository: FakeLanguagePreferenceRepository(
          AppLanguage.japanese,
        ),
      );
      expect(scope.container.read(appLanguageProvider), AppLanguage.japanese);
    });

    test('logs its initial state', () {
      final logger = RecordingAppLogger();
      TestScope(logger: logger);
      expect(logger.messagesAt(LogLevel.debug).join(), contains('[Language]'));
    });

    test('setLanguage persists the choice and updates the state', () async {
      final scope = TestScope();

      await scope.container
          .read(appLanguageProvider.notifier)
          .setLanguage(AppLanguage.japanese);

      expect(scope.languageRepository.saved, equals([AppLanguage.japanese]));
      expect(scope.container.read(appLanguageProvider), AppLanguage.japanese);
    });

    test('setLanguage to the current value is a no-op', () async {
      final scope = TestScope(
        languageRepository: FakeLanguagePreferenceRepository(
          AppLanguage.english,
        ),
      );

      await scope.container
          .read(appLanguageProvider.notifier)
          .setLanguage(AppLanguage.english);

      expect(scope.languageRepository.saved, isEmpty);
    });

    test('a failed write leaves the stored language in place', () async {
      final repository = FakeLanguagePreferenceRepository()..failOnSave = true;
      final scope = TestScope(languageRepository: repository);

      await expectLater(
        scope.container
            .read(appLanguageProvider.notifier)
            .setLanguage(AppLanguage.japanese),
        throwsA(isA<Exception>()),
      );

      expect(scope.container.read(appLanguageProvider), AppLanguage.system);
    });
  });

  group('appLocaleProvider', () {
    test('maps each language to the locale MaterialApp expects', () {
      for (final (language, expected) in <(AppLanguage, Locale?)>[
        (AppLanguage.english, const Locale('en')),
        (AppLanguage.japanese, const Locale('ja')),
        // System yields null, which tells MaterialApp to follow the device.
        (AppLanguage.system, null),
      ]) {
        final scope = TestScope(
          languageRepository: FakeLanguagePreferenceRepository(language),
        );
        expect(scope.container.read(appLocaleProvider), expected);
      }
    });

    test('follows a language change', () async {
      final scope = TestScope();
      expect(scope.container.read(appLocaleProvider), isNull);

      await scope.container
          .read(appLanguageProvider.notifier)
          .setLanguage(AppLanguage.japanese);

      expect(scope.container.read(appLocaleProvider), const Locale('ja'));
    });
  });
}
