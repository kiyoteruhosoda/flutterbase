# Architecture

このプロジェクトは DDD + OOP + SOLID + DI を前提とした Flutter アプリのテンプレートです。
本書は「どのコードがどこに属するか」と「その規約を CI がどう強制するか」を定義します。

規約の一覧は `.claude/rules/architecture.md`、実際の検査は
`tool/check_architecture.dart` と `tool/check_dependencies.dart` にあります。
**本書と検査コードが食い違った場合、検査コードが正**です（CI が落ちるのはそちらなので）。

## レイヤー

`lib/` 直下のディレクトリがそのままレイヤーです。

| ディレクトリ | 役割 | Flutter 依存 |
|---|---|---|
| `lib/domain/` | エンティティ・値オブジェクト・ドメインエラー・リポジトリ *インターフェース* | 不可 |
| `lib/application/` | ユースケース、外向きポート (`ports/`) | 不可 |
| `lib/infrastructure/` | 外部システムのアダプター（永続化・プラットフォーム・ネットワーク） | 可 |
| `lib/presentation/` | 画面・ウィジェット・ViewModel・テーマ・i18n | 可 |
| `lib/app/` | 合成ルート（DI・起動・ルーティング）。`lib/main.dart` も含む | 可 |
| `lib/shared/` | フレームワーク非依存の定数のみ（`AppConfig` / `BuildInfo`） | 不可 |

`lib/shared/` は「どのレイヤーにも属さない定数置き場」であり、**他のどのレイヤーにも依存できません**。
迷ったら shared ではなく、そのコードを必要とするレイヤーに置いてください。

## 依存方向

矢印は常に内向きです。

```
        ┌──────────────┐
        │     app      │  合成ルート: 全レイヤーを見てよい唯一の場所
        └──────┬───────┘
               │ 束ねる
   ┌───────────┼───────────┐
   ▼           ▼           ▼
presentation  infrastructure
   │           │
   └─────┬─────┘
         ▼
    application
         ▼
      domain
         ▼
      shared
```

許可される import は次のとおりです（自分自身を含む）。

| from \ to | domain | application | infrastructure | presentation | app | shared |
|---|---|---|---|---|---|---|
| domain | ✅ | ❌ | ❌ | ❌ | ❌ | ✅ |
| application | ✅ | ✅ | ❌ | ❌ | ❌ | ✅ |
| infrastructure | ✅ | ✅ | ✅ | ❌ | ❌ | ✅ |
| presentation | ✅ | ✅ | ❌ | ✅ | ❌ | ✅ |
| app | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| shared | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ |

**Presentation は `lib/app/` を import できません。** ViewModel は
`presentation/app_scope.dart`（`InheritedWidget`）経由で受け取ります。
合成ルートが `AppScope` に値を注入し、画面はそれを読むだけです。
サービスロケータを画面から直接引く形にすると矢印が外向きに逆転するため、CI で落ちます。

## CI が拒否するもの

`tool/check_architecture.dart` は Dart Analyzer の **AST** を走査します。
文字列検索ではないので、コメントや文字列リテラル中の一致では発火しません。

| ルール | 内容 |
|---|---|
| `layer-direction` | 上表に反する package import |
| `layer-placement` | どのレイヤーにも属さない `lib/**.dart` |
| `banned-import` | Domain / Application からの Flutter・`dart:io`・`dart:ui` import、Infrastructure 以外からの dio・http・sqflite・shared_preferences・path_provider・package_info_plus などの import |
| `infrastructure-only-type` | Infrastructure 以外での `File` / `Directory` / `HttpClient` / `Dio` / `MethodChannel` / `SharedPreferences` / `Database` などの使用（型注釈・コンストラクタ呼び出し・static アクセス） |
| `concrete-adapter-dependency` | Infrastructure と合成ルート以外での具象アダプター（Repository 実装など）への参照 |
| `domain-clock` | Domain での `DateTime.now()` |
| `domain-console-output` | Domain での `print()` / `debugPrint()` |
| `domain-purity` | Domain 型の `ChangeNotifier` / `ValueNotifier` / `Widget` などからの継承・実装 |
| `domain-public-setter` | Domain 型の public setter、および public な可変フィールド（暗黙の setter を持つため） |

`tool/check_dependencies.dart` は package グラフ側を見ます。

| ルール | 内容 |
|---|---|
| `undeclared-dependency` | `lib/` が import しているのに `pubspec.yaml` に無い package |
| `unused-dependency` | `pubspec.yaml` の `dependencies` にあるのに `lib/` が import していない package |
| `stale-reservation` | `dependency_policy.reserved` の記載が実態と合っていない |
| `package-direction` | `packages/` にレイヤーを分割した場合の、pubspec レベルでの依存方向違反 |

### `dependency_policy.reserved` について

本リポジトリはテンプレートなので、生成後のアプリが使う前提の package
（`go_router`・`flutter_riverpod`・`sqflite` など）を最初から宣言しています。
これらは `pubspec.yaml` 末尾の `dependency_policy.reserved` に列挙してあり、
「未使用だが意図的」であることを明示しています。
ここに無い未使用 package は CI で落ちます。

package を実際に使い始めたら、reserved から削除してください（使用中の package が
reserved に残っていても CI が落ちます）。テンプレートを軽くしたい場合は、
reserved の記載と `dependencies` の両方から削除してください。

## パッケージ分割について

レイヤーを別 Dart パッケージ（`packages/domain` など）に分割すると、
pubspec レベルでも依存方向を強制できます。本テンプレートは単一パッケージ構成を
採用しました。理由と、将来分割する場合の手順は `docs/adr/0001-single-package-layers.md`
にあります。`tool/check_dependencies.dart` は `packages/` が現れた時点で
自動的にパッケージ間の方向も検査します。

## 命名

- Repository インターフェースは `domain/repositories/` に `<Concept>Repository`。
- その実装は `infrastructure/repositories/` に `<Technology><Concept>Repository`
  （例: `SharedPreferencesThemePreferenceRepository`）。
- 外向きポートは `application/ports/`（例: `AppLogger`）。
- ユースケースは `application/usecases/<feature>/` に `<Verb><Noun>UseCase`。
- `Helper` / `Util` / `Manager` / `Common` は使いません。ドメイン語彙を使ってください。

## テスト方針

`test/` は `lib/` と同じ構造をとります。共通のテストダブルは `test/support/` です。

- `test/support/fakes.dart` — 各 Repository の in-memory 実装。書き込み内容を記録し、
  失敗も注入できます。
- `test/support/recording_app_logger.dart` — `AppLogger` ポートの記録用ダブル。
- `test/support/test_harness.dart` — `AppScope` + テーマ + i18n を組んだ
  ウィジェットテスト用ハーネス（`pumpInScope` / `pumpComponent`）。

特に次を必ずテストします。

- Domain エンティティの状態遷移、値オブジェクトの不正値
- ユースケースの正常系・異常系
- Repository・外部ポートの呼び出し（記録用ダブルで検証）
- ViewModel の状態遷移

### カバレッジ目標

| 範囲 | 下限 |
|---|---|
| `lib/domain/` | 90% |
| `lib/application/` | 85% |
| 全体 | 80% |

`tool/check_coverage.dart` が `coverage/lcov.info` を読んで強制します。

`flutter test --coverage` は「テストから到達したライブラリ」しか計測しないため、
どこからも import されていないファイルはレポートに現れず、全体の数字が実態より
高く出ます。これを防ぐために `test/coverage_surface_test.dart` が `lib/` の全
ライブラリを import しています。`lib/` にファイルを追加したらこのファイルにも
import を足してください（足し忘れるとテストが落ち、追加すべき行を教えてくれます）。

## 参照

- 操作手順・コマンド: `docs/OPERATIONS.md`
- 設計判断の記録: `docs/adr/`
- 完了した変更の要約: `docs/CHANGELOG.md`
