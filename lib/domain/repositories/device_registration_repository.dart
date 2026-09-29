/// Where the paired web app keeps this device's FCM token, so that notices
/// sent to the signed-in person reach it
/// (`/api/notifications/device/*`, fastapitemplate ADR-0049).
abstract interface class DeviceRegistrationRepository {
  /// Records [token] as the signed-in person's device. Sent on every start
  /// and sign-in: FCM may have replaced the token in the meantime.
  Future<void> register(String token);

  /// Forgets [token], so the next person on this device does not receive the
  /// last one's notices.
  Future<void> unregister(String token);
}
