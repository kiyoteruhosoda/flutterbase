import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutterbase/application/usecases/notices/dismiss_notice_usecase.dart';
import 'package:flutterbase/application/usecases/notices/list_notices_usecase.dart';
import 'package:flutterbase/application/usecases/notices/mark_all_notices_read_usecase.dart';
import 'package:flutterbase/application/usecases/notices/mark_notice_read_usecase.dart';
import 'package:flutterbase/application/usecases/notices/open_notice_link_usecase.dart';
import 'package:flutterbase/domain/entities/app_notice.dart';
import 'package:flutterbase/presentation/providers/app_providers.dart';
import 'package:flutterbase/presentation/providers/app_update_providers.dart';
import 'package:flutterbase/presentation/providers/auth_providers.dart';

// ─── Use-case seams ────────────────────────────────────────────────────────
//
// Overridden only when the sign-in is on: notices are the signed-in person's,
// read from the paired web app. Nothing reads them otherwise.

final Provider<ListNoticesUseCase> listNoticesUseCaseProvider =
    Provider<ListNoticesUseCase>((ref) {
      throw UnimplementedError(
        missingOverrideMessage('listNoticesUseCaseProvider'),
      );
    });

final Provider<MarkNoticeReadUseCase> markNoticeReadUseCaseProvider =
    Provider<MarkNoticeReadUseCase>((ref) {
      throw UnimplementedError(
        missingOverrideMessage('markNoticeReadUseCaseProvider'),
      );
    });

final Provider<MarkAllNoticesReadUseCase> markAllNoticesReadUseCaseProvider =
    Provider<MarkAllNoticesReadUseCase>((ref) {
      throw UnimplementedError(
        missingOverrideMessage('markAllNoticesReadUseCaseProvider'),
      );
    });

final Provider<DismissNoticeUseCase> dismissNoticeUseCaseProvider =
    Provider<DismissNoticeUseCase>((ref) {
      throw UnimplementedError(
        missingOverrideMessage('dismissNoticeUseCaseProvider'),
      );
    });

final Provider<OpenNoticeLinkUseCase> openNoticeLinkUseCaseProvider =
    Provider<OpenNoticeLinkUseCase>((ref) {
      throw UnimplementedError(
        missingOverrideMessage('openNoticeLinkUseCaseProvider'),
      );
    });

// ─── Screen state ──────────────────────────────────────────────────────────

/// The signed-in person's notices: the bell's list and badge, and the banner.
final NotifierProvider<NoticeInboxNotifier, AppNoticeInbox>
noticeInboxProvider = NotifierProvider<NoticeInboxNotifier, AppNoticeInbox>(
  NoticeInboxNotifier.new,
);

/// Loads the notices and records reading and dismissing them
/// (docs/adr/0009-update-notice-and-server-notices.md).
///
/// Changes reach the state only after the server accepted them, as elsewhere
/// in the app: a badge that dropped for a read the server never recorded
/// would come back on the next load. A failed request leaves the state as it
/// was and answers false; the use case has logged why.
class NoticeInboxNotifier extends Notifier<AppNoticeInbox> {
  /// Automatic reloads closer together than this are skipped.
  static const Duration minInterval = Duration(minutes: 5);

  DateTime? _lastLoad;

  @override
  AppNoticeInbox build() => const AppNoticeInbox.empty();

  DateTime _now() => ref.read(clockProvider)();

  /// Reloads unless the last load was under [minInterval] ago ([force] skips
  /// that — opening the bell always reloads). Answers false when the load
  /// failed; true otherwise, including when it was skipped.
  Future<bool> refresh({bool force = false}) async {
    if (!ref.read(signInSettingsProvider).isEnabled) return true;
    final now = _now();
    final last = _lastLoad;
    if (!force && last != null && now.difference(last) < minInterval) {
      return true;
    }
    _lastLoad = now;

    if (!await isSignedIn(ref)) {
      if (ref.mounted) state = const AppNoticeInbox.empty();
      return true;
    }
    try {
      final inbox = await ref.read(listNoticesUseCaseProvider).execute();
      if (ref.mounted) state = inbox;
      return true;
    } on Exception {
      // The next trigger may try again instead of waiting out the interval.
      _lastLoad = null;
      return false;
    }
  }

  /// Records [notice] as read.
  Future<bool> markRead(AppNotice notice) => _apply(
    () => ref.read(markNoticeReadUseCaseProvider).execute(notice),
    (inbox) => inbox.markedRead(notice.id, _now()),
  );

  /// Records every notice as read (「すべて既読」).
  Future<bool> markAllRead() => _apply(
    () => ref.read(markAllNoticesReadUseCaseProvider).execute(),
    (inbox) => inbox.allMarkedRead(_now()),
  );

  /// Closes [notice]'s banner (which also reads it).
  Future<bool> dismiss(AppNotice notice) => _apply(
    () => ref.read(dismissNoticeUseCaseProvider).execute(notice),
    (inbox) => inbox.markedDismissed(notice.id, _now()),
  );

  /// The bell's tap: reads [notice] and opens its link, if it has one.
  ///
  /// Answers false only when there was a link and it could not be opened. A
  /// failed read does not stop the link: the person asked to go there.
  Future<bool> open(AppNotice notice) async {
    await markRead(notice);
    return _openLink(notice);
  }

  /// The banner's tap: opens the link and closes the banner.
  Future<bool> openBanner(AppNotice notice) async {
    final opened = await _openLink(notice);
    await dismiss(notice);
    return opened;
  }

  /// Forgets everything (after a sign-out) and lets the next load run.
  void clear() {
    _lastLoad = null;
    state = const AppNoticeInbox.empty();
  }

  Future<bool> _openLink(AppNotice notice) async {
    if (notice.linkUrl == null) return true;
    return ref.read(openNoticeLinkUseCaseProvider).execute(notice);
  }

  Future<bool> _apply(
    Future<void> Function() request,
    AppNoticeInbox Function(AppNoticeInbox) change,
  ) async {
    try {
      await request();
    } on Exception {
      return false;
    }
    if (ref.mounted) state = change(state);
    return true;
  }
}
