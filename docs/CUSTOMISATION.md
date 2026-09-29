

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

