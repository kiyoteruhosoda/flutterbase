# 0008. サインインのブラウザは Chrome の Auth Tab にする（flutter_appauth をやめる）

- 状態: 採用（ADR-0007 の「ブラウザと戻り道」の部分を置き換える）
- 日付: 2026-09-28

## 文脈

ADR-0007 で、assay へのサインインを flutter_appauth（中身は AppAuth-Android の Custom Tab）で
入れた。戻り先は assay が https しか登録できないので、対の Web の App Link
`https://<APP_LINK_HOST>/app/oauth2redirect` にした。

2026-09-28、持ち主の端末（Pixel 9 Pro、Android 17、Chrome 153）で試すと、**サインインが
アプリに戻ってこなかった**。端末の「対応リンクを開く」には対の Web のホストがオンで出ており、
Google の Digital Asset Links API も `assetlinks.json` を正しく読めていた。それでも:

- assay にログイン済みで、認可のあとすぐ 302 で戻り先へ送る回は、タブの中で止まり、
  Web にもアプリにも何も届かなかった（assay は認可コードを出している）
- パスキーでログインした回・同意（Allow）を押した回は、戻り先がタブの中で**Web の案内
  ページとして開いた**（Web の記録に `/app/oauth2redirect?code=…` の GET が残る）
- **アプリはどの回も、認可コードをトークンの口へ引き換えに来ていない**

Custom Tab は、利用者のタップの直後でない移動では、https の App Link をアプリへ渡さない
（AppAuth-Android でも同種の報告が多い: #324・#448・#1013）。foodexpiryapp（同じ作り）も
同じ端末で「Allow」のあと戻らなかった。

AppAuth-Android は Auth Tab に対応しておらず（openid/AppAuth-Android #1128）、flutter_appauth
も同じ（MaikuB/flutter_appauth #668）。

## 決定

**ブラウザは flutter_web_auth_2（5.x）で開く。** Android では Chrome の **Auth Tab**
（`AuthTabIntent`）を使い、https の戻り先を `httpsHost` / `httpsPath` で渡す。Auth Tab は
戻り先を**意図（intent）ではなくブラウザからの直接の返事**としてアプリへ返すので、
上の「タブの中で止まる」が起きない。Auth Tab の無いブラウザでは、androidx.browser が
普通の Custom Tab へ落とし、そのときの戻り道は flutter_web_auth_2 の `CallbackActivity`
（App Link）になる。

**PKCE・state・認可コードの引き換え・更新は Dart で書く**（`WebAuthOidcClient`）。
flutter_web_auth_2 はブラウザを開いて戻り URL を返すだけで、OAuth は持たない。

- 発行者のメタデータ（`/.well-known/openid-configuration`）から 2 つの口を読む
- PKCE は S256。`state` を照合し、戻り URL が https・対の Web のホスト・`/app/oauth2redirect`
  であることを確かめる。`error=access_denied` は「断られた」（取り消しと同じ扱い）
- 引き換え・更新は public client なので `client_secret` を送らない
- ⚠ **`OidcClient` の形は変えない。** `OidcAuthSession`（トークンの保管と更新の直列化）は
  そのまま使う

## 理由

- **Auth Tab は「サインインのためのタブ」として Chrome が用意したもの**で、https の戻り先を
  前提にしている（Digital Asset Links で検証する）。こちらの要件（assay は https しか登録
  できない）にそのまま合う。
- **自前で Auth Tab を呼ぶより、保守されている部品を使う。** AppAuth の改造版や
  MethodChannel の自作は、Chrome の変更に追随する手間を背負う。
- **OAuth を自前で書く範囲は小さい。** 認可 URL の組み立て・PKCE・2 種類の POST・照合だけで、
  試験で固定できる。

採らなかった案:

- **Web の案内ページ（S16）に「アプリに戻る」ボタンを置く**（fastapitemplate ADR-0046）
  ——タブの中で開いた回は救えるが、すぐ 302 の回（タブの中で止まり、何も届かない）は救えない。
  受け皿としては残す
- **assay 側で、アプリへ戻る前に「アプリに戻る」ボタンの画面を挟む** ——どのブラウザでも
  効く受け皿として、assay 側で別に入れる（こちらの判断ではない）
- **`prompt=login` で毎回ログイン画面を出す** ——パスキー・同意のあとの形は救えず、
  毎回のログインは使う人の手間になる

## 影響

- 依存: `flutter_appauth` を外し、`flutter_web_auth_2`・`http`・`crypto` を足した
  （どれも Infrastructure だけ。`tool/check_architecture.dart`）
- マニフェスト: AppAuth の `RedirectUriReceiverActivity` の差し替えと
  `appAuthRedirectScheme` を外し、flutter_web_auth_2 の `CallbackActivity` に同じ App Link
  （`https://${appLinkHost}/app/oauth2redirect`、autoVerify）を付けた。Gradle の
  `appLinkHost` はそのため残る（`-PappLinkHost` か dart-define の `APP_LINK_HOST`）
- `--dart-define` の 3 つと「どれか空なら何も出さない」は変わらない
- ⚠ Auth Tab が Digital Asset Links の検証に失敗すると、タブがすぐ閉じる端末がある報告が
  ある（flutter_web_auth_2 PR #216、未取り込み）。そのときは `InfrastructureError`
  （「Sign-in failed: FAILED」）になる。起きたら、普通の Custom Tab でやり直す処理を足す
