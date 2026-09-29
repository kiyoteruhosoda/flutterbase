import 'package:flutterbase/domain/repositories/dismissed_update_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stores the build number whose update banner was closed in
/// [SharedPreferences].
final class SharedPreferencesDismissedUpdateRepository
    implements DismissedUpdateRepository {
  const SharedPreferencesDismissedUpdateRepository(this._prefs);

  static const String key = 'update_notice.dismissed_build';

  final SharedPreferences _prefs;

  @override
  int? get() => _prefs.getInt(key);

  @override
  Future<void> save(int build) async {
    await _prefs.setInt(key, build);
  }
}
