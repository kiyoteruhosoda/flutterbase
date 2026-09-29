import 'package:flutterbase/domain/entities/app_notice.dart';
import 'package:flutterbase/domain/errors/app_error.dart';
import 'package:flutterbase/domain/repositories/app_notice_repository.dart';
import 'package:flutterbase/infrastructure/api/web_api_client.dart';

/// The signed-in person's notices on the paired web app
/// (`/api/notifications`, fastapitemplate ADR-0047).
final class WebApiAppNoticeRepository implements AppNoticeRepository {
  const WebApiAppNoticeRepository(this._api);

  static const String path = '/api/notifications';

  final WebApiClient _api;

  @override
  Future<AppNoticeInbox> list() async =>
      appNoticeInboxFromJson(await _api.getJson(path));

  @override
  Future<void> markRead(int id) => _api.post('$path/$id/read');

  @override
  Future<void> markAllRead() => _api.post('$path/read-all');

  @override
  Future<void> dismiss(int id) => _api.post('$path/$id/dismiss');
}

/// Maps `{"items": [...], "unread_count": n}`.
///
/// A malformed body throws [InfrastructureError]; a malformed *item* is
/// skipped, so one notice the app cannot read does not hide the others.
AppNoticeInbox appNoticeInboxFromJson(Object? json) {
  if (json is! Map<String, Object?>) {
    throw const InfrastructureError('notifications: unexpected body');
  }
  final items = json['items'];
  final unread = json['unread_count'];
  if (items is! List<Object?> || unread is! int) {
    throw const InfrastructureError('notifications: no items/unread_count');
  }
  return AppNoticeInbox(
    items: items.map(appNoticeFromJson).whereType<AppNotice>().toList(),
    unreadCount: unread < 0 ? 0 : unread,
  );
}

/// One item of `/api/notifications`, or null when it cannot be read.
///
/// Channels the app does not handle (`webpush`, …) are dropped.
AppNotice? appNoticeFromJson(Object? json) {
  if (json is! Map<String, Object?>) return null;
  final id = json['id'];
  final title = json['title'];
  final body = json['body'];
  final sentAt = _time(json['sent_at']);
  if (id is! int || title is! String || body is! String || sentAt == null) {
    return null;
  }
  final channels = json['channels'];
  final link = json['link_url'];
  return AppNotice(
    id: id,
    title: title,
    body: body,
    linkUrl: link is String && link.trim().isNotEmpty ? link.trim() : null,
    channels: <NoticeChannel>{
      if (channels is List<Object?>)
        for (final name in channels)
          for (final channel in NoticeChannel.values)
            if (channel.name == name) channel,
    },
    sentAt: sentAt,
    readAt: _time(json['read_at']),
    dismissedAt: _time(json['dismissed_at']),
  );
}

DateTime? _time(Object? value) =>
    value is String ? DateTime.tryParse(value)?.toUtc() : null;
