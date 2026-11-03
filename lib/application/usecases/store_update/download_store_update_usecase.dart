import 'package:flutterbase/application/ports/app_logger.dart';
import 'package:flutterbase/application/ports/store_update_gateway.dart';

/// Downloads the store's newer build in the background, after the store's
/// own prompt (docs/adr/0012-*).
final class DownloadStoreUpdateUseCase {
  const DownloadStoreUpdateUseCase(this._store, this._logger);

  final StoreUpdateGateway _store;
  final AppLogger _logger;

  /// True when the build is downloaded and ready to install; false when the
  /// person declined or the store could not fetch it.
  Future<bool> execute() async {
    final ready = await _store.download();
    _logger.info(
      ready
          ? '[StoreUpdate] the update is downloaded'
          : '[StoreUpdate] the update was not downloaded',
    );
    return ready;
  }
}
