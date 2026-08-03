# Changelog

完了した重要な変更の短い要約を、新しいものから並べます。
詳しい経緯が必要なものは `docs/history/`、設計判断は `docs/adr/` にあります。

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
