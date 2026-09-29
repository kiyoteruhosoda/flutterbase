/// The newest release of this app that the paired web app knows about.
///
/// Read from the web app's `GET /api/app-release/latest`, which in turn reads
/// the `latest.json` the release pipeline publishes next to the APK
/// (docs/adr/0009-update-notice-and-server-notices.md).
///
/// [build] is what decides "newer": it is the Android versionCode the release
/// build is stamped with (`--build-number`, the same value as
/// `BuildInfo.buildNumber`), and it only ever goes up. [version] is only shown.
final class AppRelease {
  const AppRelease({
    required this.version,
    required this.build,
    this.downloadUrl,
    this.builtAt,
  });

  /// Display version, e.g. `1.53.0`.
  final String version;

  /// Build number (Android versionCode), e.g. `356`.
  final int build;

  /// Where the APK can be downloaded, or null when the server has no link.
  final Uri? downloadUrl;

  /// When the release was built (UTC), when known.
  final DateTime? builtAt;

  /// True when this release is newer than the installed [installedBuild].
  bool isNewerThan(int installedBuild) => build > installedBuild;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppRelease &&
          other.version == version &&
          other.build == build &&
          other.downloadUrl == downloadUrl &&
          other.builtAt == builtAt);

  @override
  int get hashCode => Object.hash(version, build, downloadUrl, builtAt);

  @override
  String toString() => 'AppRelease($version+$build)';
}
