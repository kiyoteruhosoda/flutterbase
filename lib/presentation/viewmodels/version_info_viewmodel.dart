import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

class VersionInfo {
  const VersionInfo({
    required this.appName,
    required this.packageName,
    required this.version,
    required this.buildNumber,
    required this.buildSignature,
  });

  final String appName;
  final String packageName;
  final String version;
  final String buildNumber;
  final String buildSignature;

  String get fullVersion => '$version+$buildNumber';
}

sealed class VersionInfoState {}

class VersionInfoLoading implements VersionInfoState {
  const VersionInfoLoading();
}

class VersionInfoLoaded implements VersionInfoState {
  const VersionInfoLoaded(this.info);
  final VersionInfo info;
}

class VersionInfoError implements VersionInfoState {
  const VersionInfoError(this.message);
  final String message;
}

class VersionInfoViewModel extends StateNotifier<VersionInfoState> {
  VersionInfoViewModel() : super(const VersionInfoLoading()) {
    _load();
  }

  Future<void> _load() async {
    try {
      final info = await PackageInfo.fromPlatform();
      state = VersionInfoLoaded(
        VersionInfo(
          appName: info.appName,
          packageName: info.packageName,
          version: info.version,
          buildNumber: info.buildNumber,
          buildSignature: info.buildSignature,
        ),
      );
    } catch (e) {
      state = VersionInfoError(e.toString());
    }
  }

  Future<void> refresh() => _load();
}

final versionInfoViewModelProvider =
    StateNotifierProvider.autoDispose<VersionInfoViewModel, VersionInfoState>(
  (ref) => VersionInfoViewModel(),
);
