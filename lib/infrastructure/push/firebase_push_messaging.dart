import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutterbase/application/ports/push_messaging.dart';
import 'package:flutterbase/domain/value_objects/push_settings.dart';
import 'package:flutterbase/infrastructure/push/fid_registrations.dart';

/// [PushMessaging] on `firebase_messaging`
/// (docs/adr/0010-notifications-through-fcm.md).
///
/// Firebase is started from [PushSettings] (the `FIREBASE_*` dart-defines)
/// rather than from a `google-services.json`: the template commits no Firebase
/// project, and a build without the settings never touches the plugin.
///
/// The server sends *notification* messages (title and body), which Android
/// shows by itself while the app is in the background — no background handler
/// is needed. In the foreground Android shows nothing; [foregroundMessages]
/// lets the app refresh its bell instead.
///
/// The device is addressed by its Firebase Installation ID (FID), not by a
/// registration token (docs/adr/0013-notify-by-installation-id.md): the
/// manifest turns the FID mode on, which makes `getToken()` unusable.
final class FirebasePushMessaging implements PushMessaging {
  FirebasePushMessaging._(this._messaging)
    : _fids = FidRegistrations(_messaging.onRegistered, _messaging.register);

  final FirebaseMessaging _messaging;
  final FidRegistrations _fids;

  /// Starts Firebase with [settings]. Throws what the plugin throws; the
  /// caller decides whether the app goes on without notifications.
  static Future<FirebasePushMessaging> start(PushSettings settings) async {
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: settings.apiKey,
        appId: settings.appId,
        messagingSenderId: settings.messagingSenderId,
        projectId: settings.projectId,
      ),
    );
    return FirebasePushMessaging._(FirebaseMessaging.instance);
  }

  @override
  Future<bool> requestPermission() async {
    final settings = await _messaging.requestPermission();
    return switch (settings.authorizationStatus) {
      AuthorizationStatus.authorized || AuthorizationStatus.provisional => true,
      AuthorizationStatus.denied ||
      AuthorizationStatus.deniedPermanently ||
      AuthorizationStatus.notDetermined => false,
    };
  }

  /// The FID (see [PushMessaging.token]).
  @override
  Future<String?> token() => _fids.current();

  @override
  Stream<String> get tokenRefreshes => _fids.changes;

  @override
  Stream<PushTap> get taps => FirebaseMessaging.onMessageOpenedApp.map(tapOf);

  @override
  Future<PushTap?> initialTap() async {
    final message = await _messaging.getInitialMessage();
    return message == null ? null : tapOf(message);
  }

  @override
  Stream<void> get foregroundMessages =>
      FirebaseMessaging.onMessage.map((_) {});

  /// The server's `data`: `notification_id` (a string, as FCM requires) and
  /// the optional `url`.
  static PushTap tapOf(RemoteMessage message) => pushTapFromData(message.data);
}

/// Reads the `data` of a message the paired web app sent.
PushTap pushTapFromData(Map<String, dynamic> data) {
  final id = data['notification_id'];
  final url = data['url'];
  return PushTap(
    noticeId: id is String ? int.tryParse(id) : (id is int ? id : null),
    linkUrl: url is String && url.trim().isNotEmpty ? url.trim() : null,
  );
}
