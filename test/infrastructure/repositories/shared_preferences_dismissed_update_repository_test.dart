import 'package:flutter_test/flutter_test.dart';
import 'package:flutterbase/infrastructure/repositories/shared_preferences_dismissed_update_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  group('SharedPreferencesDismissedUpdateRepository', () {
    test('nothing is dismissed at first', () {
      expect(SharedPreferencesDismissedUpdateRepository(prefs).get(), isNull);
    });

    test('the dismissed build survives a restart', () async {
      await SharedPreferencesDismissedUpdateRepository(prefs).save(356);
      expect(SharedPreferencesDismissedUpdateRepository(prefs).get(), 356);
    });

    test('a later dismissal replaces the earlier one', () async {
      final repo = SharedPreferencesDismissedUpdateRepository(prefs);
      await repo.save(356);
      await repo.save(360);
      expect(repo.get(), 360);
    });
  });
}
