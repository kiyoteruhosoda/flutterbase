import 'package:flutter_test/flutter_test.dart';
import 'package:flutterbase/domain/value_objects/push_settings.dart';

const PushSettings full = PushSettings(
  apiKey: 'AIza-secret-looking',
  appId: '1:1234:android:abcd',
  messagingSenderId: '1234',
  projectId: 'example-project',
);

void main() {
  test('on only when all four values are present', () {
    expect(full.isEnabled, isTrue);
    expect(const PushSettings.disabled().isEnabled, isFalse);
    expect(
      const PushSettings(
        apiKey: 'k',
        appId: 'a',
        messagingSenderId: ' ',
        projectId: 'p',
      ).isEnabled,
      isFalse,
    );
  });

  test('never prints the API key', () {
    expect(full.toString(), 'PushSettings(example-project)');
    expect(const PushSettings.disabled().toString(), 'PushSettings(off)');
  });

  test('value equality', () {
    expect(
      full,
      const PushSettings(
        apiKey: 'AIza-secret-looking',
        appId: '1:1234:android:abcd',
        messagingSenderId: '1234',
        projectId: 'example-project',
      ),
    );
    expect(full.hashCode, isNot(const PushSettings.disabled().hashCode));
    expect(full, isNot(const PushSettings.disabled()));
  });
}
