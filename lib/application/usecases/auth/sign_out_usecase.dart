import 'package:flutterbase/application/ports/app_logger.dart';
import 'package:flutterbase/application/ports/auth_session.dart';

/// Forgets the sign-in on this device.
final class SignOutUseCase {
  const SignOutUseCase(this._session, this._logger);

  final AuthSession _session;
  final AppLogger _logger;

  Future<void> execute() async {
    await _session.signOut();
    _logger.info('[Auth] signed out');
  }
}
