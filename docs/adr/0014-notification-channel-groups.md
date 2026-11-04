# 0014. 通知の分類（チャンネル）を、名前の付いたまとまり（チャンネルグループ）に入れて作る

- 状態: 採用
- 日付: 2026-11-04
- 関係するもの: [0010](0010-notifications-through-fcm.md)、[0013](0013-notify-by-installation-id.md)、
  noticeapp ADR-0015（同じやり方の先例）、fastapitemplate ADR-0049（通知を送る側）

## 文脈

端末の「設定 → アプリ → 通知」を開くと、雛形から作ったアプリの通知が、見出しの無い
「その他（Other）」の下の「Miscellaneous」に並んでいた。

- 雛形は自分で分類を 1 つも作っておらず、AndroidManifest に `default_notification_channel_id` も
  無かった。対の Web アプリ（fastapitemplate の `fcm_sender`）も `android.notification.channel_id` を
  送らない。そのため FCM は自前の予備の分類 `fcm_fallback_notification_channel`（名前は
  「Miscellaneous」）を作って出していた
- Android は、まとまりに入っていない分類を見出し無しの「その他」に並べる

## 決定

1. **まとまり `app` を作り、その中に分類を作る。** 見出しはアプリ名（`AppLocalizations.appName`）。
   雛形の分類は `server_notices`（「お知らせ」／Notices、説明「Web 版から届くお知らせ」、
   重さは既定＝音あり・画面上の帯なし）だけ。flutter_local_notifications の
   `createNotificationChannelGroup` を**分類より先に**呼び、各分類は `groupId` でまとまりを指す
2. **AndroidManifest の `default_notification_channel_id` を `server_notices` にする。** サーバーが
   分類を指定しない通知はここに出る。試験が `NotificationChannelCatalog.serverNoticesChannelId` と
   揃っているかを見る
3. **FCM の予備の分類 `fcm_fallback_notification_channel` は消す**（持ち主の決定）。今まで届いた
   アプリでは「その他」に残り続けるため。消しても、FCM は要るときにまた作る
4. **名前はアプリ内の言語（ja / en）で付け、言語を替えたら付け直す。** メイン画面が起動時と、
   言語が替わったときにだけ作り直す（`createNotificationChannel` は既にある分類の名前を書き換える）
5. **FCM が有効なときだけ作る。** FCM の無い版で空の分類を設定画面に出さない
6. **分類の一覧は 1 か所（`lib/presentation/notifications/notification_channel_catalog.dart`）。**
   派生アプリはここに分類やまとまりを足す。id は出したら変えない。名前は中身が分かるものにし、
   他の分類の名前を使い回さない（持ち主「warn とか使い回さないでほしい」）

## 理由

- 見出しがアプリ名なら、派生アプリは名前（`appName`）を変えるだけで見出しも替わる。分類が増えたら
  まとまりを分けて名前を付けられる
- 名前の訳は画面の文言と同じ `AppLocalizations` に置く（CLAUDE.md の i18n の方針）。分類の id と
  まとまりの id は言葉に依らない
- 分類を作るのに通知の許可も、プラグインの `initialize` も要らない。雛形は自分では通知を出さない
  （FCM が出す）ので、作るだけにした

## 影響

- 依存に `flutter_local_notifications`（Infrastructure だけ。`tool/check_architecture.dart` が見る）。
  そのため Android で `coreLibraryDesugaring`（`desugar_jdk_libs`）を有効にした
- 派生アプリは取り込むと、端末の設定で通知がアプリ名の下の「お知らせ」に移る。分類ごとの人の設定は
  新しい分類では初めからになる（「Miscellaneous」で切っていた人は、もう一度切る必要がある）
- サーバーが分類を指定するようになったら（`android.notification.channel_id`）、その id もここで作る
