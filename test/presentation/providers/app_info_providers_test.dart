import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutterbase/domain/value_objects/log_level.dart';
import 'package:flutterbase/presentation/providers/app_info_providers.dart';

import '../../support/fakes.dart';
import '../../support/recording_app_logger.dart';
import '../../support/test_harness.dart';

void main() {
  group('appInfoProvider', () {
    test('starts loading before the first value arrives', () {
      final scope = TestScope();
      expect(scope.container.read(appInfoProvider), isA<AsyncLoading<void>>());
    });

    test('resolves to the metadata the repository reports', () async {
      final scope = TestScope();

      final info = await scope.container.read(appInfoProvider.future);

      expect(info.version, testAppInfo.version);
      expect(scope.appInfoRepository.callCount, 1);
    });

    test('is read once however many screens ask for it', () async {
      final scope = TestScope();

      await scope.container.read(appInfoProvider.future);
      await scope.container.read(appInfoProvider.future);

      expect(scope.appInfoRepository.callCount, 1);
    });

    test('invalidating it re-reads the repository', () async {
      final scope = TestScope();
      await scope.container.read(appInfoProvider.future);

      scope.container.invalidate(appInfoProvider);
      await scope.container.read(appInfoProvider.future);

      expect(scope.appInfoRepository.callCount, 2);
    });

    test('a repository failure surfaces as an error state', () async {
      final scope = TestScope(
        appInfoRepository: FakeAppInfoRepository(failure: 'no platform'),
      );

      await expectLater(
        scope.container.read(appInfoProvider.future),
        throwsA(isA<Exception>()),
      );
      expect(scope.container.read(appInfoProvider), isA<AsyncError<void>>());
    });

    test('a failure is logged at error level', () async {
      final logger = RecordingAppLogger();
      final scope = TestScope(
        logger: logger,
        appInfoRepository: FakeAppInfoRepository(failure: 'no platform'),
      );

      await expectLater(
        scope.container.read(appInfoProvider.future),
        throwsA(isA<Exception>()),
      );
      expect(logger.messagesAt(LogLevel.error), hasLength(1));
    });
  });
}
