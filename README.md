# Flutterbase

デジタル庁デザインシステム (DADS v2.10.3) に準拠した Flutter ベースアプリ。

## 概要

| 項目 | 内容 |
|------|------|
| デザインシステム | [デジタル庁デザインシステム v2.10.3](https://design.digital.go.jp/dads/) |
| フレームワーク | Flutter 3.22+ / Dart 3.3+ |
| アーキテクチャ | DDD (Domain-Driven Design) |
| 状態管理 | flutter_riverpod |
| ナビゲーション | go_router |
| ターゲット | Android / iOS |

## 画面構成

```
スプラッシュ画面 (/)
  └─ メイン画面 (/main)
       ├─ メインヘッダー (AppHeader)
       ├─ メインコンテンツ
       ├─ メインフッター (AppFooter)
       └─ ドロワーメニュー (AppDrawer)
            ├─ バージョン情報 (/system/version)
            ├─ ライセンス情報 (/system/licenses)
            └─ デバッグ情報 (/system/debug)
```

## デザイントークン

| クラス | 内容 |
|--------|------|
| `AppColors` | カラースケール (Sumi・Umi・Midori・Ki・Suo) + セマンティックトークン |
| `AppSpacing` | スペーシング (8px ベース: 4・8・12・16・24・32・40・48・64・80px) |
| `AppRadius` | 角丸 (0・2・4・8・12・16・24px・full) |
| `AppTextStyles` | タイポグラフィ (Noto Sans JP / Display・Standard・Dense・Oneline・Mono) |
| `AppTheme` | ライト / ダークテーマ定義 |

## テーマ

ライトモードとダークモードの両方をサポート。システム設定に従い自動切り替え。

## プロジェクト構成

```
lib/
  app/
    bootstrap/    # App + AppRouter
    di/           # Dependency injection
  presentation/
    pages/
      splash/     # スプラッシュ画面
      main/       # メイン画面
      system/     # バージョン・ライセンス・デバッグ
    widgets/
      ui/         # AppPrimaryButton, AppTextField, AppCard, AppStatusBadge
      layout/     # AppHeader, AppFooter, AppDrawer
    viewmodels/   # SplashViewModel, VersionInfoViewModel, DebugInfoViewModel
  shared/
    theme/        # デザイントークン
    errors/       # AppError sealed class
  main.dart
```

## CI/CD (Azure DevOps)

`azure-pipelines.yml` に以下のステージを定義:

| ステージ | トリガー | 成果物 |
|---------|---------|--------|
| validate | 全ブランチ | テスト結果・カバレッジ |
| build_dev | feature/* fix/* claude/* | Debug APK |
| build_stg | develop | Release APK + IPA (unsigned) |
| build_prod | main | Signed APK + AAB + IPA |

## 開発

```bash
# 依存関係インストール
flutter pub get

# コード生成
dart run build_runner build --delete-conflicting-outputs

# フォーマット
dart format lib/ test/

# 静的解析
flutter analyze

# テスト
flutter test

# 実行
flutter run
```