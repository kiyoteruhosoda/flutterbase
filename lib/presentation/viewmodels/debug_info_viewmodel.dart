import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

class DebugInfo {
  const DebugInfo({
    required this.appVersion,
    required this.buildNumber,
    required this.packageName,
    required this.platform,
    required this.os,
    required this.osVersion,
    required this.locale,
    required this.flutterVersion,
    required this.dartVersion,
    required this.isDebugMode,
    required this.isProfileMode,
    required this.isReleaseMode,
    required this.screenSize,
    required this.devicePixelRatio,
    required this.textScaleFactor,
    required this.buildMode,
  });

  final String appVersion;
  final String buildNumber;
  final String packageName;
  final String platform;
  final String os;
  final String osVersion;
  final String locale;
  final String flutterVersion;
  final String dartVersion;
  final bool isDebugMode;
  final bool isProfileMode;
  final bool isReleaseMode;
  final String screenSize;
  final String devicePixelRatio;
  final String textScaleFactor;
  final String buildMode;
}

sealed class DebugInfoState {}

class DebugInfoLoading implements DebugInfoState {
  const DebugInfoLoading();
}

class DebugInfoLoaded implements DebugInfoState {
  const DebugInfoLoaded(this.info);
  final DebugInfo info;
}

class DebugInfoError implements DebugInfoState {
  const DebugInfoError(this.message);
  final String message;
}

class DebugInfoViewModel extends StateNotifier<DebugInfoState> {
  DebugInfoViewModel(this._context)
      : super(const DebugInfoLoading()) {
    _load();
  }

  final BuildContext _context;

  Future<void> _load() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final mediaQuery = MediaQuery.of(_context);
      final locale = Localizations.localeOf(_context);

      String platformName;
      String osVersion;

      if (kIsWeb) {
        platformName = 'Web';
        osVersion = 'N/A';
      } else {
        platformName = Platform.operatingSystem;
        osVersion = Platform.operatingSystemVersion;
      }

      final buildMode = kDebugMode
          ? 'Debug'
          : kProfileMode
              ? 'Profile'
              : 'Release';

      state = DebugInfoLoaded(
        DebugInfo(
          appVersion: packageInfo.version,
          buildNumber: packageInfo.buildNumber,
          packageName: packageInfo.packageName,
          platform: platformName,
          os: platformName,
          osVersion: osVersion,
          locale: locale.toString(),
          flutterVersion: 'Flutter SDK',
          dartVersion: Platform.version.split(' ').first,
          isDebugMode: kDebugMode,
          isProfileMode: kProfileMode,
          isReleaseMode: kReleaseMode,
          screenSize:
              '${mediaQuery.size.width.toStringAsFixed(0)}x${mediaQuery.size.height.toStringAsFixed(0)}',
          devicePixelRatio: mediaQuery.devicePixelRatio.toStringAsFixed(2),
          textScaleFactor: mediaQuery.textScaler.toString(),
          buildMode: buildMode,
        ),
      );
    } catch (e) {
      state = DebugInfoError(e.toString());
    }
  }

  Future<void> refresh() => _load();
}

final debugInfoViewModelProvider = StateNotifierProvider.autoDispose
    .family<DebugInfoViewModel, DebugInfoState, BuildContext>(
  (ref, context) => DebugInfoViewModel(context),
);
