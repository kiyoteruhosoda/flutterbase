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

## この雛形から派生アプリを作るとき

```bash
scripts/rename_app.sh <dart_name> com.nolumia.<app>
```

そのあと nolumialab で鍵を発行し、`deploy-repo` に登録する。
手順は `deploy-repo/docs/flutter-signing.md` の「新しいアプリを追加する」。

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
