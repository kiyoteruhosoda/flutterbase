

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
