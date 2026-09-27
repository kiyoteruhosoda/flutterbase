import 'package:flutterbase/application/ports/auth_session.dart';
import 'package:flutterbase/domain/entities/account.dart';

/// Who is signed in on this device, or null.
final class GetCurrentAccountUseCase {
  const GetCurrentAccountUseCase(this._session);

  final AuthSession _session;

  Future<Account?> execute() => _session.currentAccount();
}
