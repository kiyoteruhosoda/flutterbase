import 'package:flutterbase/application/ports/app_logger.dart';
import 'package:flutterbase/application/ports/push_messaging.dart';
import 'package:flutterbase/domain/repositories/device_registration_repository.dart';

/// Hands this device's FCM token to the paired web app as the signed-in
/// person's (docs/adr/0010-notifications-through-fcm.md).
///
/// Run on every start and after a sign-in, and again whenever FCM replaces the
/// token: registering is idempotent on the server, and "only when it changed"
/// would silently miss a change that happened while the app was closed.
final class RegisterForPushUseCase {
  const RegisterForPushUseCase(this._messaging, this._devices, this._logger);

  final PushMessaging _messaging;
  final DeviceRegistrationRepository _devices;
  final AppLogger _logger;

  /// Answers whether the device is registered. False when the person declined
  /// the permission (nothing would be shown), when there is no token yet, or
  /// when the server refused; the reason is logged, never thrown.
  Future<bool> execute({String? token}) async {
    try {
      if (!await _messaging.requestPermission()) {
        _logger.info('[Push] notifications not allowed on this device');
        return false;
      }
      final current = token ?? await _messaging.token();
      if (current == null || current.isEmpty) {
        _logger.warning('[Push] FCM gave no token');
        return false;
      }
      await _devices.register(current);
      _logger.info('[Push] device registered');
      return true;
    } on Exception catch (e) {
      _logger.warning('[Push] registering the device failed', error: e);
      return false;
    }
  }
}
