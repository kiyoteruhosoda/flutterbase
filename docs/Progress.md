# Progress

進行中・未着手タスクのみを管理する（完了したら本ファイルから削除し、必要なら `CHANGELOG.md` / `history/` へ移す）。


- 状態: ⬜未着手 / 🚧進行中 / 🟡要判断
- 影響度・重要度・難易度・工数: 大 / 中 / 小
- バックログは「優先」列の昇順（1 が最優先）。

## バックログ

| 優先 | # | 概要 | 状態 | 影響度 | 重要度 | 難易度 | 工数 |
|---|---|---|---|---|---|---|---|
| 1 | 1 | `minSdk = 36` が意図どおりか確認する | 🟡要判断 | 大 | 大 | 小 | 小 |
| 2 | 2 | `dependency_policy.reserved` の 7 package を残すか決める | 🟡要判断 | 中 | 中 | 小 | 小 |


## 詳細

### 1. `minSdk = 36` が意図どおりか確認する

`android/app/build.gradle` の `defaultConfig` が
`minSdk = 36` / `targetSdk = 36` / `compileSdk = 36` になっています。
`minSdk = 36` は「Android 16 以降にしかインストールできない」という意味で、
テンプレートの既定値としてはかなり強い制約です。

一方 `pubspec.yaml` の `flutter_launcher_icons` は
`min_sdk_android: 21` を指定しており、両者が食い違っています。
`compileSdk` / `targetSdk` を上げる際に `minSdk` も一緒に書き換えてしまった
可能性があります。

意図的でなければ `minSdk` だけを下げてください（21 / 24 が一般的）。
`compileSdk` と `targetSdk` は 36 のままで問題ありません。

判断が必要なのでこの変更は行っていません。

### 2. `dependency_policy.reserved` の 7 package を残すか決める

`go_router` / `flutter_riverpod` / `riverpod_annotation` / `sqflite` /
`path` / `url_launcher` / `equatable` は `pubspec.yaml` で宣言されていますが、
`lib/` からは一度も import されていません。

テンプレートとして「生成後のアプリが使う前提の初期スタック」を配っている、
という解釈で `dependency_policy.reserved` に列挙し、
`tool/check_dependencies.dart` が意図的な予約として扱うようにしました
（`docs/ARCHITECTURE.md` 参照）。

テンプレートを軽くしたい場合は、reserved の記載と `dependencies` の両方から
削除してください。いずれも未使用なので、削除しても `lib/` の修正は不要です。
リポジトリ所有者の方針次第なので、判断は保留しています。
