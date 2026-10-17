# リリースビルドと署名

release の AAB / APK は **CI ではなく deck の配る段（nolumiadeck ADR-0063）が作る。**
起動は forge の push の知らせ（nolumiadeck ADR-0119）。

## 流れ

```
merge → quality（品質ゲート。緑でなければ main へ入らない）
      → Version Bump … pubspec のバージョンを上げて main へ commit
forge の push の知らせ → deck /api/release/hooks/push/app/flutterbase
      └─ deck の配る段（deploy-repo の bin/flutter-release.sh）
           stage 1  ビルド    鍵を渡さない → 未署名の APK / AAB
           stage 2  署名      成果物と鍵だけを渡した別コンテナで
                              apksigner / jarsigner
           stage 3  検証保管  宣言した証明書指紋と実測を突合して保管
           stage 4  配布      share.nolumia.com へ
```

`pubspec.yaml` の `version` が前回ビルドから変わっていなければスキップされる。

成果物には `SHA256SUMS` と `signing-report.txt`（alias / 証明書指紋 / applicationId /
commit）が付く。

APK は **ABI ごとに分けて**焼く（`arm64-v8a` / `armeabi-v7a`。universal は 80MB を超え、
端末の空き容量で入らないことがある）。share.nolumia.com の入口は
`flutterbase/flutterbase.apk`（arm64-v8a。ふつうの端末はこれ）・
`flutterbase/flutterbase-armeabi-v7a.apk`（32bit の端末）・`flutterbase/flutterbase.aab`。
⚠ 分割は一方通行（versionCode が +2000 されるので、戻すと既存の端末からはダウングレードになる）。
詳しくは deploy-repo の `docs/flutter-signing.md`。

## assay へのサインイン（任意。ADR-0007 / ADR-0008）

雛形のサインインは、**ビルドに 3 つの値を渡したときだけ**有効になる（既定は無し）:

```
flutter build apk --release \
  --dart-define=OIDC_ISSUER=https://identity.nolumia.com/<tenant> \
  --dart-define=OIDC_CLIENT_ID=<アプリの public client> \
  --dart-define=APP_LINK_HOST=<対の Web のホスト。例 recipebox.nolumia.com>
```

- ⚠ **1 つでも欠けるとサインインは出ない**（壊れた入口を出さないため）
- ブラウザは Chrome の **Auth Tab**（ADR-0008）。戻り先 `https://<APP_LINK_HOST>/app/oauth2redirect`
  はブラウザがアプリへ直接返す。Auth Tab の無いブラウザで使う App Link（マニフェストの
  `CallbackActivity`）のホストは、Gradle が同じ `APP_LINK_HOST` を読んで埋める。
  `-PappLinkHost=…`（`flutter build … --android-project-arg=appLinkHost=…`）があればそちらが勝つ
- ⚠ **対の Web が `/.well-known/assetlinks.json` でこのアプリの署名の指紋を答えている
  こと**。Auth Tab も戻り先をこれで検証する。答えていないと、タブがすぐ閉じてサインインが
  「失敗（FAILED）」になる
- deck から作ったアプリは、deploy-repo の `resources/flutter-apps.json` に値が書かれ、
  配布（`bin/flutter-release.sh`）がこの形で渡す
- サインインがあると、アプリは対の Web の `GET /api/app-release/latest`（Web は公開済みの
  `latest.json` を読む）で新しい版を知らせる（ADR-0009）。比べるのは **`build`** と、この
  ビルドに焼いた `--build-number`（= `BuildInfo.buildNumber`）。⚠ `latest.json` の `build` は
  この `--build-number` と同じ値でなければならない。ずれると、入れても知らせが消えない／
  出るべき知らせが出ない。APK を ABI ごとに分けると Flutter が versionCode に +1000 / +2000 を
  足すが、`BuildInfo.buildNumber` には足さないので比べる値は変わらない

## 署名鍵

Play App Signing のアップロード鍵。alias は `flutterbase-upload`。

| | 場所 |
|---|---|
| 保管（正） | naso `/volume1/labbackup/android-signing/flutterbase/` |
| 稼働用 | nolumialab `/srv/signing/flutterbase/upload-keystore.jks` (0400 root) |
| パスワード | deck の worker の `/srv/secrets/nolumiadeck/release/signing/flutterbase/`（正は naso の `CREDENTIALS.txt`） |
| 紐付けの宣言 | `deploy-repo` の `resources/flutter-apps.json` |

## リポジトリ側が守る契約

stage 2 と stage 3 は**リポジトリを見ない。**成果物を固定のディレクトリから
固定の名前で拾うだけで、その名前を作っているのは `android/app/build.gradle` の
中の、リポジトリ内の他のどこからも参照されていないコピー処理と
`unsignedRelease` フラグだけ。

つまりここを壊しても debug ビルドは通り、テストも通り、**マージ後に
nolumialab で初めて落ちる。**

```bash
./scripts/check_release_contract.sh
```

これが stage 1 を同じ手順で走らせ、stage 2 / stage 3 が探すものが揃っているかを
確かめる。`./scripts/ci.sh` の最後の検査でもあるので、PR が緑なら契約は
守られている。検査項目の一覧と、破れたときに何が起きるかは
`docs/OPERATIONS.md` の「リリース契約を手元で検査する」にある。

## Flutter を上げるとき

固定値は 3 か所にあり、**1 つはこのリポジトリの外**（ビルダーイメージに同梱
された Flutter 本体）。

**先にビルダーイメージを用意すること。** 逆順にすると、`pubspec.yaml` の
`environment: flutter:` の床だけが上がった状態になり、CI は緑のまま
リリースビルドだけが `version solving failed` で落ちる。

`pubspec.lock` は必ず作り直しになるわけではない。壊れるのは新しい SDK が
同梱パッケージ（`meta` / `matcher` / `test_api` / `vector_math` / `intl` …）の
版を動かしたときだけで、`--enforce-lockfile` が通るならそのままでよい。

## この雛形から派生アプリを作るとき

```bash
scripts/rename_app.sh <dart_name> com.nolumia.<app>
```

**deck の画面からプロジェクトを作ったなら、鍵・宣言・連携は作成の手順が済ませる**
（deck が作成の途中でこれを流す）。手で起こしたときは、これが生成する
`docs/release-registration.md` を順に片付ける。**登録が済むまで、その派生アプリは
main に入れても何も焼かれない。**必要な値（applicationId・鍵の別名・
`flutter-apps.json` に足す 1 件）はこのアプリの分が埋まった形で入っている。
済んだらファイルを消す。

鍵の発行そのものは nolumialab 側の作業。手順の正本は
`deploy-repo/docs/flutter-signing.md` の「新しいアプリを追加する」。

## `build.gradle` の署名まわり

```groovy
def unsignedRelease = (System.getenv("NOLUMIA_SIGNING") == "none")
...
signingConfig = unsignedRelease ? null : (hasKeystore ? signingConfigs.release : signingConfigs.debug)
```

- CI (`NOLUMIA_SIGNING=none`) → 署名しない。署名は後段の別コンテナが行う
- 手元 / 従来の `key.properties` 方式 → 今までどおり動く
- **鍵が無いと debug 署名に落ちる。** ローカルで release を焼くときは
  `apksigner verify --print-certs` で署名者を自分で確認すること

⚠ 署名なしモードでは AGP の出力が `app[-<abi>]-release-unsigned.apk` になる。
Flutter CLI が `app[-<abi>]-release.apk` を決め打ちで探して落ちるため、
`build.gradle` の per-app コピー処理の中で既定名のコピーも置いている。
