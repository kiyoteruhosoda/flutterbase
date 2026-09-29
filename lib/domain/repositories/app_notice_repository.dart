import 'package:flutterbase/domain/entities/app_notice.dart';

/// The signed-in person's notices on the paired web app.
///
/// Implementations live in `infrastructure/repositories/` (the web app's
/// `/api/notifications`). Reading and dismissing are recorded on the server,
/// so a notice read in the app is read in the browser too.
abstract interface class AppNoticeRepository {
  /// The notices, newest first, with the bell's unread count.
  Future<AppNoticeInbox> list();

  /// Records notice [id] as read.
  Future<void> markRead(int id);

  /// Records every notice as read.
  Future<void> markAllRead();

  /// Records notice [id]'s banner as dismissed (which also reads it).
  Future<void> dismiss(int id);
}
