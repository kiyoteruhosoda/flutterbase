# 新しいアプリへの移植ガイド

このテンプレートを別のアプリに流用するときに変更が必要な箇所をまとめます。
英語版の詳細は [`CUSTOMISATION.md`](./CUSTOMISATION.md) を参照してください。

---

## クイックスタート（6ステップ）

```bash
# 1. パッケージ名・Android ID の一括リネーム
scripts/rename_app.sh my_cool_app com.mycompany.coolapp

# 2. アイコン差し替え後に再生成
dart run flutter_launcher_icons

# 3. 動作確認
flutter clean && flutter pub get
dart analyze --fatal-infos --fatal-warnings
flutter test
```

残りの変更（アプリ名・色・アイコン画像）は下表を参照。

---

## 変更箇所一覧

### 1. アプリ識別情報（必須）

**`lib/shared/config/app_config.dart`** — ここが Dart 側の唯一の情報源

| フィールド | 現在の値 | 変更内容 |
|---|---|---|
| `appName` | `'FlutterBase'` | 新しいアプリの表示名 |
| `appDescription` | `'Flutter base app ...'` | アプリの説明文（About ページに表示） |
| `appTagline` | `'DADS Design System'` | ドロワーのサブタイトル |
| `homeSubtitle` | `'DADS Design System App'` | ホーム画面のサブタイトル |
| `homeCardTitle` | `'DADS Design System'` | ホームの最初のカードタイトル |
| `designSystemLabel` | `'DADS v2.10.3'` | デザインシステム名（About ページ） |
| `designSystemName` | `'Digital Agency Design System ...'` | ライセンス登録名 |
| `designSystemUrl` | `'https://design.digital.go.jp/'` | デザインシステムの URL |
| `designSystemLicense` | `'CC BY 4.0'` | ライセンス種別 |

**`pubspec.yaml`**

| 行 | フィールド | 変更内容 |
|---|---|---|
| 1 | `name:` | Dart パッケージ名（`rename_app.sh` が自動変更） |
| 2 | `description:` | アプリの説明文 |
| 4 | `version:` | バージョン番号 |

**`android/app/src/main/AndroidManifest.xml`**

```xml
<!-- line 4: ホーム画面に表示されるアプリ名（rename_app.sh は変更しない） -->
android:label="FlutterBase"  →  android:label="新しいアプリ名"
```

**`android/app/build.gradle`**（`rename_app.sh` が自動変更）

```groovy
def appNamespace     = "com.example.flutterbase"   // → 新しい namespace
def appApplicationId = "com.example.flutterbase"   // → 新しい applicationId
```

---

### 2. ブランドカラー（必須）

3 箇所を同じ色に揃える必要があります。

**`lib/shared/theme/app_colors.dart`** line 91

```dart
static const Color brand = blue800;  // → 新しい Color(0xFFxxxxxx)
```

**`pubspec.yaml`** line 84

```yaml
adaptive_icon_background: "#264AF4"  # → 新しいブランドカラーの hex
```

**`android/app/src/main/res/values/colors.xml`** line 9

```xml
<color name="ic_launcher_background">#264AF4</color>  <!-- → 新しい hex -->
```

> この 3 箇所が一致していないと、アダプティブアイコンの背景と Android 12 以降の
> スプラッシュ画面の背景色がズレます。

---

### 3. ランチャーアイコン（必須）

1. `assets/icon/app_icon.png` を差し替え（1024×1024 px、正方形）
2. `assets/icon/app_icon_foreground.png` を差し替え（1024×1024 px、透過、中央 66% に収める）
3. ブランドカラーを上記 §2 の通り更新
4. ジェネレーターを実行

```bash
dart run flutter_launcher_icons
```

生成されたファイル（`android/app/src/main/res/mipmap-*/`）をコミットしてください。

---

### 4. UIテキスト（必要に応じて）

**`lib/shared/l10n/app_strings.dart`**

ナビゲーション・ボタン・エラーメッセージなど、ユーザーに表示される全文字列がここに集約されています。  
アプリ固有のコピーに書き換えてください。

> アプリ名・説明文などのアイデンティティ情報は `AppConfig` にあります（`app_strings.dart` には置かないこと）。

---

### 5. ルーティング（新画面追加時）

**`lib/app/bootstrap/app_router.dart`**

現在のルート一覧：

| 定数 | パス | 用途 |
|---|---|---|
| `AppRouter.main` | `/` | メイン画面 |
| `AppRouter.about` | `/about` | About ページ |
| `AppRouter.debug` | `/debug` | デバッグ情報（開発時のみ） |
| `AppRouter.logs` | `/logs` | ログ画面（開発時のみ） |

新しい画面を追加する場合はここに定数とルートを追加します。

---

### 6. ドメインロジック（新機能追加時）

`.claude/skills/` のスキルを参照して実装します：

| スキル | 用途 |
|---|---|
| `add-entity.md` | ドメインエンティティの追加 |
| `add-repository.md` | リポジトリの追加 |
| `add-usecase.md` | ユースケースの追加 |
| `add-widget.md` | UI ウィジェットの追加 |
| `implement-feature.md` | 機能をエンドツーエンドで実装 |

---

## 確認コマンド

カスタマイズ後に実行して問題がないか確認します。

```bash
flutter clean && flutter pub get
dart analyze --fatal-infos --fatal-warnings
flutter test

# アイデンティティが残っていないか確認
grep -rn "'FlutterBase'"        lib/ test/   # AppConfig のみのはず
grep -rn "'DADS Design System'" lib/ test/   # AppConfig のみのはず
```

---

## チェックリスト

| 変更箇所 | ファイル | 自動化 |
|---|---|---|
| Dart パッケージ名 | `pubspec.yaml` + 全 import | `rename_app.sh` |
| Android namespace / applicationId | `android/app/build.gradle` | `rename_app.sh` |
| Android ランチャーラベル | `AndroidManifest.xml` | **手動** |
| アプリ表示名・説明・タグライン | `lib/shared/config/app_config.dart` | **手動** |
| ブランドカラー | `app_colors.dart`, `colors.xml`, `pubspec.yaml` | **手動（3 箇所一致必須）** |
| ランチャーアイコン PNG | `assets/icon/*.png` | **手動** → `dart run flutter_launcher_icons` |
| pubspec `description` / `version` | `pubspec.yaml` | **手動** |
| UIテキスト | `lib/shared/l10n/app_strings.dart` | **手動** |
| iOS 設定 | 未対応（`ios/` ディレクトリなし） | — |
