

## assay へのサインイン（任意）

雛形はサインインを持っているが、既定では出さない。使うときは**コードを直さず**、
ビルドに `--dart-define` を 3 つ渡す（`OIDC_ISSUER` / `OIDC_CLIENT_ID` / `APP_LINK_HOST`）。
手順と Web 側の条件は `docs/RELEASE.md` と `docs/adr/0007-optional-assay-sign-in.md`・`0008-auth-tab-sign-in.md`。
対の Web の API は `WebApiClient`（`lib/infrastructure/api/`）で呼ぶ。サインインした人の
アクセストークンを付け、401 なら 1 度だけ取り直す。派生アプリの API も、これを使う
リポジトリを Infrastructure に足す（例: `WebApiAppNoticeRepository`）。

新しい版の知らせとサーバーからのお知らせ（ADR-0009）は、サインインがあれば**そのまま動く**。
対の Web に `/api/app-release/latest` と `/api/notifications`（fastapitemplate ADR-0047 /
ADR-0048）が無ければ、何も出ない。

Google Play のアプリ内アップデート（ADR-0012）は、サインインが無くても**そのまま動く**。
Play から入れた版だけに出て、Web の「新しい版」より先に出る（バナーは 1 本）。
Play Console 側の設定は要らない。

メンテナンス画面（ADR-0011）も、サインインがあれば**そのまま動く**。`WebApiClient` を通した呼び出しが
edge の 503（`reason: maintenance` / `stopped`）を受けると全体にかぶさり、戻ると消える。
派生アプリの API も `WebApiClient` を通せば同じになる。

## 端末への通知（FCM。任意）

対の Web アプリの「端末への通知」を、このアプリでも受け取る（ADR-0010）。既定では Firebase を
一切始めない。使うときは**コードを直さず**、サインインの 3 つに加えて `--dart-define` を 4 つ渡す。

1. [Firebase コンソール](https://console.firebase.google.com/) でプロジェクトを作り、Android アプリを
   追加する（パッケージ名は `applicationId`）。`google-services.json` を落とす。
   ⚠ **リポジトリに置かない。** 中の値だけを使う:

   | `--dart-define` | `google-services.json` の場所 |
   | --- | --- |
   | `FIREBASE_API_KEY` | `client[].api_key[].current_key` |
   | `FIREBASE_APP_ID` | `client[].client_info.mobilesdk_app_id` |
   | `FIREBASE_MESSAGING_SENDER_ID` | `project_info.project_number` |
   | `FIREBASE_PROJECT_ID` | `project_info.project_id` |

2. 対の Web アプリに、同じプロジェクトのサービスアカウントの鍵を置く
   （fastapitemplate の `docs/OPERATIONS.md`「スマホアプリへ通知（FCM）を送りたいとき」）。
3. サインインすると、初回だけ通知の許可を聞かれる。許可すると端末が登録され、Web の管理画面で
   「端末への通知」を選んだお知らせが届く。押すと既読になり、行き先がブラウザで開く。

### 通知の分類（チャンネル）を足す

端末の「設定 → アプリ → 通知」では、通知が**アプリ名の見出し（まとまり＝チャンネルグループ）**の下に
**分類（チャンネル）**ごとに並び、人が分類ごとに切ったり静かにしたりできる（ADR-0014）。雛形が持つのは
まとまり `app`（見出しは `appName`）と、その中の分類 `server_notices`（「お知らせ」）だけ。

- 足すときは `lib/presentation/notifications/notification_channel_catalog.dart` の `groupsFor` に
  書き足す。名前は `AppLocalizations` に足して ja / en の両方に訳す（言語を替えると端末の名前も替わる）
- **id は一度出したら変えない**（端末は人の設定を id で覚えている）。使わなくなった id は
  `retiredChannelIds` に入れると消える
- **名前は中身が分かるものにし、他の分類の名前を流用しない**（「注意」「情報」のような重さの名前を
  別の意味に使い回さない）
- まとまりの見出しはアプリ名が既定。分類が多いなら、まとまりを分けて名前を付けてよい
- サーバーが分類を指定しない通知は、AndroidManifest の `default_notification_channel_id`
  （`server_notices`）に出る。変えるなら `serverNoticesChannelId` と一緒に（試験が見張る）
- 雛形は FCM が有効なときだけ分類を作る。FCM なしで自前の通知を出すアプリは、
  `PrepareNotificationChannelsUseCase` の登録をサービスロケーターの `if` の外へ出す

