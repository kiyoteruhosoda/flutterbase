import 'package:flutterbase/application/ports/app_logger.dart';
import 'package:flutterbase/domain/entities/app_notice.dart';
import 'package:flutterbase/domain/repositories/app_notice_repository.dart';

/// Closes a notice's banner on the server (which also marks it read), so it
/// does not come back on the next load — here or in the browser.
final class DismissNoticeUseCase {
  const DismissNoticeUseCase(this._notices, this._logger);

  final AppNoticeRepository _notices;
  final AppLogger _logger;

  Future<void> execute(AppNotice notice) async {
    try {
      await _notices.dismiss(notice.id);
      _logger.info('[Notices] banner #${notice.id} dismissed');
    } on Exception catch (e) {
      _logger.warning('[Notices] dismissing #${notice.id} failed', error: e);
      rethrow;
    }
  }
}
