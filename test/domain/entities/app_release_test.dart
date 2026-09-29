import 'package:flutter_test/flutter_test.dart';
import 'package:flutterbase/domain/entities/app_release.dart';

AppRelease release({int build = 356, String version = '1.53.0'}) => AppRelease(
  version: version,
  build: build,
  downloadUrl: Uri.parse('https://share.example.com/app.apk'),
  builtAt: DateTime.utc(2026, 9, 27, 1, 2, 3),
);

void main() {
  group('AppRelease.isNewerThan', () {
    test('a higher build is newer', () {
      expect(release(build: 356).isNewerThan(355), isTrue);
    });

    test('the same build is not newer', () {
      expect(release(build: 356).isNewerThan(356), isFalse);
    });

    test('a lower build is not newer, whatever the version says', () {
      expect(release(build: 300, version: '9.9.9').isNewerThan(356), isFalse);
    });
  });

  group('AppRelease equality', () {
    test('equal fields are equal', () {
      expect(release(), release());
      expect(release().hashCode, release().hashCode);
    });

    test('a different build is not equal', () {
      expect(release(build: 1), isNot(release(build: 2)));
    });

    test('toString names version and build', () {
      expect(release().toString(), 'AppRelease(1.53.0+356)');
    });
  });
}
