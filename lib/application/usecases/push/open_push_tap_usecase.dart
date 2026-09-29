import 'package:flutterbase/application/ports/app_logger.dart';
import 'package:flutterbase/application/ports/external_link_launcher.dart';
import 'package:flutterbase/application/ports/push_messaging.dart';
import 'package:flutterbase/domain/entities/app_notice.dart';
import 'package:flutterbase/domain/repositories/app_notice_repository.dart';

/// The person tapped a device notification: record the notice as read and
/// open its link, as tapping it under the bell would.
///
/// The link opens in the external browser; a path of the web app (`/items`)
/// resolves against [_webBaseUrl] ([noticeLinkTarget]).
final class OpenPushTapUseCase {
  const OpenPushTapUseCase(
    this._notices,
    this._launcher,
    this._webBaseUrl,
    this._logger,
  );

  final AppNoticeRepository _notices;
  final ExternalLinkLauncher _launcher;
  final Uri _webBaseUrl;
  final AppLogger _logger;

  /// Answers whether a link was opened. A failed read does not stop the link:
  /// the person asked to go there.
  Future<bool> execute(PushTap tap) async {
    final id = tap.noticeId;
    if (id != null) {
      try {
        await _notices.markRead(id);
      } on Exception catch (e) {
        _logger.warning('[Push] marking #$id read failed', error: e);
      }
    }
    final target = noticeLinkTarget(tap.linkUrl, _webBaseUrl);
    if (target == null) {
      if (tap.linkUrl != null) _logger.warning('[Push] unusable link in #$id');
      return false;
    }
    final opened = await _launcher.open(target);
    if (!opened) _logger.warning('[Push] no handler for the link of #$id');
    return opened;
  }
}
