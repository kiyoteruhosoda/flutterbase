import 'package:flutter_test/flutter_test.dart';
import 'package:flutterbase/domain/value_objects/sign_in_settings.dart';

void main() {
  const full = SignInSettings(
    issuer: 'https://identity.example.com/tenant',
    clientId: 'app-client',
    linkHost: 'recipebox.nolumia.com',
  );

  group('SignInSettings', () {
    test('is on only when all three values are present', () {
      expect(full.isEnabled, isTrue);
      expect(const SignInSettings.disabled().isEnabled, isFalse);
      for (final missing in <SignInSettings>[
        const SignInSettings(issuer: '', clientId: 'c', linkHost: 'h'),
        const SignInSettings(issuer: 'i', clientId: ' ', linkHost: 'h'),
        const SignInSettings(issuer: 'i', clientId: 'c', linkHost: ''),
      ]) {
        expect(missing.isEnabled, isFalse, reason: '$missing');
      }
    });

    test('redirects through the App Link on the paired host', () {
      expect(
        full.redirectUri,
        'https://recipebox.nolumia.com/app/oauth2redirect',
      );
      expect(SignInSettings.redirectPath, '/app/oauth2redirect');
    });

    test('value equality', () {
      const same = SignInSettings(
        issuer: 'https://identity.example.com/tenant',
        clientId: 'app-client',
        linkHost: 'recipebox.nolumia.com',
      );
      expect(full, same);
      expect(full.hashCode, same.hashCode);
      expect(full == const SignInSettings.disabled(), isFalse);
    });

    test('describes itself (issuer and client id are not secrets)', () {
      expect(full.toString(), contains('app-client'));
      expect(const SignInSettings.disabled().toString(), contains('off'));
    });
  });
}
