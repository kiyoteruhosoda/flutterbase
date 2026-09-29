import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutterbase/presentation/l10n/app_localizations.dart';
import 'package:flutterbase/presentation/providers/auth_providers.dart';
import 'package:flutterbase/presentation/providers/notice_providers.dart';
import 'package:flutterbase/presentation/widgets/notices/notice_list_sheet.dart';

/// The header's bell: the unread badge, and the notice list on tap
/// (docs/adr/0009-update-notice-and-server-notices.md).
///
/// Notices belong to the signed-in person, so the bell is absent in a build
/// without the sign-in and while nobody is signed in — a bell that can never
/// ring is only noise.
class NoticeBellButton extends ConsumerWidget {
  const NoticeBellButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(signInSettingsProvider).isEnabled) {
      return const SizedBox.shrink();
    }
    if (ref.watch(accountProvider).value == null) {
      return const SizedBox.shrink();
    }
    final unread = ref.watch(noticeInboxProvider.select((i) => i.unreadCount));
    return IconButton(
      tooltip: AppLocalizations.of(context).commonNotifications,
      onPressed: () => unawaited(showNoticeListSheet(context)),
      icon: Badge(
        isLabelVisible: unread > 0,
        label: Text(unread > 99 ? '99+' : '$unread'),
        child: const Icon(Icons.notifications_outlined),
      ),
    );
  }
}
