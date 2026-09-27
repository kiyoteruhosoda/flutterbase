import 'package:flutterbase/application/ports/app_logger.dart';
import 'package:flutterbase/application/ports/auth_session.dart';
import 'package:flutterbase/domain/entities/account.dart';
import 'package:flutterbase/domain/errors/app_error.dart';

/// Signs in through the identity provider's page.
///
/// Returns null when the person closes the page: backing out is a choice, not
/// a failure to report. Every other error propagates to the caller.
final class SignInUseCase {
  const SignInUseCase(this._session, this._logger);

  final AuthSession _session;
  final AppLogger _logger;

  Future<Account?> execute() async {
    try {
      final account = await _session.signIn();
      _logger.info('[Auth] signed in');
      return account;
    } on SignInCancelledError {
      _logger.info('[Auth] sign-in cancelled');
      return null;
    }
  }
}
