import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutterbase/domain/entities/app_notice.dart';
import 'package:flutterbase/domain/entities/app_release.dart';
import 'package:flutterbase/presentation/l10n/app_localizations.dart';
import 'package:flutterbase/presentation/providers/app_update_providers.dart';
import 'package:flutterbase/presentation/providers/notice_providers.dart';

/// The banner at the top of the main screen
/// (docs/adr/0009-update-notice-and-server-notices.md).
///
/// At most one banner shows: a newer build of the app wins over a notice from
/// the server, because an old build may be the reason a notice cannot be
/// acted on. With neither, this takes no space.
class NoticeBanner extends ConsumerWidget {
  const NoticeBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final update = ref.watch(availableUpdateProvider);
    if (update != null) return _UpdateBanner(release: update);
    final notice = ref.watch(noticeInboxProvider.select((i) => i.banner));
    if (notice != null) return _ServerNoticeBanner(notice: notice);
    return const SizedBox.shrink();
  }
}

class _UpdateBanner extends ConsumerWidget {
  const _UpdateBanner({required this.release});

  final AppRelease release;

  Future<void> _download(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final failed = AppLocalizations.of(context).updateOpenFailed;
    final opened = await ref
        .read(availableUpdateProvider.notifier)
        .openDownload();
    if (!opened) messenger.showSnackBar(SnackBar(content: Text(failed)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return MaterialBanner(
      key: const ValueKey<String>('update-banner'),
      leading: const Icon(Icons.system_update_outlined),
      content: Text(l10n.updateAvailable(release.version)),
      actions: [
        if (release.downloadUrl != null)
          TextButton(
            onPressed: () => unawaited(_download(context, ref)),
            child: Text(l10n.updateDownload),
          ),
        TextButton(
          onPressed: () =>
              unawaited(ref.read(availableUpdateProvider.notifier).dismiss()),
          child: Text(l10n.commonClose),
        ),
      ],
    );
  }
}

class _ServerNoticeBanner extends ConsumerWidget {
  const _ServerNoticeBanner({required this.notice});

  final AppNotice notice;

  Future<void> _open(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final failed = AppLocalizations.of(context).noticeOpenFailed;
    final opened = await ref
        .read(noticeInboxProvider.notifier)
        .openBanner(notice);
    if (!opened) messenger.showSnackBar(SnackBar(content: Text(failed)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    return MaterialBanner(
      key: ValueKey<String>('notice-banner-${notice.id}'),
      leading: const Icon(Icons.campaign_outlined),
      content: InkWell(
        onTap: notice.linkUrl == null
            ? null
            : () => unawaited(_open(context, ref)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              notice.title,
              style: textTheme.titleSmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (notice.body.trim().isNotEmpty)
              Text(
                notice.body,
                style: textTheme.bodyMedium,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () =>
              unawaited(ref.read(noticeInboxProvider.notifier).dismiss(notice)),
          child: Text(l10n.commonClose),
        ),
      ],
    );
  }
}
