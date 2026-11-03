import 'package:flutterbase/application/ports/app_logger.dart';
import 'package:flutterbase/application/ports/store_update_gateway.dart';

/// Installs the downloaded build. The store restarts the app to do it
/// (docs/adr/0012-*).
final class InstallStoreUpdateUseCase {
  const InstallStoreUpdateUseCase(this._store, this._logger);

  final StoreUpdateGateway _store;
  final AppLogger _logger;

  Future<void> execute() async {
    _logger.info('[StoreUpdate] installing the downloaded update');
    await _store.install();
  }
}
