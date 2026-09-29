import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutterbase/application/ports/push_messaging.dart';
import 'package:flutterbase/domain/value_objects/push_settings.dart';

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
final class FirebasePushMessaging implements PushMessaging {
  FirebasePushMessaging._(this._messaging);

  final FirebaseMessaging _messaging;

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

  @override
  Future<String?> token() => _messaging.getToken();

  @override
  Stream<String> get tokenRefreshes => _messaging.onTokenRefresh;

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
