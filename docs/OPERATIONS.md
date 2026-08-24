# Operations

この文書は、デプロイ・リセット・マイグレーションなど、運用時に発生しやすい事象の一次切り分け手順をまとめます。

## 品質ゲート

すべての検査は 1 コマンドで走ります。CI (`.github/workflows/quality.yml`) が
実行するのも同じスクリプトなので、ローカルで通れば CI でも通ります。

```bash
./scripts/ci.sh                 # 全検査
./scripts/ci.sh --fast          # APK ビルドを飛ばす（開発中はこれで十分）
./scripts/ci.sh --keep-going    # 途中で止めず、最後に失敗一覧を出す
./scripts/ci.sh --help
```

実行される検査は次の順です。いずれかが失敗すると非ゼロ終了します。

| # | 検査 | コマンド |
|---|---|---|
| 1 | 依存解決 | `flutter pub get --enforce-lockfile` |
| 2 | コード生成（使用時のみ） | `dart run build_runner build --delete-conflicting-outputs` |
| 3 | 生成物のコミット漏れ | `git diff --exit-code` |
| 4 | 整形 | `dart format --output=none --set-exit-if-changed .` |
| 5 | 静的解析 | `flutter analyze --fatal-infos --fatal-warnings` |
| 6 | アーキテクチャ規約 | `dart run tool/check_architecture.dart` |
| 7 | 依存関係規約 | `dart run tool/check_dependencies.dart` |
| 8 | テスト | `flutter test --coverage` |
| 9 | カバレッジ下限 | `dart run tool/check_coverage.dart` |
| 10 | リリース契約 | `bash scripts/check_release_contract.sh` |

2 と 3 は、`build.yaml` があるか `lib/` に `part '*.g.dart'` /
`part '*.freezed.dart'` があるときだけ走ります。現状このテンプレートは
コード生成を使っていないため自動的にスキップされます。

10 は release の APK / AAB を**リリース経路と同じ焼き方で**作り、その成果物が
リリース経路の後段の前提を満たしているかを確かめます（下の
「リリース契約を手元で検査する」）。以前ここは `flutter build apk --debug`
でしたが、debug ビルドは release ビルドタイプも成果物のファイル名も未署名出力も
通らないため、そこを壊しても緑のままでした。

### Flutter のバージョン固定と `pubspec.lock`

Flutter は自身が同梱するパッケージ（`meta` / `matcher` / `test_api` /
`test_core` / `test` / `vector_math` / `intl` など）のバージョンを SDK 側で
固定します。そのため `pubspec.lock` は **それを生成した Flutter でしか
解決できません**。別のバージョンで `flutter pub get --enforce-lockfile` を
走らせると、必ず次のように落ちます。

```text
> intl 0.20.3 (was 0.20.2)
> matcher 0.12.20 (was 0.12.19)
...
Unable to satisfy `pubspec.yaml` using `pubspec.lock`.
```

これは lock の書き方の問題ではなく、ツールチェインが食い違っているという
意味です。したがってバージョンは 1 か所に決め打ちし、全ての実行環境で
同じものを使います。

| 定義場所 | 項目 | 所在 |
|---|---|---|
| `pubspec.yaml` | `environment: flutter:` / `sdk:` | このリポジトリ |
| `.github/workflows/quality.yml` | `subosito/flutter-action` の `flutter-version` | このリポジトリ |
| リリースビルダーイメージ | イメージに同梱された Flutter 本体 | **リポジトリ外**（ビルドホスト） |

現在の固定値は **Flutter 3.47.1 / Dart 3.13.1** です。

⚠ **3 つ目はこのリポジトリからは動かせません。** リリースの APK / AAB を焼くのは
ビルドホスト側で digest 固定されたコンテナイメージで、そこに入っている Flutter が
実際の固定値です。`environment:` の床を上げるときは、**先にビルダーイメージ側が
その版を持っていることを確認**してください。順序を逆にすると、CI は緑のまま
リリースビルドだけが `version solving failed` で落ちます。手順は
`docs/RELEASE.md` を参照。

CI で `stable` のような流動的なブランチを clone してはいけません。Flutter 側が
stable を進めた瞬間に lock と食い違い、`--enforce-lockfile` が構造的に必ず
失敗するようになります。

依存解決は全経路で `--enforce-lockfile` を使います（`scripts/ci.sh` /
`scripts/build.sh` / `scripts/check_release_contract.sh`、およびリリース経路）。
配布物を作る経路が、品質ゲートで検証していない依存でビルドされるのを防ぐ
ためです。**副作用として、ビルダーの Flutter が固定値からずれると依存解決の
時点で止まります。** これは意図した挙動で、黙って別の依存で配布物が作られるより
早く気付けます。直し方は上の表の 3 か所を揃えるか、ビルダーの Flutter を固定値に
戻すかのどちらかです。

#### 上げるとき

1. **先にビルダーイメージを新しい版で焼き直す**（リポジトリ外の作業）。
   ここが最後になると、リリースビルドだけが落ちる状態が生まれます。
2. 上の表の残り 2 か所を新しいバージョンに揃える。
3. そのバージョンの Flutter で `flutter pub get`（`--enforce-lockfile` なし）を
   走らせ、`pubspec.lock` を作り直す。
4. `./scripts/ci.sh` を通し、`pubspec.lock` を一緒にコミットする。
5. Android ツールチェインの最低要件が上がっていないか、本書の
   「Android ツールチェイン」を確認する。

⚠ SDK を上げても `pubspec.lock` が必ず壊れるわけではありません。壊れるのは
**新しい SDK が同梱パッケージの版を動かしたときだけ**です。`flutter pub get
--enforce-lockfile` が通るなら lock はそのままで構いません。

### 個別に走らせる

```bash
dart run tool/check_architecture.dart --verbose   # レイヤー違反の詳細
dart run tool/check_dependencies.dart --verbose   # pubspec と import の突き合わせ
flutter test --coverage
dart run tool/check_coverage.dart --verbose       # 下限割れ時に低い順で列挙
```

`tool/check_architecture.dart` は `--root` / `--package` を受け取ります。
テスト用フィクスチャに対して走らせるためのもので、通常は不要です。

### 検査ツール自体のテスト

`test/tool/` が各ルールについて「違反入りのフィクスチャで非ゼロ終了すること」を
確認します。時間がかかるので、開発中に飛ばしたい場合は次を使います。

```bash
flutter test --exclude-tags tool
```

### よくある失敗と対処

| 症状 | 原因 | 対処 |
|---|---|---|
| `banned-import` | Domain / Application が Flutter や I/O package を import した | そのコードを `lib/infrastructure/` へ移し、Application にポートを切る |
| `layer-direction` | 依存方向が外向きになった | `docs/ARCHITECTURE.md` の表を参照。Presentation から合成ルートを引いていないか確認 |
| `concrete-adapter-dependency` | 具象アダプターを直接参照した | Domain のインターフェースに差し替える。束ねてよいのは `lib/app/` だけ |
| `unused-dependency` | 使っていない runtime 依存がある | 削除するか、意図的なら `pubspec.yaml` の `dependency_policy.reserved` に記載 |
| `stale-reservation` | reserved の記載が実態と合っていない | 使い始めた package は reserved から外す |
| カバレッジ下限割れ | テスト不足 | `--verbose` で低い順に出るので上から潰す |
| `every library under lib/ is imported by this file` が落ちる | `lib/` にファイルを足したが `test/coverage_surface_test.dart` に import していない | 失敗メッセージのとおり import を追加 |
| `Unable to satisfy pubspec.yaml using pubspec.lock` | 手元の Flutter が固定バージョンと違う、または `pubspec.lock` の更新をコミットし忘れた | 上の「Flutter のバージョン固定と `pubspec.lock`」を参照 |
| `AndroidManifest — deep links` が落ちる | `AppConfig` と `AndroidManifest.xml` のホスト / スキームが食い違った | 両方を揃える。手順は `docs/DEEP_LINKS.md` |

## 配布物をビルドする

⚠ **ここは手元でビルドする話です。**main に入ったものを配る正規の経路は
ビルドホスト側にあり、そちらが署名と検証まで行います（`docs/RELEASE.md`）。
この節の `scripts/build.sh` は、CI を通さずに手元の判断で焼きたいとき
（任意のブランチ、外部ネットワークに出せない環境）のためのものです。

配布用の APK / AAB は `scripts/build.sh` で作ります。出力先ディレクトリ
（既定 `dist/`）が配布物の一式で、これをそのまま配布元のマシンへ渡せば足ります
（リポジトリも Flutter SDK も要りません）。

```bash
./scripts/build.sh              # APK + AAB（release）を dist/ へ
./scripts/build.sh apk          # APK だけ
./scripts/build.sh aab out      # AAB だけを out/ へ
./scripts/build.sh --help
```

| 環境変数 | 既定 | 意味 |
|---|---|---|
| `BUILD_MODE` | `release` | ビルド variant（`release` / `debug`） |
| `BUILD_NUMBER` | `git rev-list --count HEAD` | Android の versionCode |

出力されるもの:

| ファイル | 内容 |
|---|---|
| `<base>-<version>-<variant>.apk` | 端末へ入れる配布物 |
| `<base>-<version>-<variant>.aab` | Play Console へ上げる配布物 |
| `manifest.env` | commit / branch / version / 署名鍵 / ファイル名 |
| `manifest.sha256` | 転送破損を検出するためのチェックサム |

`<base>` は `android/app/build.gradle` の `appApplicationId` の末尾
（`android/gradle.properties` の `app.archivesBaseName` があればそちら）です。

出力先にある古い APK / AAB は毎回消してから書き出します。新しいものの隣に
前回の版が残っていると、配布元では見分けが付かないためです。

### 署名

`android/key.properties` に `storeFile` があれば release 鍵で、無ければ debug 鍵で
署名されます（`android/app/build.gradle` のフォールバック）。判定はファイルの有無
ではなく `storeFile` の有無で行います。`build.gradle` がそう判定するためで、
中身が空・書きかけの `key.properties` があっても debug 鍵になります。

debug 鍵になった場合は警告を出し、`manifest.env` の `signing` にも
`debug-keystore` と記録します。**社外へ配るビルドでは必ず
`signing=release-keystore` を確認してください。** 鍵の用意は
`docs/CUSTOMISATION.md` にあります。

### 生成物とワーキングツリー

生成物でありながらコミット対象のファイルが 2 つあります。ビルドで書き換わった
ままだとビルドホストの次の `git pull --ff-only` が失敗するため、`build.sh` と
`check_release_contract.sh` はビルド前の内容へ戻してから終了します（失敗時も
戻します）。開発機で未コミットの変更を持っている場合も、その内容が戻ります。

| ファイル | 誰が書き換えるか |
|---|---|
| `lib/shared/build_info.dart` | `scripts/generate_build_info.sh` |
| `android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java` | `flutter build` |

⚠ 2 つ目は **variant によって中身が変わります。** そのビルドが実際にリンクする
プラグインだけを登録するので、`integration_test`（dev 依存）は **release では
消え、debug では戻ります。**リポジトリにコミットされているのは debug 側の内容
です。release を焼いたあとに差分が出ていたらこれで、異常ではありません。

`BUILD_NUMBER` を指定した場合、その値は `BuildInfo.buildNumber` にも渡ります。
アプリの About 画面が表示する build number と、成果物の versionCode・
`manifest.env` が食い違わないようにするためです。

## リリース契約を手元で検査する

配布する APK / AAB を焼くのはこのリポジトリの CI ではなく、ビルドホスト側の
リリース経路です（全体像は `docs/RELEASE.md`）。その経路は 3 段に分かれていて、
**署名する段と検証する段はリポジトリを見ません。**成果物を固定のディレクトリから
固定の名前で拾うだけです。

| 段 | やること | リポジトリを見るか | 鍵を持つか |
|---|---|---|---|
| 1 | ビルド | 見る（アプリのコードが走る） | **持たない** → 未署名 |
| 2 | 署名 | 見ない | 持つ |
| 3 | 検証・保管 | 見ない | 持たない |

こう分けてあるのは、署名鍵を pub パッケージや Gradle プラグインの手が届かない
場所に置くためです。その代償として、**段 2 と段 3 が探すファイル名とディレクトリが
そのまま契約になります。**そしてその名前を作っているのは
`android/app/build.gradle` 1 つだけで、リポジトリ内の他のどこからも参照されて
いません。つまりここを壊しても、debug ビルドは通り、テストも通り、**マージ後に
ビルドホストで初めて落ちます。**

`scripts/check_release_contract.sh` がその穴を塞ぎます。段 1 をリリース経路と
同じ手順で走らせ、そのあとで段 2 と段 3 が探すものが揃っているかを確かめます。

```bash
./scripts/check_release_contract.sh              # ビルドしてから検査
./scripts/check_release_contract.sh --no-build   # 既存の build/ をそのまま検査
```

`./scripts/ci.sh` の最後の検査がこれです（`--fast` で飛ばせます）。

### 検査している契約

| 契約 | 破れると |
|---|---|
| `build/app/outputs/apk/release/<base>-<version>-release.apk` がある | 段 2 が署名対象を 1 つも拾えず「署名対象の APK が見つからない」で落ちる |
| `build/app/outputs/flutter-apk/<base>-<version>-release.apk` がある | 段 2 は成功するのに、段 3 が「APK が見つからない」で落ちる |
| `build/app/outputs/bundle/release/<base>-<version>-release.aab` がある | 段 2・段 3 とも「署名対象の AAB が見つからない」で落ちる |
| ファイル名の版数が `pubspec.yaml` の `version` と一致する | 段 3 が「前回ビルドの残骸を拾っている」と判断して落ちる |
| `app-release-unsigned.apk` がある（＝ `NOLUMIA_SIGNING=none` が効いている） | Gradle が debug 鍵で署名してしまい、段 3 が「debug 鍵で署名されている」で落ちる |
| `flutter-apk/app-release.apk` がある | Flutter CLI が「Gradle build failed to produce an .apk file」でビルドごと落ちる |
| 成果物が署名されていない | 段 1 の中で何かが署名している。鍵がアプリのコードから届く位置にある疑い |
| APK の applicationId が `build.gradle` の宣言と一致する | 段 3 が「applicationId が宣言と一致しない」で落ちる |

`<base>` は `android/app/build.gradle` の `appApplicationId` の末尾
（`android/gradle.properties` に `app.archivesBaseName` があればそちら）です。

最後の 2 つは外部ツールが要ります。APK の署名判定は `apksigner`、AAB の署名判定は
`unzip`、applicationId の照合は `aapt2` です。無い環境ではその検査だけスキップされ、
他は変わらず走ります。

⚠ APK の署名判定に zip の中身（`META-INF/*.RSA`）を見てはいけません。`minSdk` が
36 なので AGP は v1（JAR）署名を既定で行わず、署名済みでも APK Signing Block
（v2/v3）にしか署名が入りません。エントリ一覧を見る方法だと**署名済みの APK も
「未署名」と判定してしまいます。**

⚠ `apksigner` は `java` を PATH から探すシェルラッパーです。**ビルダーイメージは
JDK を PATH に置いていない**（`JAVA_HOME` だけが指している）ため、素のままでは
exit 127 で落ちます。これは「署名が無い」と終了コードで区別が付かないので、
検査は `JAVA_HOME/bin` を PATH に足したうえで、**先に `apksigner version` が
通ることを確かめてから**署名の有無を読みます。動かない場合は「未署名」ではなく
スキップとして出ます。

### なぜ debug ビルドでは足りなかったのか

以前ここは `flutter build apk --debug` でした。Gradle が設定として壊れていない
ことは分かりますが、release ビルドタイプも、成果物のリネーム処理も、未署名モードも
一切通りません。リリース経路が読むものは全部そこにあるので、**壊しても緑**でした。

## ローカル DB (SQLite)

スキーマとマイグレーションは `lib/infrastructure/database/app_database.dart`
に集約しています。DB を開くのはアプリ起動時（`InfrastructureModule.create`）
の 1 回だけです。

| 項目 | 値 / 場所 |
|---|---|
| ファイル名 | `flutterbase.db`（`AppDatabase.fileName`） |
| 配置 | プラットフォームの databases ディレクトリ（`getDatabasesPath()`） |
| スキーマ版 | `AppDatabase.schemaVersion` |
| マイグレーション | `AppDatabase._upgrade` の `if (from < n)` ラダー |

### スキーマを変更する

1. `AppDatabase.schemaVersion` を 1 つ上げる。
2. `_upgrade` に `if (from < <新しい版>) { ... }` を追加する。
   既存のブロックは消さないでください。数リリース飛ばして更新した端末は、
   上から順に全部を通ります。
3. `_create` にも同じ最終形を反映する（新規インストール用）。
4. `test/infrastructure/database/app_database_test.dart` にケースを足す。

### リセット

アプリのデータを消せば DB ファイルごと消えます。

```bash
adb shell pm clear com.nolumia.flutterbase
```

### テスト

Android / iOS の sqflite プラグインはホスト上では動かないため、テストは
`sqflite_common_ffi` の `databaseFactory` に差し替えて**同じ production コード**
を実行します。`AppDatabase.open` が top-level の `openDatabase` ではなく
ambient な `databaseFactory` を使っているのはこのためです。

```dart
setUpAll(() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
});
```

## ディープリンク

App Links / カスタムスキームの設定・確認手順は `docs/DEEP_LINKS.md` にあります。

切り分けの起点はログです。ルーターに届いたリンクは必ず
`[Router] → /bookmarks/1` の形で残ります。

- ログが出ない → リンクがアプリに届いていない（intent filter か検証の問題）
- ログは出るが画面が出ない → ルートが一致していない（`AppRoutes` を確認）

アプリ内の `/link` 画面（ドロワー → ディープリンク）に、起動時 URL と
`adb` コマンドが表示されます。

## Android ツールチェイン

`android/` は Flutter 3.47.1 の**テンプレート既定値に揃えて**固定しています。
`flutter create` が 3.47.1 で生成するのと同じ組み合わせで、Flutter 側が
テストしている範囲そのものです。

| 項目 | バージョン | 定義場所 |
|---|---|---|
| Gradle | 9.3.1 | `android/gradle/wrapper/gradle-wrapper.properties` |
| Android Gradle Plugin | 9.1.0 | `android/settings.gradle` |
| Kotlin (KGP) | 2.4.0 | `android/settings.gradle` |
| JDK | 17 | `android/app/build.gradle` (`compileOptions`) |

Flutter 3.47.1 が要求する下限（`DependencyVersionChecker`）との関係は次のとおりです。
`error` を下回るとビルドが失敗し、`warn` を下回ると非推奨警告が出ます。

| 項目 | error（失敗） | warn（警告） | 現在 |
|---|---|---|---|
| Gradle | 8.14.0 | 9.1.0 | 9.3.1 |
| AGP | 8.11.1 | 9.0.1 | 9.1.0 |
| KGP | 2.2.20 | 2.3.20 | 2.4.0 |
| JDK | 17 | 17 | 17 |

以前は AGP 8.11.1 / KGP 2.2.20 で、いずれも **error 閾値ちょうど**に乗っていました。
Flutter が下限を 1 つ上げた時点でビルドが失敗する位置です。現在はどれも warn を
超えており、余裕があります。

### AGP 9 と Groovy DSL

AGP 9 は新 DSL を既定にしますが、`android/gradle.properties` の
`android.newDsl=false` で従来の DSL を読み続けます。Flutter 3.47.1 の
テンプレート自身がこのフラグを false で出荷しており、Groovy の
`build.gradle` を書き換えずに AGP 9 へ上げられます。
`applicationVariants` を使う成果物リネーム処理（`android/app/build.gradle`）も
AGP 9.1.0 でそのまま動くことを、APK / AAB 両方のビルドで確認しています。

### built-in Kotlin にはまだ移行できない

AGP 9 では `android.builtInKotlin` が既定で有効になり、有効なままだと
Flutter が「KGP を明示適用しているので将来のリリースで壊れる」と警告します。
ただし**今は移行できません**。AGP 9.1.0 / 9.2.1 / 9.3.1 のいずれも同梱する
Kotlin が 2.2.10 で、Flutter の下限 2.2.20 を下回るためです。有効にすると
Flutter Gradle プラグインの適用時点で次のように失敗します。

```text
Error: Your project's Kotlin version (2.2.10) is lower than Flutter's
minimum supported version of 2.2.20.
```

そのため `android.builtInKotlin=false` のまま KGP を明示適用します。これは
Flutter 3.47.1 のテンプレートと同じ構成なので、`flutter create` で作った
新規アプリと同じだけ将来に耐えます。AGP の同梱 Kotlin が 2.2.20 以上になったら
移行してください。手順は
<https://docs.flutter.dev/release/breaking-changes/migrate-to-built-in-kotlin/for-app-developers>。

Gradle のバージョンが低いと `flutter build` は
`Your project's Gradle version ... is lower than Flutter's minimum supported version`
で失敗します。Flutter を上げたらこの表も合わせて更新してください。

## デプロイ時の確認観点

デプロイは次の境界ごとに分けて確認します。

| 境界 | 確認対象 | 代表的な失敗 |
|---|---|---|
| Image | 実行イメージと revision | 古い image、想定外の tag |
| Runtime | ホスト kernel / cgroup / libc | バイナリ互換性不足 |
| Database | 起動状態 / healthcheck | 初期化待ち、volume 破損 |
| Migration | migration ツール / schema | migration binary の起動失敗、SQL エラー |

境界を分けることで、単一の巨大な `if` / `switch` 的な切り分けではなく、責務ごとの Strategy として原因を特定しやすくします。

## MariaDB reset 後に `sqlx: GLIBC_2.39 not found` が出る場合

### 症状

`./deploy.sh reset` などで DB volume を削除し、MariaDB の healthcheck が `healthy` になった後、migration フェーズで次のエラーが出ます。

```text
sqlx: /lib/x86_64-linux-gnu/libc.so.6: version `GLIBC_2.39' not found (required by sqlx)
DB migration failed after 3 attempts
```

この場合、MariaDB 自体は起動できています。失敗している境界は **Database** ではなく **Migration runtime** です。

### 原因

`sqlx` CLI バイナリが、実行コンテナまたはホストに入っている glibc より新しい glibc を要求しています。

典型例:

* Ubuntu 24.04 など glibc 2.39 系で build した `sqlx` を、Debian bookworm / bullseye 系の image で実行している
* CI で作った `sqlx` バイナリを、NAS や古い distro ベースのコンテナへコピーしている
* migration image と builder image の OS 世代が揃っていない

### 推奨対応

migration image の中で、実行環境と同じ libc 世代に合わせて `sqlx` を build / install してください。DDD の境界で考えると、migration 実行は API や Web とは別の Infrastructure concern なので、専用 image に閉じ込めるのが安全です。

推奨方針:

1. `sqlx` をホストや別 OS 世代の CI artifact からコピーしない
2. `migrate` service の Dockerfile 内で `cargo install sqlx-cli --no-default-features --features mysql` を実行する
3. builder stage と runtime stage の distro 系統を合わせる
4. どうしても単体バイナリを配布する場合は、配布先より古い glibc で build する

例:

```dockerfile
FROM rust:1-bookworm AS builder
RUN cargo install sqlx-cli --locked --no-default-features --features mysql

FROM debian:bookworm-slim AS migrate
COPY --from=builder /usr/local/cargo/bin/sqlx /usr/local/bin/sqlx
COPY migrations /app/migrations
WORKDIR /app
CMD ["sqlx", "migrate", "run"]
```

builder と runtime をどちらも bookworm 系にしておくと、`sqlx` が要求する glibc と runtime の glibc がずれにくくなります。

### 確認コマンド

migration コンテナ内で次を確認します。

```sh
ldd --version
sqlx --version
ldd "$(command -v sqlx)"
```

`ldd` の glibc version が `sqlx` の要求 version より古い場合は、migration image の作り直しが必要です。

### 暫定回避

すぐに復旧が必要な場合は、次のどちらかを選びます。

* runtime と同じ OS 世代の環境で `sqlx` を再 build して image を作り直す
* `sqlx` CLI を使わず、API binary に組み込んだ migration runner など、同一 image 内で build 済みの実行経路へ切り替える

ただし、ホストへ新しい glibc を手動導入する対応は推奨しません。NAS や appliance 系環境では OS 全体の互換性を壊すリスクがあります。
