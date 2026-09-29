/// Where a notice from the server asks to be shown.
///
/// The server may name channels the app does not handle (`webpush`, later
/// `fcm`); those are dropped when reading, so they never reach this enum.
enum NoticeChannel {
  /// A banner at the top of the main screen until dismissed.
  banner,

  /// An entry in the bell's list, counted in its unread badge.
  bell,
}

/// One notice the paired web app sent to the signed-in person
/// (`GET /api/notifications`).
///
/// Times are UTC. The entity never reads the clock: the moment a notice is
/// read or dismissed is passed in by the caller.
final class AppNotice {
  const AppNotice({
    required this.id,
    required this.title,
    required this.body,
    required this.channels,
    required this.sentAt,
    this.linkUrl,
    this.readAt,
    this.dismissedAt,
  });

  final int id;
  final String title;
  final String body;

  /// Absolute `https://…` or a path of the web app (`/items`), as sent.
  final String? linkUrl;

  final Set<NoticeChannel> channels;
  final DateTime sentAt;
  final DateTime? readAt;
  final DateTime? dismissedAt;

  bool get isRead => readAt != null;

  /// Listed under the bell.
  bool get isInBell => channels.contains(NoticeChannel.bell);

  /// Still wants its banner shown.
  bool get wantsBanner =>
      channels.contains(NoticeChannel.banner) && dismissedAt == null;

  /// Counted in the bell's unread badge.
  bool get countsAsUnread => isInBell && !isRead;

  /// Where tapping the notice leads, or null when it leads nowhere.
  ///
  /// The app has no route for the web app's paths, so a path (`/items`) is
  /// resolved against [webBaseUrl] and opened in the browser like an absolute
  /// link. Only `https` leaves the app: anything else (`javascript:`, plain
  /// `http:`, a path without the leading slash) is refused.
  Uri? linkTarget(Uri webBaseUrl) {
    final raw = linkUrl?.trim();
    if (raw == null || raw.isEmpty) return null;
    if (raw.startsWith('/') && !raw.startsWith('//')) {
      return webBaseUrl.resolve(raw);
    }
    final uri = Uri.tryParse(raw);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) return null;
    return uri;
  }

  /// This notice as read at [at] (unchanged when it already was).
  AppNotice markedRead(DateTime at) => isRead ? this : _copy(readAt: at);

  /// This notice as dismissed at [at]. Dismissing also reads it, as on the
  /// server.
  AppNotice markedDismissed(DateTime at) =>
      _copy(readAt: readAt ?? at, dismissedAt: dismissedAt ?? at);

  AppNotice _copy({DateTime? readAt, DateTime? dismissedAt}) => AppNotice(
    id: id,
    title: title,
    body: body,
    linkUrl: linkUrl,
    channels: channels,
    sentAt: sentAt,
    readAt: readAt ?? this.readAt,
    dismissedAt: dismissedAt ?? this.dismissedAt,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppNotice &&
          other.id == id &&
          other.title == title &&
          other.body == body &&
          other.linkUrl == linkUrl &&
          other.channels.length == channels.length &&
          other.channels.containsAll(channels) &&
          other.sentAt == sentAt &&
          other.readAt == readAt &&
          other.dismissedAt == dismissedAt);

  @override
  int get hashCode => Object.hash(
    id,
    title,
    body,
    linkUrl,
    Object.hashAllUnordered(channels),
    sentAt,
    readAt,
    dismissedAt,
  );

  @override
  String toString() => 'AppNotice(#$id)';
}

/// The signed-in person's notices, newest first, with the bell's unread count.
///
/// [unreadCount] comes from the server (it may count notices beyond the page
/// [items] holds); the changes below adjust it the way the server does, so the
/// badge is right without a reload.
final class AppNoticeInbox {
  const AppNoticeInbox({required this.items, required this.unreadCount});

  /// Nothing to show — before the first load, and after signing out.
  const AppNoticeInbox.empty() : items = const <AppNotice>[], unreadCount = 0;

  final List<AppNotice> items;
  final int unreadCount;

  /// The notices under the bell, newest first.
  List<AppNotice> get bellItems => items.where((n) => n.isInBell).toList();

  /// The newest notice still wanting its banner, or null.
  AppNotice? get banner {
    for (final notice in items) {
      if (notice.wantsBanner) return notice;
    }
    return null;
  }

  /// The inbox after notice [id] was read at [at].
  AppNoticeInbox markedRead(int id, DateTime at) =>
      _replace(id, (n) => n.markedRead(at));

  /// The inbox after notice [id] was dismissed at [at].
  AppNoticeInbox markedDismissed(int id, DateTime at) =>
      _replace(id, (n) => n.markedDismissed(at));

  /// The inbox after every notice was read at [at].
  AppNoticeInbox allMarkedRead(DateTime at) => AppNoticeInbox(
    items: items.map((n) => n.markedRead(at)).toList(),
    unreadCount: 0,
  );

  AppNoticeInbox _replace(int id, AppNotice Function(AppNotice) change) {
    var unread = unreadCount;
    final changed = <AppNotice>[];
    for (final notice in items) {
      if (notice.id != id) {
        changed.add(notice);
        continue;
      }
      final next = change(notice);
      if (notice.countsAsUnread && !next.countsAsUnread) unread--;
      changed.add(next);
    }
    return AppNoticeInbox(items: changed, unreadCount: unread < 0 ? 0 : unread);
  }
}
