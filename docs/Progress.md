# Progress

進行中・未着手タスクのみを管理する（完了したら本ファイルから削除し、必要なら `CHANGELOG.md` / `history/` へ移す）。


- 状態: ⬜未着手 / 🚧進行中 / 🟡要判断
- 影響度・重要度・難易度・工数: 大 / 中 / 小
- バックログは「優先」列の昇順（1 が最優先）。

## バックログ

| 優先 | # | 概要 | 状態 | 影響度 | 重要度 | 難易度 | 工数 |
|---|---|---|---|---|---|---|---|
| 1 | 1 | App Link のホストを実ドメインに差し替え、`assetlinks.json` を配信する | ⬜未着手 | 大 | 中 | 小 | 小 |


## 詳細

### 1. App Link のホストを実ドメインに差し替える

テンプレートの既定値は `flutterbase.example.com` で、実在しません。
そのままでは `autoVerify` が失敗し、リンクはブラウザで開きます
（アプリの起動やアプリ内遷移は壊れません）。

fork 後に必要な作業は 3 つで、いずれも `docs/DEEP_LINKS.md` に手順があります。

1. `lib/shared/app_config.dart` の `appLinkHost` を実ドメインにする。
2. `android/app/src/main/AndroidManifest.xml` の `android:host` を合わせる。
3. `docs/deep_links/assetlinks.json` に署名フィンガープリントを入れ、
   `https://<host>/.well-known/assetlinks.json` として配信する。

テンプレート側で決められるのはここまでなので、作業自体は fork 側に残します。
