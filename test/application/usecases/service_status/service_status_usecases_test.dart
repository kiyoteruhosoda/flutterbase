import 'package:flutter_test/flutter_test.dart';
import 'package:flutterbase/application/usecases/service_status/check_service_usecase.dart';
import 'package:flutterbase/application/usecases/service_status/watch_service_outages_usecase.dart';
import 'package:flutterbase/domain/entities/service_outage.dart';
import 'package:flutterbase/domain/errors/app_error.dart';
import 'package:flutterbase/domain/value_objects/log_level.dart';

import '../../../support/fakes.dart';
import '../../../support/recording_app_logger.dart';

const ServiceOutage outage = ServiceOutage(
  reason: ServiceOutageReason.maintenance,
);

void main() {
  late FakeServiceStatus status;
  late RecordingAppLogger logger;

  setUp(() {
    status = FakeServiceStatus();
    logger = RecordingAppLogger();
  });

  tearDown(() => status.close());

  group('WatchServiceOutagesUseCase', () {
    test('passes every outage on and logs it', () async {
      final seen = <ServiceOutage>[];
      final subscription = WatchServiceOutagesUseCase(
        status,
        logger,
      ).execute().listen(seen.add);
      addTearDown(subscription.cancel);

      status.outageController.add(outage);
      await Future<void>.delayed(Duration.zero);

      expect(seen, [outage]);
      expect(logger.messagesAt(LogLevel.warning), hasLength(1));
    });
  });

  group('CheckServiceUseCase', () {
    test('answers the outage while it lasts', () async {
      status.checkAnswer = outage;
      expect(await CheckServiceUseCase(status, logger).execute(), outage);
    });

    test('answers null once the service is back', () async {
      expect(await CheckServiceUseCase(status, logger).execute(), isNull);
      expect(logger.messagesAt(LogLevel.info), ['[Service] back in service']);
    });

    test('logs and rethrows a failed request', () async {
      status.checkFailure = const InfrastructureError('offline');
      await expectLater(
        CheckServiceUseCase(status, logger).execute(),
        throwsA(isA<InfrastructureError>()),
      );
      expect(logger.messagesAt(LogLevel.warning), hasLength(1));
    });
  });
}
