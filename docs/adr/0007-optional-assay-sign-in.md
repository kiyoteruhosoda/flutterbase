# 0007. assay へのサインインを「任意の機能」として雛形に持たせる

- 状態: 採用
- 日付: 2026-09-28

## 文脈

nolumiadeck の画面から Android アプリを作れるようになった（nolumiadeck ADR-0114）。
アプリの多くは、同じ deck で作った Web アプリ（fastapitemplate 型）と対になり、
**同じ人が同じ assay の口座で入る**。foodexpiryapp はこれを自前で書いていた
（foodexpiryweb ADR-0047）が、雛形には無く、派生のたびに書き写すことになる。

assay の事情が形を決める:

- assay は **http(s) の redirect URI しか登録できない**（独自スキームは不可）。
  ブラウザから戻す先は、対の Web のホスト上の **App Link**
  （`https://<host>/app/oauth2redirect`）になる。App Link は Web 側が
  `/.well-known/assetlinks.json` で署名の指紋を答えて初めて検証される
- アプリは **public client（PKCE、秘密なし）**。リフレッシュトークンは回転し、
  使い回すと一族ごと失効する（直列化が要る）
- 人のアクセストークンの `aud` は常に userinfo なので、Web の API は
  **`client_id` で受け取るかを決める**（`APP_CLIENT_IDS`）

## 決定

**雛形に「assay へのサインイン」を入れるが、既定では何も出さない。**

- 値は 3 つとも `--dart-define` で渡す: `OIDC_ISSUER` / `OIDC_CLIENT_ID` /
  `APP_LINK_HOST`（対の Web のホスト）。**1 つでも空ならサインインは無い**
  ——メニューにも画面にも出ず、プラグインも呼ばない（`SignInSettings.isEnabled`）
- 戻り先は `https://<APP_LINK_HOST>/app/oauth2redirect`。AppAuth の
  `RedirectUriReceiverActivity` を `tools:node="replace"` で置き換え、
  **プラグイン自身の独自スキームの受け口を落とす**（戻り道を 1 本にする）
- マニフェストのホストは Gradle の placeholder `appLinkHost`。値は
  `-PappLinkHost=…` があればそれ、無ければ **ビルドの `--dart-define=APP_LINK_HOST`**
  （Flutter が `dart-defines` として Gradle に渡すものを読む）。リリースは
  `--dart-define` だけ渡せば Dart とマニフェストが食い違わない
- 実装は foodexpiryapp から移した（`OidcAuthSession`・`FlutterAppAuthOidcClient`・
  `SecretStore`）。層は既存のとおり: ポート `AuthSession`（Application）、
  AppAuth と Keystore は Infrastructure だけ（`tool/check_architecture.dart` の
  `_ioPackages`）
- 入口は最小: ドロワーの「アカウント」→ `/account`（サインイン／サインアウトと、誰が入っているか）。
  アクセストークンは `AuthSession.accessToken()` で派生アプリが Web の API を呼ぶのに使う

## 理由

**既定で何も出さない。** 雛形そのものと、サインインを使わない派生の挙動を変えない
ため。3 つのうち 1 つでも欠けたら「無い」に倒すので、半端な設定で壊れた入口が出る
ことが無い。

**値は `--dart-define` で渡す。** 派生のリポジトリに環境ごとの値を書かずに済み、
deck の配布（deploy-repo の `flutter-apps.json`）が同じアプリの版を別の組の値で
焼ける。発行者と client_id は秘密ではない（public client）。

**マニフェストは dart-define から読む。** `-P` を別に渡す形にすると、リリースの道具が
2 か所に同じ値を書くことになり、片方を忘れると**サインインだけがブラウザで止まる**
（App Link が検証されない）——それが最も気付きにくい壊れ方なので、値の出所を 1 つにした。

採らなかった案:

- **サインインを使わないビルドでは受け口ごと消す** ——Gradle の variant API で
  マニフェストを足す方法はあるが、flutter_appauth のマニフェストは常に自前の受け口
  （独自スキーム）を持ち込むので、「消す」と「置き換える」を条件で出し分ける必要が
  出る。置き換えを常に行い、ホストの既定値を雛形の既存のディープリンクのホスト
  （`AppConfig.appLinkHost`）にした。**既に受けている領域のパスが 1 つ増えるだけ**で、
  新しい受け口は開かない
- **独自スキームで戻す** ——他のアプリが同じスキームを名乗れる。assay も登録できない

## 影響

- 依存が 2 つ増える（`flutter_appauth`、`flutter_secure_storage`）。どちらも Infrastructure だけ
- Web 側（fastapitemplate 型）に `assetlinks.json` と `APP_CLIENT_IDS` が要る。
  deck の作成が対の Web に設定を足す（nolumiadeck ADR-0114、taskstg /issues/58）
- `scripts/rename_app.sh` は触らない（名前の置き換えと無関係の値）
