import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutterbase/domain/value_objects/app_theme_mode.dart';
import 'package:flutterbase/domain/value_objects/log_level.dart';
import 'package:flutterbase/presentation/providers/theme_providers.dart';

import '../../support/fakes.dart';
import '../../support/recording_app_logger.dart';
import '../../support/test_harness.dart';

void main() {
  group('ThemeModeNotifier', () {
    test('defaults to light mode when no preference is stored', () {
      final scope = TestScope();
      expect(scope.container.read(themeModeProvider), ThemeMode.light);
    });

    test('reads the stored preference on first build', () {
      for (final (stored, expected) in <(AppThemeMode, ThemeMode)>[
        (AppThemeMode.dark, ThemeMode.dark),
        (AppThemeMode.system, ThemeMode.system),
      ]) {
        final scope = TestScope(
          themeRepository: FakeThemePreferenceRepository(stored),
        );
        expect(scope.container.read(themeModeProvider), expected);
      }
    });

    test('logs its initial state', () {
      final logger = RecordingAppLogger();
      TestScope(logger: logger);
      expect(logger.messagesAt(LogLevel.debug).join(), contains('[Theme]'));
    });

    test('setThemeMode persists the choice and updates the state', () async {
      final scope = TestScope();

      await scope.container
          .read(themeModeProvider.notifier)
          .setThemeMode(ThemeMode.dark);

      expect(scope.themeRepository.saved, equals([AppThemeMode.dark]));
      expect(scope.container.read(themeModeProvider), ThemeMode.dark);
    });

    test('setThemeMode to the current value is a no-op', () async {
      final scope = TestScope();

      await scope.container
          .read(themeModeProvider.notifier)
          .setThemeMode(ThemeMode.light);

      expect(scope.themeRepository.saved, isEmpty);
    });

    test('every mode round-trips through the repository', () async {
      final scope = TestScope();
      final notifier = scope.container.read(themeModeProvider.notifier);

      await notifier.setThemeMode(ThemeMode.dark);
      await notifier.setThemeMode(ThemeMode.system);
      await notifier.setThemeMode(ThemeMode.light);

      expect(
        scope.themeRepository.saved,
        equals([AppThemeMode.dark, AppThemeMode.system, AppThemeMode.light]),
      );
    });

    test('a failed write leaves the app on the mode that is stored', () async {
      final repository = FakeThemePreferenceRepository()..failOnSave = true;
      final scope = TestScope(themeRepository: repository);

      await expectLater(
        scope.container
            .read(themeModeProvider.notifier)
            .setThemeMode(ThemeMode.dark),
        throwsA(isA<Exception>()),
      );

      expect(scope.container.read(themeModeProvider), ThemeMode.light);
    });
  });
}
