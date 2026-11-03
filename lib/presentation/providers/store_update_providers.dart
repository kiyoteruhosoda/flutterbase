import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutterbase/application/ports/store_update_gateway.dart';
import 'package:flutterbase/application/usecases/store_update/check_store_update_usecase.dart';
import 'package:flutterbase/application/usecases/store_update/download_store_update_usecase.dart';
import 'package:flutterbase/application/usecases/store_update/install_store_update_usecase.dart';
import 'package:flutterbase/presentation/providers/app_providers.dart';

// ─── Use-case seams ────────────────────────────────────────────────────────
//
// Always overridden, with or without the sign-in: Google Play is asked
// directly, and a copy it did not install hears "nothing" (docs/adr/0012-*).

final Provider<CheckStoreUpdateUseCase> checkStoreUpdateUseCaseProvider =
    Provider<CheckStoreUpdateUseCase>((ref) {
      throw UnimplementedError(
        missingOverrideMessage('checkStoreUpdateUseCaseProvider'),
      );
    });

final Provider<DownloadStoreUpdateUseCase> downloadStoreUpdateUseCaseProvider =
    Provider<DownloadStoreUpdateUseCase>((ref) {
      throw UnimplementedError(
        missingOverrideMessage('downloadStoreUpdateUseCaseProvider'),
      );
    });

final Provider<InstallStoreUpdateUseCase> installStoreUpdateUseCaseProvider =
    Provider<InstallStoreUpdateUseCase>((ref) {
      throw UnimplementedError(
        missingOverrideMessage('installStoreUpdateUseCaseProvider'),
      );
    });

// ─── Screen state ──────────────────────────────────────────────────────────

/// Where an update of this app through Google Play stands, as the banner at
/// the top of the main screen draws it.
enum StoreUpdateStage {
  /// Nothing to offer — no newer build, or not installed from Play.
  none,

  /// A newer build is out; the person has not asked for it yet.
  available,

  /// The person agreed and Play is fetching it in the background.
  downloading,

  /// Downloaded; installing restarts the app.
  downloaded,
}

final NotifierProvider<StoreUpdateNotifier, StoreUpdateStage>
storeUpdateProvider = NotifierProvider<StoreUpdateNotifier, StoreUpdateStage>(
  StoreUpdateNotifier.new,
);

/// Drives [storeUpdateProvider] (docs/adr/0012-*).
class StoreUpdateNotifier extends Notifier<StoreUpdateStage> {
  @override
  StoreUpdateStage build() => StoreUpdateStage.none;

  /// Asks Play again. The main screen calls this on its first frame and
  /// whenever the app comes back to the front: a build goes out while the
  /// person is elsewhere, and an app that stays in memory for days would
  /// otherwise never hear of it.
  Future<void> check() async {
    // A download in flight answers for itself when it finishes.
    if (state == StoreUpdateStage.downloading) return;
    final status = await ref.read(checkStoreUpdateUseCaseProvider).execute();
    if (!ref.mounted || state == StoreUpdateStage.downloading) return;
    state = switch (status) {
      StoreUpdateStatus.none => StoreUpdateStage.none,
      StoreUpdateStatus.available => StoreUpdateStage.available,
      StoreUpdateStatus.downloaded => StoreUpdateStage.downloaded,
    };
  }

  /// Starts the background download, after Play's own prompt.
  Future<void> download() async {
    if (state != StoreUpdateStage.available) return;
    state = StoreUpdateStage.downloading;
    final ready = await ref.read(downloadStoreUpdateUseCaseProvider).execute();
    if (!ref.mounted) return;
    // Declined, or Play could not fetch it: offer it again, so the way to the
    // new build is still there.
    state = ready ? StoreUpdateStage.downloaded : StoreUpdateStage.available;
  }

  /// Installs the downloaded build. Play restarts the app.
  Future<void> install() async {
    if (state != StoreUpdateStage.downloaded) return;
    await ref.read(installStoreUpdateUseCaseProvider).execute();
  }
}
