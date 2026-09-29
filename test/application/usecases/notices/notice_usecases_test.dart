import 'package:flutter_test/flutter_test.dart';
import 'package:flutterbase/application/usecases/notices/dismiss_notice_usecase.dart';
import 'package:flutterbase/application/usecases/notices/list_notices_usecase.dart';
import 'package:flutterbase/application/usecases/notices/mark_all_notices_read_usecase.dart';
import 'package:flutterbase/application/usecases/notices/mark_notice_read_usecase.dart';
import 'package:flutterbase/application/usecases/notices/open_notice_link_usecase.dart';
import 'package:flutterbase/domain/entities/app_notice.dart';
import 'package:flutterbase/domain/errors/app_error.dart';
import 'package:flutterbase/domain/value_objects/log_level.dart';

import '../../../support/fakes.dart';
import '../../../support/recording_app_logger.dart';

final Uri base = Uri.parse('https://web.example.com');

void main() {
  late FakeAppNoticeRepository notices;
  late RecordingAppLogger logger;

  setUp(() {
    notices = FakeAppNoticeRepository();
    logger = RecordingAppLogger();
  });

  group('ListNoticesUseCase', () {
    test('answers the server inbox', () async {
      notices.inbox = AppNoticeInbox(items: [testNotice()], unreadCount: 1);
      final inbox = await ListNoticesUseCase(notices, logger).execute();
      expect(inbox.items.single.id, 1);
      expect(inbox.unreadCount, 1);
    });

    test('logs and rethrows a failure', () async {
      notices.failure = const InfrastructureError('offline');
      await expectLater(
        ListNoticesUseCase(notices, logger).execute(),
        throwsA(isA<InfrastructureError>()),
      );
      expect(logger.messagesAt(LogLevel.warning), hasLength(1));
    });
  });

  group('MarkNoticeReadUseCase', () {
    test('records an unread notice as read', () async {
      await MarkNoticeReadUseCase(notices, logger).execute(testNotice(id: 7));
      expect(notices.read, [7]);
    });

    test('skips a notice already read', () async {
      await MarkNoticeReadUseCase(
        notices,
        logger,
      ).execute(testNotice(readAt: testNoticeSentAt));
      expect(notices.read, isEmpty);
    });

    test('logs and rethrows a failure', () async {
      notices.failure = const InfrastructureError('offline');
      await expectLater(
        MarkNoticeReadUseCase(notices, logger).execute(testNotice()),
        throwsA(isA<InfrastructureError>()),
      );
      expect(logger.messagesAt(LogLevel.warning), hasLength(1));
    });
  });

  group('MarkAllNoticesReadUseCase', () {
    test('records every notice as read', () async {
      await MarkAllNoticesReadUseCase(notices, logger).execute();
      expect(notices.readAllCalls, 1);
    });

    test('logs and rethrows a failure', () async {
      notices.failure = const InfrastructureError('offline');
      await expectLater(
        MarkAllNoticesReadUseCase(notices, logger).execute(),
        throwsA(isA<InfrastructureError>()),
      );
      expect(logger.messagesAt(LogLevel.warning), hasLength(1));
    });
  });

  group('DismissNoticeUseCase', () {
    test('records the dismissal', () async {
      await DismissNoticeUseCase(notices, logger).execute(testNotice(id: 4));
      expect(notices.dismissed, [4]);
    });

    test('logs and rethrows a failure', () async {
      notices.failure = const InfrastructureError('offline');
      await expectLater(
        DismissNoticeUseCase(notices, logger).execute(testNotice()),
        throwsA(isA<InfrastructureError>()),
      );
      expect(logger.messagesAt(LogLevel.warning), hasLength(1));
    });
  });

  group('OpenNoticeLinkUseCase', () {
    test('opens a web app path on the web app', () async {
      final launcher = RecordingExternalLinkLauncher();
      final opened = await OpenNoticeLinkUseCase(
        launcher,
        base,
        logger,
      ).execute(testNotice(linkUrl: '/items'));
      expect(opened, isTrue);
      expect(launcher.opened, [Uri.parse('https://web.example.com/items')]);
    });

    test('refuses an unusable link without launching', () async {
      final launcher = RecordingExternalLinkLauncher();
      final opened = await OpenNoticeLinkUseCase(
        launcher,
        base,
        logger,
      ).execute(testNotice(linkUrl: 'javascript:alert(1)'));
      expect(opened, isFalse);
      expect(launcher.opened, isEmpty);
      expect(logger.messagesAt(LogLevel.warning), hasLength(1));
    });

    test('a notice without a link opens nothing', () async {
      final launcher = RecordingExternalLinkLauncher();
      final opened = await OpenNoticeLinkUseCase(
        launcher,
        base,
        logger,
      ).execute(testNotice());
      expect(opened, isFalse);
      expect(logger.messagesAt(LogLevel.warning), isEmpty);
    });

    test('reports a device that cannot open it', () async {
      final launcher = RecordingExternalLinkLauncher(result: false);
      final opened = await OpenNoticeLinkUseCase(
        launcher,
        base,
        logger,
      ).execute(testNotice(linkUrl: 'https://other.example.com/'));
      expect(opened, isFalse);
      expect(logger.messagesAt(LogLevel.warning), hasLength(1));
    });
  });
}
