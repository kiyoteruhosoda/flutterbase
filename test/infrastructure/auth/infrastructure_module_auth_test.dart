import 'package:flutter_test/flutter_test.dart';
import 'package:flutterbase/domain/value_objects/sign_in_settings.dart';
import 'package:flutterbase/infrastructure/auth/oidc_auth_session.dart';
import 'package:flutterbase/infrastructure/infrastructure_module.dart';

void main() {
  test('no sign-in adapter is built when the sign-in is off', () {
    expect(
      InfrastructureModule.authSessionFor(const SignInSettings.disabled()),
      isNull,
    );
  });

  test('the AppAuth session is built when the sign-in is on', () {
    const settings = SignInSettings(
      issuer: 'https://identity.example.com/tenant',
      clientId: 'app-client',
      linkHost: 'web.example.com',
    );
    expect(
      InfrastructureModule.authSessionFor(settings),
      isA<OidcAuthSession>(),
    );
  });
}
