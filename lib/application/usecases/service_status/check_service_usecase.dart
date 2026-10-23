import 'package:flutterbase/application/ports/app_logger.dart';
import 'package:flutterbase/application/ports/service_status.dart';
import 'package:flutterbase/domain/entities/service_outage.dart';

/// Asks whether the paired web app is back in service.
///
/// Answers the outage while it lasts and null once the web app answers again.
/// A failed request is logged and rethrown: it says nothing either way, so the
/// caller keeps what it was showing.
final class CheckServiceUseCase {
  const CheckServiceUseCase(this._status, this._logger);

  final ServiceStatus _status;
  final AppLogger _logger;

  Future<ServiceOutage?> execute() async {
    try {
      final outage = await _status.check();
      _logger.info(
        outage == null
            ? '[Service] back in service'
            : '[Service] still out of service — $outage',
      );
      return outage;
    } on Exception catch (e) {
      _logger.warning('[Service] check failed', error: e);
      rethrow;
    }
  }
}
