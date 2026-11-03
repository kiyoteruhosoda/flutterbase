import 'package:flutter_test/flutter_test.dart';
import 'package:flutterbase/application/ports/store_update_gateway.dart';
import 'package:flutterbase/application/usecases/store_update/check_store_update_usecase.dart';
import 'package:flutterbase/application/usecases/store_update/download_store_update_usecase.dart';
import 'package:flutterbase/application/usecases/store_update/install_store_update_usecase.dart';
import 'package:flutterbase/domain/value_objects/log_level.dart';

import '../../../support/fakes.dart';
import '../../../support/recording_app_logger.dart';

void main() {
  late FakeStoreUpdateGateway store;
  late RecordingAppLogger logger;

  setUp(() {
    store = FakeStoreUpdateGateway();
    logger = RecordingAppLogger();
  });

  group('CheckStoreUpdateUseCase', () {
    test('answers what the store says and logs an offer', () async {
      store.status = StoreUpdateStatus.available;
      final status = await CheckStoreUpdateUseCase(store, logger).execute();
      expect(status, StoreUpdateStatus.available);
      expect(logger.messagesAt(LogLevel.info).single, contains('available'));
    });

    test('stays quiet when there is nothing to offer', () async {
      final status = await CheckStoreUpdateUseCase(store, logger).execute();
      expect(status, StoreUpdateStatus.none);
      expect(logger.entries, isEmpty);
    });
  });

  group('DownloadStoreUpdateUseCase', () {
    test('true once the store has downloaded the build', () async {
      expect(await DownloadStoreUpdateUseCase(store, logger).execute(), isTrue);
      expect(store.downloads, 1);
      expect(logger.messagesAt(LogLevel.info).single, contains('downloaded'));
    });

    test('false when the person declined', () async {
      store.downloadSucceeds = false;
      expect(
        await DownloadStoreUpdateUseCase(store, logger).execute(),
        isFalse,
      );
      expect(
        logger.messagesAt(LogLevel.info).single,
        contains('not downloaded'),
      );
    });
  });

  group('InstallStoreUpdateUseCase', () {
    test('hands the install to the store', () async {
      await InstallStoreUpdateUseCase(store, logger).execute();
      expect(store.installs, 1);
      expect(logger.messagesAt(LogLevel.info).single, contains('installing'));
    });
  });
}
