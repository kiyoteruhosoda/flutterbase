import 'package:flutter/services.dart';
import 'package:flutterbase/application/ports/app_logger.dart';
import 'package:flutterbase/application/ports/store_update_gateway.dart';
import 'package:in_app_update/in_app_update.dart';

/// [StoreUpdateGateway] backed by Google Play's in-app updates, through the
/// `in_app_update` plugin (docs/adr/0012-*).
///
/// Only the flexible flow: the update downloads while the person goes on
/// using the app, and installs when they say so. The immediate flow takes
/// over the screen, which no update of a template-born app is urgent enough
/// to justify.
///
/// A platform that refuses is **logged and swallowed** (the port never
/// throws). Play answers with an error on a copy it did not install, which is
/// the normal case for the APK from share.nolumia.com and for a local build.
final class PlayStoreUpdateGateway implements StoreUpdateGateway {
  const PlayStoreUpdateGateway(this._logger);

  final AppLogger _logger;

  @override
  Future<StoreUpdateStatus> check() async {
    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.installStatus == InstallStatus.downloaded) {
        return StoreUpdateStatus.downloaded;
      }
      if (info.updateAvailability == UpdateAvailability.updateAvailable &&
          info.flexibleUpdateAllowed) {
        _logger.info(
          '[StoreUpdate] build ${info.availableVersionCode} is out on Play',
        );
        return StoreUpdateStatus.available;
      }
      return StoreUpdateStatus.none;
    } on PlatformException catch (error) {
      _logger.debug('[StoreUpdate] Play cannot be asked: ${error.message}');
      return StoreUpdateStatus.none;
    } on MissingPluginException catch (error) {
      // A unit test host, or a platform the plugin does not cover.
      _logger.debug('[StoreUpdate] no platform implementation: $error');
      return StoreUpdateStatus.none;
    }
  }

  @override
  Future<bool> download() async {
    try {
      final result = await InAppUpdate.startFlexibleUpdate();
      if (result != AppUpdateResult.success) {
        _logger.info('[StoreUpdate] the download did not start: $result');
      }
      return result == AppUpdateResult.success;
    } on PlatformException catch (error) {
      _logger.warning(
        '[StoreUpdate] Play refused the download: ${error.message}',
      );
      return false;
    } on MissingPluginException catch (error) {
      _logger.debug('[StoreUpdate] no platform implementation: $error');
      return false;
    }
  }

  @override
  Future<void> install() async {
    try {
      await InAppUpdate.completeFlexibleUpdate();
    } on PlatformException catch (error) {
      _logger.warning('[StoreUpdate] Play could not install: ${error.message}');
    } on MissingPluginException catch (error) {
      _logger.debug('[StoreUpdate] no platform implementation: $error');
    }
  }
}
