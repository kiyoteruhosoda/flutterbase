import 'package:flutterbase/application/ports/app_logger.dart';
import 'package:flutterbase/application/ports/store_update_gateway.dart';

/// Asks the store the app was installed from whether a newer build is out
/// (docs/adr/0012-*).
///
/// Answers [StoreUpdateStatus.none] for a copy the store did not install;
/// the gateway never throws.
final class CheckStoreUpdateUseCase {
  const CheckStoreUpdateUseCase(this._store, this._logger);

  final StoreUpdateGateway _store;
  final AppLogger _logger;

  Future<StoreUpdateStatus> execute() async {
    final status = await _store.check();
    if (status != StoreUpdateStatus.none) {
      _logger.info('[StoreUpdate] the store has an update: ${status.name}');
    }
    return status;
  }
}
