import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutterbase/application/usecases/app_info/get_app_info_usecase.dart';
import 'package:flutterbase/domain/entities/app_info.dart';
import 'package:flutterbase/presentation/providers/app_providers.dart';

// ─── Use-case seam ─────────────────────────────────────────────────────────

final Provider<GetAppInfoUseCase> getAppInfoUseCaseProvider =
    Provider<GetAppInfoUseCase>((ref) {
      throw UnimplementedError(
        missingOverrideMessage('getAppInfoUseCaseProvider'),
      );
    });

// ─── Screen state ──────────────────────────────────────────────────────────

/// Version and build metadata, shared by the About and Debug screens.
///
/// One provider rather than one per screen: both show the same numbers read
/// the same way, so the second screen to open reuses what the first loaded.
/// `ref.invalidate(appInfoProvider)` is what a retry button calls.
///
/// Riverpod's automatic retry is switched off: build metadata does not become
/// readable by waiting, and both screens already offer an explicit Retry — so
/// a failure should show once rather than re-run ten times in the background.
final FutureProvider<AppInfo> appInfoProvider = FutureProvider<AppInfo>((
  ref,
) async {
  final logger = ref.read(appLoggerProvider);
  logger.debug('[AppInfo] load start');
  try {
    final info = await ref.read(getAppInfoUseCaseProvider).execute();
    logger.debug('[AppInfo] load success — v${info.version}');
    return info;
  } on Exception catch (e, st) {
    // Logged here and rethrown rather than wrapped: the failure reaches the
    // screen as an [AsyncError], and the screen decides what a user sees.
    logger.error('[AppInfo] load failed', error: e, stackTrace: st);
    rethrow;
  }
}, retry: (retryCount, error) => null);
