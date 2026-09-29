import 'package:flutterbase/application/ports/app_logger.dart';
import 'package:flutterbase/application/ports/external_link_launcher.dart';
import 'package:flutterbase/domain/entities/app_release.dart';

/// Opens a release's download link in the external browser.
///
/// The APK is installed by Android's own installer from the browser's
/// download, so the app never handles the file itself.
final class OpenUpdateDownloadUseCase {
  const OpenUpdateDownloadUseCase(this._launcher, this._logger);

  final ExternalLinkLauncher _launcher;
  final AppLogger _logger;

  /// Returns false when the release has no link or nothing can open it.
  Future<bool> execute(AppRelease release) async {
    final url = release.downloadUrl;
    if (url == null) return false;
    final opened = await _launcher.open(url);
    if (opened) {
      _logger.info('[Update] opened the download of $release');
    } else {
      _logger.warning('[Update] no handler for the download of $release');
    }
    return opened;
  }
}
