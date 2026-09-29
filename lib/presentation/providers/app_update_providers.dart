import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutterbase/application/usecases/app_update/check_for_update_usecase.dart';
import 'package:flutterbase/application/usecases/app_update/dismiss_update_usecase.dart';
import 'package:flutterbase/application/usecases/app_update/open_update_download_usecase.dart';
import 'package:flutterbase/domain/entities/app_release.dart';
import 'package:flutterbase/presentation/providers/app_providers.dart';
import 'package:flutterbase/presentation/providers/auth_providers.dart';

// ─── Use-case seams ────────────────────────────────────────────────────────
//
// Overridden only when the sign-in is on: the release is read from the paired
// web app as the signed-in person. Nothing reads them otherwise
// ([AppUpdateNotifier.refresh] stops first).

final Provider<CheckForUpdateUseCase> checkForUpdateUseCaseProvider =
    Provider<CheckForUpdateUseCase>((ref) {
      throw UnimplementedError(
        missingOverrideMessage('checkForUpdateUseCaseProvider'),
      );
    });

final Provider<DismissUpdateUseCase> dismissUpdateUseCaseProvider =
    Provider<DismissUpdateUseCase>((ref) {
      throw UnimplementedError(
        missingOverrideMessage('dismissUpdateUseCaseProvider'),
      );
    });

final Provider<OpenUpdateDownloadUseCase> openUpdateDownloadUseCaseProvider =
    Provider<OpenUpdateDownloadUseCase>((ref) {
      throw UnimplementedError(
        missingOverrideMessage('openUpdateDownloadUseCaseProvider'),
      );
    });

// ─── Screen state ──────────────────────────────────────────────────────────

/// The newer release to announce in the main screen's banner, or null.
final NotifierProvider<AppUpdateNotifier, AppRelease?> availableUpdateProvider =
    NotifierProvider<AppUpdateNotifier, AppRelease?>(AppUpdateNotifier.new);

/// Checks for a newer build and holds the one to announce
/// (docs/adr/0009-update-notice-and-server-notices.md).
///
/// The main screen calls [refresh] on start, after a sign-in, and whenever
/// the app returns to the foreground; [minInterval] keeps the last of those
/// from asking the server on every glance at the app.
class AppUpdateNotifier extends Notifier<AppRelease?> {
  /// Automatic checks closer together than this are skipped.
  static const Duration minInterval = Duration(minutes: 5);

  DateTime? _lastCheck;

  @override
  AppRelease? build() => null;

  /// Asks the server unless the last check was under [minInterval] ago
  /// ([force] skips that). Nothing is shown without a sign-in.
  Future<void> refresh({bool force = false}) async {
    if (!ref.read(signInSettingsProvider).isEnabled) return;
    final now = ref.read(clockProvider)();
    final last = _lastCheck;
    if (!force && last != null && now.difference(last) < minInterval) return;
    _lastCheck = now;

    if (!await isSignedIn(ref)) {
      if (ref.mounted) state = null;
      return;
    }
    final release = await ref.read(checkForUpdateUseCaseProvider).execute();
    if (ref.mounted) state = release;
  }

  /// Closes the banner for this build; a newer build shows it again.
  Future<void> dismiss() async {
    final release = state;
    if (release == null) return;
    await ref.read(dismissUpdateUseCaseProvider).execute(release);
    if (ref.mounted) state = null;
  }

  /// Opens the download link in the browser. False when that failed.
  Future<bool> openDownload() async {
    final release = state;
    if (release == null) return false;
    return ref.read(openUpdateDownloadUseCaseProvider).execute(release);
  }

  /// Forgets the release (after a sign-out) and lets the next check run.
  void clear() {
    _lastCheck = null;
    state = null;
  }
}

/// Whether someone is signed in, answering false when that cannot be told.
///
/// The current value wins over `.future`: right after a sign-in (while the
/// account listener runs) `.future` may still answer the value from before.
Future<bool> isSignedIn(Ref ref) async {
  final current = ref.read(accountProvider);
  if (current.hasValue) return current.value != null;
  try {
    return await ref.read(accountProvider.future) != null;
  } on Exception {
    return false;
  }
}
