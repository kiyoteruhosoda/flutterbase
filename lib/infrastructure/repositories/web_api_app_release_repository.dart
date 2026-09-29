import 'package:flutterbase/domain/entities/app_release.dart';
import 'package:flutterbase/domain/errors/app_error.dart';
import 'package:flutterbase/domain/repositories/app_release_repository.dart';
import 'package:flutterbase/infrastructure/api/web_api_client.dart';

/// Reads the newest release from the paired web app
/// (`GET /api/app-release/latest`, fastapitemplate ADR-0048). The web app
/// answers from the `latest.json` the release pipeline publishes.
final class WebApiAppReleaseRepository implements AppReleaseRepository {
  const WebApiAppReleaseRepository(this._api);

  static const String path = '/api/app-release/latest';

  final WebApiClient _api;

  @override
  Future<AppRelease?> latest() async =>
      appReleaseFromJson(await _api.getJson(path));
}

/// Maps `{"latest": null | {"version", "build", "download_url", "built_at"}}`.
///
/// `{"latest": null}` is "nothing published" (null). A body of any other
/// shape throws [InfrastructureError]: the server and the app disagree on the
/// contract, which is worth a log line rather than a silent "up to date".
AppRelease? appReleaseFromJson(Object? json) {
  if (json is! Map<String, Object?> || !json.containsKey('latest')) {
    throw const InfrastructureError('app-release: unexpected body');
  }
  final latest = json['latest'];
  if (latest == null) return null;
  if (latest is! Map<String, Object?>) {
    throw const InfrastructureError('app-release: "latest" is not an object');
  }
  final version = latest['version'];
  final build = latest['build'];
  if (version is! String || version.trim().isEmpty || build is! int) {
    throw const InfrastructureError('app-release: no version/build');
  }
  final download = latest['download_url'];
  final builtAt = latest['built_at'];
  return AppRelease(
    version: version.trim(),
    build: build,
    downloadUrl: download is String ? _httpsUrl(download) : null,
    builtAt: builtAt is String ? DateTime.tryParse(builtAt)?.toUtc() : null,
  );
}

/// Only an absolute https URL is worth offering as a download.
Uri? _httpsUrl(String raw) {
  final uri = Uri.tryParse(raw.trim());
  if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) return null;
  return uri;
}
