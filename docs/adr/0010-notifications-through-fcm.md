# ADR-0010: 端末への通知は FCM で受け、Firebase の値は --dart-define で渡す

- 日付: 2026-09-29
- 状態: 承認
- 関連: [ADR-0007](0007-optional-assay-sign-in.md) / [ADR-0009](0009-update-notice-and-server-notices.md) /
  fastapitemplate ADR-0049 / 課題 task.nolumia.com #59

## 文脈

ADR-0009 で、対の Web アプリのお知らせをベルと上部のバナーに出すようにした。ただしアプリを開いて
いないと気付けない。Web アプリの「端末への通知」はブラウザ（Web Push）にしか届かなかった。
Android のアプリへ通知を届ける経路は、事実上 Firebase Cloud Messaging（FCM）しかない。

## 決定

1. **FCM で受ける（`firebase_messaging`）。** 対の Web アプリ（fastapitemplate ADR-0049）が
   `notification`（題・本文）と `data`（`notification_id`・`url`）を送る。背景では Android が
   そのまま出し、押されたらお知らせを既読にして行き先を開き、ベルを取り直す。前面で届いたら
   ベルを取り直すだけ（Android は前面では何も出さない）。
2. **Firebase の値は `--dart-define` で渡す**（`FIREBASE_API_KEY` / `FIREBASE_APP_ID` /
   `FIREBASE_MESSAGING_SENDER_ID` / `FIREBASE_PROJECT_ID`）。`google-services.json` と Google の
   Gradle プラグインは使わず、`Firebase.initializeApp(options: …)` で始める。
3. **4 つが揃い、かつサインインが有効なときだけ Firebase を始める。** どちらかが無ければプラグインを
   一切呼ばない（通知の許可も求めない）。始められなかったら記録してアプリは続ける。
4. **端末の登録は起動のたび・サインインのたび・トークンが替わるたび**
   （`POST /api/notifications/device/register`）。**サインアウトの前に**外す（`…/unregister`。本人の
   トークンが要るため）。通知の許可を断られたら登録しない。

## 理由

- **`google-services.json` を置かない（決定 2）**: テンプレートは特定の Firebase プロジェクトを持たない。
  置くと派生のアプリがそのまま他人のプロジェクトへ登録しに行く。値を `--dart-define` にすれば、
  サインイン（ADR-0007）と同じく「渡したときだけ有効」にでき、配布の段で値を差し込める。
- **サインイン必須（決定 3）**: 端末は「サインインしている人の端末」として登録する。人が決まらない
  端末へ送る宛先は、Web アプリ側に無い。
- **毎回登録（決定 4）**: FCM のトークンはアプリが閉じているあいだにも入れ替わる。「変わったときだけ」
  は取りこぼしても気付けない。

## 影響

- 依存に `firebase_core` / `firebase_messaging`（Infrastructure だけ。`tool/check_architecture.dart` が見る）。
- ⚠ Firebase のプロジェクトは人が作る（Android アプリを登録し、値を控える）。手順は
  `docs/CUSTOMISATION.md`、サーバー側の鍵は fastapitemplate の `docs/OPERATIONS.md`。
- 通知の中身は Google を経由する（fastapitemplate ADR-0049）。
