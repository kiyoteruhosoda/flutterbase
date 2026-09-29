import 'package:flutterbase/application/ports/app_logger.dart';
import 'package:flutterbase/domain/repositories/app_notice_repository.dart';

/// Records every notice as read on the server (the bell's 「すべて既読」).
final class MarkAllNoticesReadUseCase {
  const MarkAllNoticesReadUseCase(this._notices, this._logger);

  final AppNoticeRepository _notices;
  final AppLogger _logger;

  Future<void> execute() async {
    try {
      await _notices.markAllRead();
      _logger.info('[Notices] all read');
    } on Exception catch (e) {
      _logger.warning('[Notices] marking all read failed', error: e);
      rethrow;
    }
  }
}
