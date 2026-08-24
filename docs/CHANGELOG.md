# Changelog

完了した重要な変更の短い要約を、新しいものから並べます。
詳しい経緯が必要なものは `docs/history/`、設計判断は `docs/adr/` にあります。

## 2026-08-24 — リリースビルドの前提をリポジトリ側に揃え、契約を検査する

配布する APK / AAB を焼くのはビルドホスト側のリリース経路（ビルド／署名／
検証・保管の 3 段）だが、リポジトリにはそれ以前の経路の痕跡が 3 つ同時に
残っていた。同時に、その経路が読むものを**リポジトリ側は一切検査していな
かった**。設計判断は `docs/adr/0005-release-build-off-repository.md`。

### 追加

- `scripts/check_release_contract.sh` — stage 1 をリリース経路と同じ手順で
  走らせ、stage 2 / stage 3 が探すものが揃っているかを確かめる。成果物の
  per-app 名が AGP の出力先と Flutter CLI のコピー先の両方にあること、
  ファイル名の版数が `pubspec.yaml` と一致すること、`NOLUMIA_SIGNING=none` が
  実際に `signingConfig` を外していること、成果物に署名ブロックが無いこと、
  APK の applicationId が `build.gradle` の宣言と一致すること。
  `unzip` / `aapt2` が無い環境では末尾 2 つだけスキップする。
- `scripts/rename_app.sh` が `docs/komodo-registration.md` を生成するように
  した。派生アプリをビルドホストへ登録するのに要る値（applicationId・鍵の
  別名・Secret 変数名・`repos.toml` に貼るブロック）が埋まった状態で出る。
  **登録しないと、派生アプリは main に入れても何も焼かれない。**

### 変更

- `scripts/ci.sh` の最後の検査を `flutter build apk --debug` から
  `scripts/check_release_contract.sh` へ置き換えた。debug ビルドは release
  ビルドタイプにも成果物のリネーム処理にも未署名モードにも触れないため、
  **そこを壊しても CI は緑**で、マージ後にビルドホストで初めて落ちていた。
  release ビルドは APK と AAB の 2 本を焼くので CI の所要時間は伸びる
  （`--fast` で従来どおり飛ばせる）。
- Flutter のバージョンを固定する場所の数え方を直した。`azure-pipelines.yml`
  を外し、**ビルダーイメージに同梱された Flutter** を入れた。3 か所のうち
  1 つはこのリポジトリの外にあり、**そちらを先に用意しないと CI は緑のまま
  リリースビルドだけが落ちる。**

### 削除

- `azure-pipelines.yml` — 一度も使われていない。存在しない `ios/` をビルドし、
  終了したサービスへ配布し、`build.gradle` が読まない環境変数で署名しようと
  する内容のまま、Flutter の固定値を宣言する 3 か所目として docs に
  数えられていた。
- `scripts/build-remote-container.sh` と
  `scripts/build-remote-container.env.example` — ADR 0003 の dev コンテナ経路。
  前提としていた配布ディレクトリはホスト上に作られず、ビルドを委ねるはずの
  dev コンテナも停止したままで、**定常運用に乗らなかった**。ADR 0003 は廃止。
  `scripts/build.sh`（手元で任意のブランチを焼く経路）は残す。

## 2026-08-23 — Flutter 3.47.1 と Android ツールチェインを更新

Flutter 3.47 が Gradle / AGP / Kotlin について出していた「近く対応を打ち切る」
警告を解消した。AGP 8.11.1 と KGP 2.2.20 は Flutter の **error 閾値ちょうど**に
乗っており、Flutter が下限を 1 つ上げた時点でビルドが失敗する位置だった。

### 変更

- Flutter の固定値を 3.47.0 → **3.47.1**（Dart 3.13.1）。3 か所（`pubspec.yaml` /
  `quality.yml` / `azure-pipelines.yml`）を揃えた。`pubspec.lock` は 3.47.0 と
  3.47.1 で解決結果が完全に一致するため変更なし。
- Android ツールチェインを Flutter 3.47.1 のテンプレート既定値に合わせた。
  `flutter create` が生成するのと同じ組み合わせ。

  | 項目 | 旧 | 新 | error 閾値 | warn 閾値 |
  |---|---|---|---|---|
  | Gradle | 8.14.3 | 9.3.1 | 8.14.0 | 9.1.0 |
  | AGP | 8.11.1 | 9.1.0 | 8.11.1 | 9.0.1 |
  | KGP | 2.2.20 | 2.4.0 | 2.2.20 | 2.3.20 |

### 分かったこと

- **AGP 9 でも Groovy DSL はそのまま使える。** `android.newDsl=false` で従来の
  DSL を読み続ける。Flutter 3.47.1 のテンプレート自身がこのフラグを false で
  出荷している。旧ドキュメントの「AGP 9 は新 DSL のみを読むので 8 系に留めるのが
  安全」という判断は、この事実に基づき撤回した。`build.gradle` の書き換えは不要。
- **`applicationVariants` を使う成果物リネーム処理は AGP 9.1.0 でも動く。**
  APK / AAB 両方をビルドし、既定名と per-app 名の両方が
  `apk/debug/` `flutter-apk/` `bundle/release/` すべてに出ることを確認した。
- **built-in Kotlin にはまだ移行できない。** AGP 9.1.0 / 9.2.1 / 9.3.1 のいずれも
  同梱 Kotlin が 2.2.10 で、Flutter の下限 2.2.20 を下回る。有効にすると
  Flutter Gradle プラグインの適用時点で失敗する。`android.builtInKotlin=false`
  のまま KGP を明示適用する（テンプレートと同じ構成）。この構成では
  「KGP を明示適用している」旨の警告が 1 件残るが、これは AGP 側の同梱 Kotlin が
  上がるまで解消できない。詳細は `docs/OPERATIONS.md`。

## 2026-08-22 — Flutter 3.47.0 に固定し、`pubspec.lock` を作り直した

`flutter pub get --enforce-lockfile` がビルダー上で必ず失敗していた。
`pubspec.lock` は Flutter 3.44 系で生成されていた一方、ビルダーの Flutter は
3.47.0 で、SDK 側が固定する 7 パッケージ（`intl` / `matcher` / `meta` /
`test` / `test_api` / `test_core` / `vector_math`）が食い違っていたため。

### 変更

- `pubspec.lock` を Flutter 3.47.0 / Dart 3.13.0 で再生成。
- `pubspec.yaml` の `environment` を `flutter: ">=3.47.0"` /
  `sdk: ">=3.13.0 <4.0.0"` に更新。
- `.github/workflows/quality.yml` の `flutter-version` を 3.47.0 へ。
- `azure-pipelines.yml` が `FLUTTER_VERSION` を宣言しながら使わず、
  流動的な `stable` ブランチを clone していたのを直した。5 か所すべてが
  `--branch $(FLUTTER_VERSION)` を使う。固定値を宣言していても clone が
  `stable` を追う限り、lock は Flutter が stable を進めた時点で必ず腐る。
- 依存解決を `flutter pub get --enforce-lockfile` に統一した
  （`scripts/ci.sh` / `scripts/build.sh` / `.github/workflows/build.yml` /
  `azure-pipelines.yml` の 5 ジョブ）。lock のズレを黙って上書きせず、必ず
  失敗させる。配布物を作る経路が、品質ゲートで検証していない依存で
  ビルドされることを防ぐ。
- `analysis_options.yaml` の除外に `android/` などのプラットフォームディレクトリ。
  Flutter 3.47 の `pub get` が自動で足すもので、外しても書き戻される
  （実際に消して `pub get` を走らせ、復活することを確認済み）。
- Dart 3.13 の `dart format` に合わせて 5 ファイルを再整形（メソッド連鎖の
  改行位置が変わった）。挙動は変わらない。
- ADR の番号重複を解消した。`0003` が 2 つあったため、後から入った
  Riverpod 統一の ADR を `0004-riverpod-unification.md` に採番し直し、
  参照 4 か所を追随させた。`0003-build-in-dev-container.md` は据え置き。

固定バージョンの定義場所と上げ方は `docs/OPERATIONS.md`
「Flutter のバージョン固定と `pubspec.lock`」にまとめた。

## 2026-08-21 — 画面の状態管理を Riverpod に統一

判断の経緯は `docs/adr/0004-riverpod-unification.md`。

### 削除

- `lib/presentation/viewmodels/`（`ChangeNotifier` ViewModel 5 本）と
  `lib/presentation/app_scope.dart`（`InheritedWidget`）。状態管理の入り口が
  Riverpod と 2 系統あったのを 1 つにするため。

### 追加

- `lib/presentation/providers/theme_providers.dart` — `themeModeProvider`。
- `lib/presentation/providers/language_providers.dart` — `appLanguageProvider`
  と、そこから `Locale` を導く `appLocaleProvider`。
- `lib/presentation/providers/debug_providers.dart` — `debugModeProvider` と
  `logLevelProvider`。デバッグ表示とログレベルは別々に watch できる。
- `lib/presentation/providers/app_info_providers.dart` — `appInfoProvider`。
  About と Debug が同じビルド情報を共有する（旧 `AboutViewModel` /
  `DebugViewModel` はほぼ同一のコードだった）。Riverpod 3 の自動リトライは
  無効化し、失敗は 1 回だけ表示する。

### 変更

- `provider_overrides.dart` がユースケース 14 本すべての注入先になった。
  画面の状態を持つ provider はそこから自分で組み立てるので、合成ルートは
  UI の状態を知らない。
- `AppWidget` は `ConsumerStatefulWidget` になり、`themeMode` / `locale` を
  `ref.watch` で読む。サービスロケータ参照と `ListenableBuilder` が消えた。
- テーマ・言語の保存は「保存が成功してから state を進める」形になった。
  以前は `await` の前に値を書き換えており、保存に失敗すると画面に
  保存されていない値が残っていた。
- About / Debug のエラー表示が翻訳キー（`commonError`）になった。
  以前はハードコードされた英語メッセージ。
- `TestScope` が `ProviderContainer` を持つ。ウィジェットテストは実際の
  notifier を動かし、`scope.container.read(...)` で状態を読む。

## 2026-08-05 — 自己更新後の再実行が終了コード 126 で落ちる問題の修正

- `scripts/build-remote-container.sh` の自己更新後の再実行を、ファイルを直接
  実行する形から「今動いている bash に自分自身を渡す」形へ変更。ホスト上の
  コピーに実行権が無い場合（共有フォルダ経由で置くと 0644 になりがち）に
  `/usr/bin/env: bad interpreter: Permission denied`（終了コード 126）で
  ビルドが始まらないまま落ちていたため。あわせて、差し替えるファイルには
  元の権限に加えて実行権も付ける（元の権限をそのまま引き継ぐと、実行権の
  無い状態が更新のたびに引き継がれるため）。実行権は読み取りを許可している
  相手にだけ付けるので、`0640` のような絞った権限は `0750` にとどまる。

## 2026-08-03 — 配布物ビルドのスクリプト化

判断の経緯は `docs/adr/0003-build-in-dev-container.md`。

### 追加

- `scripts/build.sh` — APK / AAB をビルドし、`dist/` に配布物一式
  （成果物 + `manifest.env` + `manifest.sha256`）を書き出す。`apk` / `aab` /
  `all` の指定と、`BUILD_MODE` / `BUILD_NUMBER` に対応。
  `android/key.properties` に `storeFile` が無い release ビルド（＝Gradle が
  debug 鍵へフォールバックするビルド）は警告し、manifest に
  `signing=debug-keystore` を残す。
- `scripts/build-remote-container.sh` — git も Flutter も無い配布先ホスト向けの
  一括ビルド（SYNC → BUILD → PICK → VERIFY → PUBLISH）。同一ホスト上の dev
  コンテナで `git pull` と `build.sh` を実行し、`dist/` を一時ディレクトリへ
  取り込み、チェックサムが通ってから入れ替える（照合が通るまで前回の配布物を
  残す）。実行のたびに自分自身を最新版へ差し替える。
- `scripts/build-remote-container.env.example` — 上記の設定雛形。

### 変更

- `build.sh` はビルド後に `lib/shared/build_info.dart` をビルド前の内容へ戻す
  （未コミットの変更を持っていた場合はその内容へ）。生成物でありながら
  コミット対象のため、汚れたままだとビルドホストの次回の `git pull --ff-only`
  が失敗するため。
- `scripts/generate_build_info.sh` が `BUILD_NUMBER` を受け付けるようになった。
  未指定なら従来どおりコミット数。`build.sh` は `flutter build --build-number`
  と同じ値を渡すため、About 画面の build number と成果物の versionCode・
  `manifest.env` が食い違わない。
- `.gitignore` に `dist/` を追加。

## 2026-08-03 — 初期スタックの確定と App Links 対応

判断の経緯は `docs/adr/0002-starter-stack.md`。

### 追加

- ブックマーク機能（サンプル）— `go_router` / `flutter_riverpod` / `sqflite` /
  `path` / `url_launcher` を 4 層すべてに通す題材。一覧・詳細・追加・削除・
  外部リンク起動。
  - Domain: `Bookmark` / `BookmarkDraft` / `BookmarkId` / `BookmarkRepository`
  - Application: 5 つのユースケースと `ExternalLinkLauncher` ポート
  - Infrastructure: `AppDatabase`（スキーマ + マイグレーション）、
    `SqfliteBookmarkRepository`、`UrlLauncherExternalLinkLauncher`
  - Presentation: `BookmarksPage` / `BookmarkDetailPage` と
    `presentation/providers/` の Riverpod provider
- Android App Links の基礎 — `autoVerify` 付き intent filter、カスタムスキーム、
  `flutter_deeplinking_enabled`、`assetlinks.json` の雛形、診断画面（`/link`）。
  手順は `docs/DEEP_LINKS.md`。
- `lib/presentation/navigation/app_routes.dart` — 公開 URL とアプリ内ルートの
  唯一の定義元。
- `lib/app/di/provider_overrides.dart` — サービスロケータと Riverpod の橋渡し。

### 変更

- ルーティングを `Navigator.onGenerateRoute` から `go_router` に移行
  （`MaterialApp.router`）。これによりプラットフォームから届くリンクが
  通常の遷移と同じ経路で解決される。
- `minSdk` を 36 に統一。`flutter_launcher_icons.min_sdk_android` が 21 のまま
  食い違っていたのを解消。
- `url_launcher` を `tool/check_architecture.dart` の Infrastructure 限定
  package に追加。
- 起動時に SQLite を開くようになった（`InfrastructureModule.create`）。
- `dependency_policy.reserved` が空になった（宣言済み依存はすべて使用中）。

### 削除

- `equatable`、`riverpod_annotation`、`riverpod_generator`。

## 2026-08-03 — CI 品質ゲートの導入とツールチェイン更新

### 追加

- `scripts/ci.sh` — 整形・静的解析・アーキテクチャ検査・依存関係検査・
  テスト・カバレッジ下限・デバッグ APK ビルドを 1 コマンドで実行。
  規約違反時は非ゼロ終了。`--fast` / `--keep-going` / `--help` に対応。
  コード生成を使うプロジェクトでは `build_runner build` と
  `git diff --exit-code` も自動的に実行される。
- `tool/check_architecture.dart` — Analyzer の AST を走査してレイヤー規約を強制。
  依存方向、レイヤー別の禁止 import / 禁止型、Domain での `DateTime.now()` /
  `print` / `debugPrint`、Domain 型の `ChangeNotifier` 継承と public setter、
  具象アダプターへの依存を検出する。
- `tool/check_dependencies.dart` — `pubspec.yaml` と `lib/` の import を突き合わせ、
  未宣言依存・未使用依存・古い予約記載を検出。`packages/` にレイヤーを分割した
  場合は pubspec レベルの依存方向も検査する。
- `tool/check_coverage.dart` — `lcov.info` を読んで Domain 90% /
  Application 85% / 全体 80% を強制。
- `.github/workflows/quality.yml` — PR と main への push で `scripts/ci.sh` を実行。
  リリース・タグ・マージ運用には触れない。
- `test/coverage_surface_test.dart` — `lib/` の全ライブラリを import し、
  どこからも参照されていないファイルが計測対象から消えて全体カバレッジが
  実態より高く出るのを防ぐ。
- `test/support/` — Repository の in-memory fake、`AppLogger` の記録用ダブル、
  `AppScope` を組んだウィジェットテスト用ハーネス。
- `test/tool/` — 検査ツール自体のテスト。各ルールについて、違反を含む
  フィクスチャで非ゼロ終了することを確認する。
- `docs/adr/0001-single-package-layers.md` — 単一パッケージ構成を選んだ理由。

### 変更

- Flutter 3.44.8 / Dart 3.12 に更新し、依存パッケージを最新メジャーへ。
  `CardTheme` → `CardThemeData` の破壊的変更に追従。
- Android ツールチェインを Gradle 8.14.3 / AGP 8.11.1 / Kotlin 2.2.20 に更新。
  Gradle 8.3 は Flutter 3.44 の最低要件 8.7 を下回りビルドできなかった。
  非推奨の `Project.buildDir` と、AGP 8 で無効な `android.enableJetifier` を除去。
- レイヤー構成を整理。`lib/shared/` に混在していた値オブジェクト・エンティティ・
  エラー・ログ契約・テーマ・i18n を、それぞれ domain / application / presentation へ移動。
  `lib/shared/` はフレームワーク非依存の定数のみになった。
- `AppInfoRepository` が Application の DTO を返していた（Domain → Application の
  逆流）のを、Domain エンティティ `AppInfo` に変更。
- `AppLogger` ポートの `logFiles()` を `logFilePaths()` に変更し、`dart:io` の
  `File` を Application から排除。
- Presentation が合成ルートを import していたのをやめ、ViewModel は
  コンストラクタ注入、画面は新設の `AppScope`（`InheritedWidget`）から取得する形に。
- 合成ルートが `SharedPreferences` を直接扱っていたのをやめ、
  `InfrastructureModule` がアダプターを組み立てて Domain インターフェースだけを返す。
- `analysis_options.yaml` を強化。`strict-casts` / `strict-inference` /
  `strict-raw-types`、未使用 import・dead code・型不整合を error 扱い。
  併用できない `prefer_relative_imports` を外し `always_use_package_imports` に統一。
- カバレッジを Domain 100% / Application 100% / 全体 90% まで引き上げ。

### 削除

- `test/domain/app_colors_test.dart` — `test/presentation/theme/` の同名テストと
  内容が重複していた旧配置。
