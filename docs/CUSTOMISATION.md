

## assay へのサインイン（任意）

雛形はサインインを持っているが、既定では出さない。使うときは**コードを直さず**、
ビルドに `--dart-define` を 3 つ渡す（`OIDC_ISSUER` / `OIDC_CLIENT_ID` / `APP_LINK_HOST`）。
手順と Web 側の条件は `docs/RELEASE.md` と `docs/adr/0007-optional-assay-sign-in.md`。
サインインした人のアクセストークンは `AuthSession.accessToken()`（Application のポート）で
取り、対の Web の API を呼ぶアダプターを Infrastructure に足す。
