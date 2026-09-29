import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutterbase/domain/entities/app_notice.dart';
import 'package:flutterbase/presentation/l10n/app_localizations.dart';
import 'package:flutterbase/presentation/providers/notice_providers.dart';
import 'package:flutterbase/presentation/theme/theme.dart';

/// Opens the bell's list of notices as a bottom sheet.
Future<void> showNoticeListSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => const NoticeListSheet(),
  );
}

/// The notices under the bell, newest first; unread ones stand out.
///
/// Opening it always reloads, so the list is current even between the
/// automatic reloads. Tapping a notice reads it and opens its link in the
/// browser.
class NoticeListSheet extends ConsumerStatefulWidget {
  const NoticeListSheet({super.key});

  @override
  ConsumerState<NoticeListSheet> createState() => _NoticeListSheetState();
}

class _NoticeListSheetState extends ConsumerState<NoticeListSheet> {
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _retry() {
    setState(() {
      _loading = true;
      _failed = false;
    });
    return _load();
  }

  Future<void> _load() async {
    final ok = await ref
        .read(noticeInboxProvider.notifier)
        .refresh(force: true);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _failed = !ok;
    });
  }

  Future<void> _open(AppNotice notice) async {
    final messenger = ScaffoldMessenger.of(context);
    final failed = AppLocalizations.of(context).noticeOpenFailed;
    final opened = await ref.read(noticeInboxProvider.notifier).open(notice);
    if (!opened) messenger.showSnackBar(SnackBar(content: Text(failed)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final inbox = ref.watch(noticeInboxProvider);
    final items = inbox.bellItems;
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.75,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.pageMargin,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.noticesTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                TextButton(
                  onPressed: inbox.unreadCount == 0
                      ? null
                      : () => unawaited(
                          ref.read(noticeInboxProvider.notifier).markAllRead(),
                        ),
                  child: Text(l10n.noticesMarkAllRead),
                ),
              ],
            ),
          ),
          if (_loading)
            const LinearProgressIndicator()
          else
            const SizedBox(height: 4),
          if (_failed)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.pageMargin),
              child: Row(
                children: [
                  Expanded(child: Text(l10n.noticesLoadFailed)),
                  TextButton(
                    onPressed: () => unawaited(_retry()),
                    child: Text(l10n.commonRetry),
                  ),
                ],
              ),
            ),
          if (items.isEmpty && !_loading && !_failed)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Text(l10n.noticesEmpty, textAlign: TextAlign.center),
            ),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              itemCount: items.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) => _NoticeTile(
                notice: items[index],
                onTap: () => unawaited(_open(items[index])),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoticeTile extends StatelessWidget {
  const _NoticeTile({required this.notice, required this.onTap});

  final AppNotice notice;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final unread = !notice.isRead;
    return ListTile(
      key: ValueKey<String>('notice-${notice.id}'),
      onTap: onTap,
      leading: SizedBox(
        width: AppSpacing.iconLg,
        child: unread
            ? Semantics(
                label: l10n.noticesUnread,
                child: Icon(
                  Icons.circle,
                  size: AppSpacing.sm,
                  color: theme.colorScheme.primary,
                ),
              )
            : null,
      ),
      title: Text(
        notice.title,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: unread ? FontWeight.w700 : FontWeight.w400,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (notice.body.trim().isNotEmpty) Text(notice.body),
          const SizedBox(height: AppSpacing.xs),
          Text(
            formatNoticeTime(context, notice.sentAt),
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
      trailing: notice.linkUrl == null
          ? null
          : const Icon(Icons.open_in_new, size: AppSpacing.iconMd),
    );
  }
}

/// [utc] in the device's time zone, in the locale's short date and time.
///
/// The server and the app keep UTC; only here, at the screen, does it become
/// local time (CLAUDE.md §基本方針 8).
String formatNoticeTime(BuildContext context, DateTime utc) {
  final local = utc.toLocal();
  final material = MaterialLocalizations.of(context);
  final time = material.formatTimeOfDay(
    TimeOfDay.fromDateTime(local),
    alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
  );
  return '${material.formatShortDate(local)} $time';
}
