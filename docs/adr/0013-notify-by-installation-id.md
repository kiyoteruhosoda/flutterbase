# 0013. 通知のあて先を登録トークンから Firebase Installation ID（FID）へ移す

- 状態: 採用
- 日付: 2026-11-04
- 関係するもの: [0010](0010-notifications-through-fcm.md)（一部を置き換える）、
  fastapitemplate ADR-0049、flutterbase #22（firebase_core 5 ＋ firebase_messaging 17）

## 文脈

firebase_messaging 17 で `getToken()` と `onTokenRefresh` が非推奨になった。代わりは
`register()` と `onRegistered` で、渡されるのは登録トークンではなく **FID**。Firebase は送る側も
FID へ移すよう勧めている（HTTP v1 の `message.token` は非推奨、新しい `message.fid` を使う。
移る間は `token` の欄も FID を受け付ける）。持ち主が 2026-11-04 に「新しい方式に移る」と決めた。

## 決定

1. **Android の manifest に `firebase_messaging_installation_id_enabled=true` を置く。** これで
   `register()` が使えるようになり、`getToken()` は例外を投げるようになる（両方は混ぜられない）。
2. **起動・サインインのたびに `register()` を呼び、`onRegistered` で受けた FID をサーバーへ登録する。**
   FCM は登録済みでも `register()` のたびに同じ FID を返す。`onRegistered` は聞いていないときに
   届いた分を捨てるので、`FidRegistrations` が最初から聞いておく。頼まずに届いた別の FID は
   「替わった」として登録し直す（ADR-0010 決定 4 の「トークンが替わるたび」と同じ役）。
3. **登録の本文に `kind: "fid"` を足す**（`POST /api/notifications/device/register`）。サーバーは
   これで `message.fid` を使う。まだ `kind` を知らないサーバーは読み飛ばし、`message.token` で
   送る。移る間はそれでも届く。

## 影響

- ポートの `PushMessaging.token()` / `tokenRefreshes` は名前を変えず、中身を FID にした（派生アプリの
  手直しを小さくするため）。サーバーへ出す口（`DeviceRegistrationRepository`）も同じ名前のまま
- 更新前のアプリが登録したトークンは、サーバーに `kind=token` のまま残る。更新すると FID が別の行と
  して登録され、古い行は FCM が `UNREGISTERED` を返した時点でサーバーが消す
- iOS は作っていない。作るときは Info.plist に `FirebaseMessagingInstallationIdEnabled` を置く
