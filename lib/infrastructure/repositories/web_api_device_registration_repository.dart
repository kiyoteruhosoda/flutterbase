import 'package:flutterbase/domain/repositories/device_registration_repository.dart';
import 'package:flutterbase/infrastructure/api/web_api_client.dart';

/// This device's FCM token on the paired web app
/// (`/api/notifications/device/*`, fastapitemplate ADR-0049).
final class WebApiDeviceRegistrationRepository
    implements DeviceRegistrationRepository {
  const WebApiDeviceRegistrationRepository(this._api);

  static const String path = '/api/notifications/device';

  /// The only kind of device the template builds for.
  static const String platform = 'android';

  final WebApiClient _api;

  @override
  Future<void> register(String token) =>
      _api.postJson('$path/register', {'token': token, 'platform': platform});

  @override
  Future<void> unregister(String token) =>
      _api.postJson('$path/unregister', {'token': token});
}
