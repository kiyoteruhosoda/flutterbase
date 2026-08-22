# 0004. 画面の状態管理を Riverpod に統一する

- 状態: 採用
- 日付: 2026-08-21
- 関連: `docs/adr/0002-starter-stack.md`（「Riverpod と `get_it` の併存」節を置き換え）

## 文脈

`0002` の時点で、テンプレートには状態管理の入り口が 2 つありました。

- テーマ・言語・デバッグ設定・About・Logs: `ChangeNotifier` ViewModel 5 本を
  `get_it` に登録し、`AppScope`（`InheritedWidget`）で画面へ配る
- ブックマーク: `flutter_riverpod`。provider を Presentation に宣言し、
  合成ルートが `overrideWithValue` で実体を差す

役割は同じ（合成ルートが注入し、Presentation は契約だけを見る）で、どちらも
`tool/check_architecture.dart` を通ります。ただしテンプレートとしては、
fork した開発者が「新しい画面はどちらで書けばいいか」を毎回決めることになります。
同じ問題を 2 通りに解いた例が並んでいる状態は、テンプレートの弱点でした。

## 決定

**Presentation の状態管理を Riverpod に一本化します。** ViewModel 5 本と
`AppScope` を削除し、`lib/presentation/providers/` の provider に置き換えました。

| 削除したもの | 置き換え |
|---|---|
| `ThemeViewModel` | `themeModeProvider`（`Notifier<ThemeMode>`） |
| `LanguageViewModel` | `appLanguageProvider` + `appLocaleProvider` |
| `DebugSettingsViewModel` | `debugModeProvider` + `logLevelProvider` |
| `AboutViewModel` / `DebugViewModel` | `appInfoProvider`（`FutureProvider<AppInfo>`） |
| `AppScope`（`InheritedWidget`） | `ProviderScope` + `provider_overrides.dart` |

`get_it` は合成ルートに残します。役割が違うためです。`service_locator.dart` は
Infrastructure アダプターとユースケースを組み立てる場所、
`provider_overrides.dart` はそれを Presentation の provider に差す場所です。
Presentation 側から見えるのは後者だけで、`get_it` は相変わらず `lib/app/` の外に
出ません。

## 理由

### 一つの書き方だけを示す

テンプレートの価値は「この構成ならこう書く」が一目で決まることです。
provider の宣言と `provider_overrides.dart` への 1 行追加、という手順が
すべての画面で同じになりました。

### 依存の向きは変わらない

`AppScope` で守っていた性質——Presentation は `lib/app/` を import せず、
合成ルートが実体を押し込む——は Riverpod でもそのまま成立します。
provider の本体は `UnimplementedError` を投げるので、override 漏れは
起動時に必ず落ちます。`AppScope.of()` が `FlutterError` を投げていたのと同じ
安全性です。

### 画面ごとの ViewModel を作らずに済む

`AboutViewModel` と `DebugViewModel` は、同じ `GetAppInfoUseCase` を呼んで
同じ 3 状態（loading / loaded / error）を持つだけの、ほぼ同一のコードでした。
`FutureProvider` の `AsyncValue` がその 3 状態そのものなので、2 本とも
`appInfoProvider` 1 本になり、画面は `switch` で描き分けるだけになります。

### 保存してから state を進める

旧 `ThemeViewModel` / `LanguageViewModel` は、`await` の前にフィールドを
書き換えていました。保存に失敗すると、画面には保存されていない値が残ります。
新しい notifier は永続化が成功してから `state` を進めます。ブックマークの
`BookmarkListNotifier` が「storage を単一の真実にする」ためにやっていることと
同じ方針です。

### `appInfoProvider` は自動リトライしない

Riverpod 3 は失敗した provider を指数バックオフで最大 10 回まで再実行します。
ビルド情報は待っても読めるようになる類のものではなく、About / Debug の両画面には
明示的な「再試行」ボタンがあります。そのため `retry` を無効化し、失敗は 1 回だけ
表示するようにしました。

## 結果

- `lib/presentation/viewmodels/` と `lib/presentation/app_scope.dart` は
  なくなりました。`lib/presentation/providers/` が唯一の状態管理の入り口です。
- `AppWidget` は `ConsumerStatefulWidget` になり、`ListenableBuilder` と
  サービスロケータ参照が消えました。`themeMode` と `locale` は `ref.watch`
  で読みます。
- テストハーネス（`TestScope`）は `ProviderContainer` を持ちます。
  ウィジェットテストは実際の notifier を動かし、`scope.container.read(...)` で
  状態を確認できます。
- About / Debug のエラー表示が翻訳キー（`commonError`）になりました。
  以前はハードコードされた英語メッセージでした。
