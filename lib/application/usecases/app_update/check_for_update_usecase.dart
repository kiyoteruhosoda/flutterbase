import 'package:flutterbase/application/ports/app_logger.dart';
import 'package:flutterbase/domain/entities/app_release.dart';
import 'package:flutterbase/domain/repositories/app_info_repository.dart';
import 'package:flutterbase/domain/repositories/app_release_repository.dart';
import 'package:flutterbase/domain/repositories/dismissed_update_repository.dart';

/// Answers "is there a newer build to tell the person about?".
///
/// Returns the release to announce, or null. Null covers every reason not to
/// show a banner: nothing published, this build is as new or newer, the
/// person closed the banner for that build, or the check failed. An update
/// notice is a courtesy — a server that cannot be reached, or a sign-in that
/// ran out, must never turn into an error on the main screen.
final class CheckForUpdateUseCase {
  const CheckForUpdateUseCase(
    this._releases,
    this._appInfo,
    this._dismissed,
    this._logger,
  );

  final AppReleaseRepository _releases;
  final AppInfoRepository _appInfo;
  final DismissedUpdateRepository _dismissed;
  final AppLogger _logger;

  Future<AppRelease?> execute() async {
    try {
      final info = await _appInfo.getAppInfo();
      final installed = int.tryParse(info.buildNumber.trim());
      if (installed == null) {
        _logger.warning(
          '[Update] own build number "${info.buildNumber}" is not a number; '
          'skipping the check',
        );
        return null;
      }
      final latest = await _releases.latest();
      if (latest == null || !latest.isNewerThan(installed)) {
        _logger.debug(
          '[Update] up to date (installed $installed, '
          'latest ${latest?.build ?? 'none'})',
        );
        return null;
      }
      final dismissed = _dismissed.get();
      if (dismissed != null && latest.build <= dismissed) {
        _logger.debug('[Update] $latest was dismissed');
        return null;
      }
      _logger.info('[Update] $latest is available (installed $installed)');
      return latest;
    } on Exception catch (e) {
      _logger.warning('[Update] check failed', error: e);
      return null;
    }
  }
}
