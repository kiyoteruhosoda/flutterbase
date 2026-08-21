import 'package:flutter_test/flutter_test.dart';
import 'package:flutterbase/domain/value_objects/log_level.dart';
import 'package:flutterbase/presentation/providers/debug_providers.dart';

import '../../support/fakes.dart';
import '../../support/recording_app_logger.dart';
import '../../support/test_harness.dart';

void main() {
  group('DebugModeNotifier', () {
    test('reads the stored flag on first build', () {
      final scope = TestScope(
        debugSettingsRepository: FakeDebugSettingsRepository(debugMode: false),
      );
      expect(scope.container.read(debugModeProvider), isFalse);
    });

    test('setEnabled persists the choice and updates the state', () async {
      final scope = TestScope();

      await scope.container.read(debugModeProvider.notifier).setEnabled(false);

      expect(scope.debugSettingsRepository.savedDebugModes, equals([false]));
      expect(scope.container.read(debugModeProvider), isFalse);
    });

    test('setEnabled to the same value still writes through', () async {
      // Unlike theme and language, debug mode has no early-out: the switch is
      // the source of truth and a redundant write is harmless.
      final scope = TestScope();

      await scope.container.read(debugModeProvider.notifier).setEnabled(true);

      expect(scope.debugSettingsRepository.savedDebugModes, equals([true]));
    });
  });

  group('LogLevelNotifier', () {
    test('reads the stored level on first build', () {
      final scope = TestScope(
        debugSettingsRepository: FakeDebugSettingsRepository(
          minLogLevel: LogLevel.warning,
        ),
      );
      expect(scope.container.read(logLevelProvider), LogLevel.warning);
    });

    test(
      'setLevel persists it, applies it to the logger and updates',
      () async {
        final logger = RecordingAppLogger();
        final scope = TestScope(logger: logger);

        await scope.container
            .read(logLevelProvider.notifier)
            .setLevel(LogLevel.error);

        expect(
          scope.debugSettingsRepository.savedLogLevels,
          equals([LogLevel.error]),
        );
        expect(logger.setMinLevelCalls, equals([LogLevel.error]));
        expect(scope.container.read(logLevelProvider), LogLevel.error);
      },
    );
  });
}
