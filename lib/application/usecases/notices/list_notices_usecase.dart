import 'package:flutterbase/application/ports/app_logger.dart';
import 'package:flutterbase/domain/entities/app_notice.dart';
import 'package:flutterbase/domain/repositories/app_notice_repository.dart';

/// Loads the signed-in person's notices from the paired web app.
///
/// Failures are logged and rethrown: the caller keeps what it was showing.
final class ListNoticesUseCase {
  const ListNoticesUseCase(this._notices, this._logger);

  final AppNoticeRepository _notices;
  final AppLogger _logger;

  Future<AppNoticeInbox> execute() async {
    try {
      final inbox = await _notices.list();
      _logger.debug(
        '[Notices] loaded ${inbox.items.length} '
        '(unread ${inbox.unreadCount})',
      );
      return inbox;
    } on Exception catch (e) {
      _logger.warning('[Notices] load failed', error: e);
      rethrow;
    }
  }
}
