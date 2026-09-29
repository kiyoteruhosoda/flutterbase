import 'package:flutterbase/application/ports/app_logger.dart';
import 'package:flutterbase/domain/entities/app_notice.dart';
import 'package:flutterbase/domain/repositories/app_notice_repository.dart';

/// Records one notice as read on the server. Already-read notices are left
/// alone (no request).
final class MarkNoticeReadUseCase {
  const MarkNoticeReadUseCase(this._notices, this._logger);

  final AppNoticeRepository _notices;
  final AppLogger _logger;

  Future<void> execute(AppNotice notice) async {
    if (notice.isRead) return;
    try {
      await _notices.markRead(notice.id);
      _logger.debug('[Notices] #${notice.id} read');
    } on Exception catch (e) {
      _logger.warning('[Notices] marking #${notice.id} read failed', error: e);
      rethrow;
    }
  }
}
