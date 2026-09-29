import 'package:flutterbase/application/ports/app_logger.dart';
import 'package:flutterbase/application/ports/external_link_launcher.dart';
import 'package:flutterbase/domain/entities/app_notice.dart';

/// Opens a notice's link in the external browser.
///
/// A path of the web app (`/items`) opens on [_webBaseUrl]: the app has no
/// route of that name, and the browser already holds the web app's sign-in.
/// See [AppNotice.linkTarget] for what is refused.
final class OpenNoticeLinkUseCase {
  const OpenNoticeLinkUseCase(this._launcher, this._webBaseUrl, this._logger);

  final ExternalLinkLauncher _launcher;
  final Uri _webBaseUrl;
  final AppLogger _logger;

  /// Returns false when the notice has no usable link or nothing can open it.
  Future<bool> execute(AppNotice notice) async {
    final target = notice.linkTarget(_webBaseUrl);
    if (target == null) {
      if (notice.linkUrl != null) {
        _logger.warning('[Notices] #${notice.id} has an unusable link');
      }
      return false;
    }
    final opened = await _launcher.open(target);
    if (opened) {
      _logger.info('[Notices] opened the link of #${notice.id}');
    } else {
      _logger.warning('[Notices] no handler for the link of #${notice.id}');
    }
    return opened;
  }
}
