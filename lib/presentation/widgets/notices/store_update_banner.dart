import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutterbase/presentation/l10n/app_localizations.dart';
import 'package:flutterbase/presentation/providers/store_update_providers.dart';

/// Says so at the top of the main screen when Google Play has a newer build
/// of the app, and takes the person through downloading and installing it
/// (docs/adr/0012-*).
///
/// A banner in the page rather than a dialog: a new build is worth knowing
/// about, not worth stopping the person for. There is no way to put it away —
/// installing is what makes it go.
///
/// Shown by [NoticeBanner] ahead of everything else; draws nothing when there
/// is nothing to offer, which includes every copy not installed from Play.
class StoreUpdateBanner extends ConsumerWidget {
  const StoreUpdateBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stage = ref.watch(storeUpdateProvider);
    if (stage == StoreUpdateStage.none) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final notifier = ref.read(storeUpdateProvider.notifier);
    return MaterialBanner(
      key: const ValueKey<String>('store-update-banner'),
      leading: const Icon(Icons.system_update_outlined),
      content: Text(switch (stage) {
        StoreUpdateStage.downloaded => l10n.storeUpdateDownloaded,
        StoreUpdateStage.downloading => l10n.storeUpdateDownloading,
        _ => l10n.storeUpdateAvailable,
      }),
      actions: [
        switch (stage) {
          StoreUpdateStage.downloaded => TextButton(
            onPressed: () => unawaited(notifier.install()),
            child: Text(l10n.storeUpdateInstall),
          ),
          StoreUpdateStage.downloading => const Padding(
            padding: EdgeInsets.all(12),
            child: SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          _ => TextButton(
            onPressed: () => unawaited(notifier.download()),
            child: Text(l10n.storeUpdateDownload),
          ),
        },
      ],
    );
  }
}
