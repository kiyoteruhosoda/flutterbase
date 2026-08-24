# リリースビルドと署名

release の AAB / APK は **GitHub Actions ではなく nolumialab の Komodo が作る。**
2026-08-23 に移設した（それ以前は Azure Container Instances を起動する
`.github/workflows/build.yml` + GitHub Secrets）。

## 流れ

```
main へ push
  └─ Version Bump (GitHub Actions) が pubspec のバージョンを上げて main へ commit
       └─ その push を Komodo の webhook が拾う
            └─ Komodo Repo リソース "flutterbase" が pull して
               /etc/komodo/bin/flutter-release.sh を実行
                 stage 1  ビルド    鍵を渡さない → 未署名の APK / AAB
                 stage 2  署名      成果物と鍵だけを渡した別コンテナで
                                    apksigner / jarsigner
                 stage 3  検証保管  宣言した証明書指紋と実測を突合して
                                    /mnt/labbackup/artifacts/flutterbase/ へ
```

`pubspec.yaml` の `version` が前回ビルドから変わっていなければスキップされる。

成果物には `SHA256SUMS` と `signing-report.txt`（alias / 証明書指紋 / applicationId /
commit）が付く。

## 署名鍵

Play App Signing のアップロード鍵。alias は `flutterbase-upload`。

| | 場所 |
|---|---|
| 保管（正） | naso `/volume1/labbackup/android-signing/flutterbase/` |
| 稼働用 | nolumialab `/srv/signing/flutterbase/upload-keystore.jks` (0400 root) |
| パスワード | Komodo Secret Variable `SIGN_FLUTTERBASE_STORE_PASS` / `_KEY_PASS` |
| 紐付けの宣言 | `deploy-repo` の `resources/repos.toml` |

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

これは `docs/komodo-registration.md` を生成する。**登録が済むまで、その派生
アプリは main に入れても何も焼かれない。**必要な値（applicationId・鍵の別名・
Secret 変数名・`repos.toml` に貼るブロック）はこのアプリの分が埋まった形で
そこに入っているので、順に片付けて、済んだらファイルを消す。

鍵の発行そのものは nolumialab 側の作業。手順は
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

⚠ 署名なしモードでは AGP の出力が `app-release-unsigned.apk` になる。
Flutter CLI が `app-release.apk` を決め打ちで探して落ちるため、
`build.gradle` の per-app コピー処理の中で既定名のコピーも置いている。
