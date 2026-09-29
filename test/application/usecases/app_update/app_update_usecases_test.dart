import 'package:flutter_test/flutter_test.dart';
import 'package:flutterbase/application/usecases/app_update/check_for_update_usecase.dart';
import 'package:flutterbase/application/usecases/app_update/dismiss_update_usecase.dart';
import 'package:flutterbase/application/usecases/app_update/open_update_download_usecase.dart';
import 'package:flutterbase/domain/entities/app_info.dart';
import 'package:flutterbase/domain/entities/app_release.dart';
import 'package:flutterbase/domain/errors/app_error.dart';
import 'package:flutterbase/domain/value_objects/log_level.dart';

import '../../../support/fakes.dart';
import '../../../support/recording_app_logger.dart';

/// The installed build in these tests ([testAppInfo] says 42).
const int installed = 42;

AppRelease release(int build, {bool link = true}) => AppRelease(
  version: '1.$build.0',
  build: build,
  downloadUrl: link ? Uri.parse('https://share.example.com/app.apk') : null,
);

void main() {
  late FakeAppReleaseRepository releases;
  late FakeDismissedUpdateRepository dismissed;
  late RecordingAppLogger logger;

  CheckForUpdateUseCase check({AppInfo? info}) => CheckForUpdateUseCase(
    releases,
    FakeAppInfoRepository(info: info),
    dismissed,
    logger,
  );

  setUp(() {
    releases = FakeAppReleaseRepository();
    dismissed = FakeDismissedUpdateRepository();
    logger = RecordingAppLogger();
  });

  group('CheckForUpdateUseCase', () {
    test('announces a newer build', () async {
      releases.release = release(installed + 1);
      expect(await check().execute(), release(installed + 1));
      expect(logger.messagesAt(LogLevel.info).single, contains('available'));
    });

    test('says nothing for the same build', () async {
      releases.release = release(installed);
      expect(await check().execute(), isNull);
    });

    test('says nothing for an older build', () async {
      releases.release = release(installed - 1);
      expect(await check().execute(), isNull);
    });

    test('says nothing when nothing is published', () async {
      expect(await check().execute(), isNull);
    });

    test('says nothing for the build whose banner was closed', () async {
      releases.release = release(50);
      dismissed.build = 50;
      expect(await check().execute(), isNull);
    });

    test('announces a build newer than the one closed', () async {
      releases.release = release(51);
      dismissed.build = 50;
      expect(await check().execute(), release(51));
    });

    test('a failure is logged and shows nothing', () async {
      releases.failure = const InfrastructureError('offline');
      expect(await check().execute(), isNull);
      expect(logger.messagesAt(LogLevel.warning).single, contains('failed'));
    });

    test('a missing sign-in shows nothing', () async {
      releases.failure = const SignInRequiredError('signed out');
      expect(await check().execute(), isNull);
    });

    test('an unreadable own build number skips the check', () async {
      releases.release = release(999);
      const info = AppInfo(
        version: '1.0.0',
        buildNumber: 'unknown',
        gitCommit: 'x',
        gitCommitFull: 'x',
        flutterVersion: 'x',
        dartVersion: 'x',
        buildDate: 'x',
        isDebug: false,
      );
      expect(await check(info: info).execute(), isNull);
      expect(releases.calls, 0);
    });
  });

  group('DismissUpdateUseCase', () {
    test('remembers the closed build', () async {
      await DismissUpdateUseCase(dismissed, logger).execute(release(60));
      expect(dismissed.build, 60);
    });
  });

  group('OpenUpdateDownloadUseCase', () {
    test('opens the download link', () async {
      final launcher = RecordingExternalLinkLauncher();
      final opened = await OpenUpdateDownloadUseCase(
        launcher,
        logger,
      ).execute(release(60));
      expect(opened, isTrue);
      expect(launcher.opened, [Uri.parse('https://share.example.com/app.apk')]);
    });

    test('reports a device that cannot open it', () async {
      final launcher = RecordingExternalLinkLauncher(result: false);
      final opened = await OpenUpdateDownloadUseCase(
        launcher,
        logger,
      ).execute(release(60));
      expect(opened, isFalse);
      expect(logger.messagesAt(LogLevel.warning), hasLength(1));
    });

    test('does nothing without a link', () async {
      final launcher = RecordingExternalLinkLauncher();
      final opened = await OpenUpdateDownloadUseCase(
        launcher,
        logger,
      ).execute(release(60, link: false));
      expect(opened, isFalse);
      expect(launcher.opened, isEmpty);
    });
  });
}
