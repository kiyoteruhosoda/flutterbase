import 'package:flutterbase/application/ports/app_logger.dart';
import 'package:flutterbase/application/ports/push_messaging.dart';
import 'package:flutterbase/domain/repositories/device_registration_repository.dart';

/// Takes this device off the signed-in person's list before they sign out,
/// so the next person on the device does not receive their notices.
///
/// Must run **before** the sign-out: the request is made with the person's
/// access token. A failure is logged and swallowed — signing out must not be
/// blocked by the network; the server also moves the device to whoever
/// registers it next.
final class UnregisterFromPushUseCase {
  const UnregisterFromPushUseCase(this._messaging, this._devices, this._logger);

  final PushMessaging _messaging;
  final DeviceRegistrationRepository _devices;
  final AppLogger _logger;

  Future<void> execute() async {
    try {
      final token = await _messaging.token();
      if (token == null || token.isEmpty) return;
      await _devices.unregister(token);
      _logger.info('[Push] device unregistered');
    } on Exception catch (e) {
      _logger.warning('[Push] unregistering the device failed', error: e);
    }
  }
}
