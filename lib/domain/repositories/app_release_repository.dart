import 'package:flutterbase/domain/entities/app_release.dart';

/// Where the newest release of this app is announced.
///
/// Implementations live in `infrastructure/repositories/` (the paired web
/// app's `GET /api/app-release/latest`).
abstract interface class AppReleaseRepository {
  /// The newest release, or null when none has been published.
  Future<AppRelease?> latest();
}
