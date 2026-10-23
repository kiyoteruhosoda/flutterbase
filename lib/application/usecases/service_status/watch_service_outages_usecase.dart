import 'package:flutterbase/application/ports/app_logger.dart';
import 'package:flutterbase/application/ports/service_status.dart';
import 'package:flutterbase/domain/entities/service_outage.dart';

/// The outages calls to the paired web app run into, logged as they come.
final class WatchServiceOutagesUseCase {
  const WatchServiceOutagesUseCase(this._status, this._logger);

  final ServiceStatus _status;
  final AppLogger _logger;

  Stream<ServiceOutage> execute() => _status.outages.map((outage) {
    _logger.warning('[Service] out of service — $outage');
    return outage;
  });
}
