# 0018. ログの保存は、持ち主が開ける場所へ（Android の「保存先を選ぶ」画面と共有）

- 状態: 採用
- 日付: 2026-11-06
- 関係するもの: task #913、keep の ADR（file_picker を使わず `MainActivity` の自前チャネル）

## 文脈

ログ画面（☰ → ログ）の保存ボタンは `PersistentAppLogger.exportLogs()` が `<アプリの documents>/logs/export_*.log`
に書くだけだった。そこはアプリ専用の場所で、ファイルアプリからもパソコンからも見えない。それでも
「ログをファイルに保存しました」と出ていた。持ち主（11/06）「アプリ領域に保存になってる？意味ないのでは」。

## 決定

1. **保存ボタンは Android の「保存先を選ぶ」画面（`ACTION_CREATE_DOCUMENT`）を開く。** 選んだ所（Download、
   Drive のフォルダーなど）へ、その場のログ（画面の一覧と同じ最大 1000 件）を文字のファイルで書く。
   名前の案は `<アプリの id の末尾>-log_<UTC の日時>.txt`（例 `flutterbase-log_20261106_123456.txt`）。
   アプリの名前を前に付けるのは、いくつものアプリのログが Download に並んでも見分けられるように。
   **拡張子は `.log` でなく `.txt`**: エミュレーター（API 34）で確かめると、ファイルアプリは `.log` を叩いても
   何も開かない（その種類を受けるアプリが無い）。`.log` の名前で渡すと「保存先を選ぶ」画面が `.log.txt` に
   書き換え、そちらは文字として開けた。初めから `.txt` にして名前を素直にした。
2. **書けたら、どこへ何という名前で書いたかを出す**（「「Downloads」に flutterbase-log_….txt を保存しました」）。
   場所は端末の中なら `primary:Download/…` からフォルダー名を、それ以外は提供元の名前（「ドライブ」など）を出す。
   どちらも分からなければ名前だけ。**選ぶ画面を閉じたら何も出さない。** 書けなかったら「ログの保存に失敗しました」。
3. **共有ボタンを足す。** ログを `.txt` のファイルにして共有の画面（`ACTION_SEND`）を開く（自分宛てのメール、
   チャット、Drive など）。ファイルは `cache/shared_logs/` に 1 つだけ置き（毎回入れ替え）、`LogFileProvider` が
   その場所だけを、渡した相手に一度だけ読ませる。
4. **どちらも `MainActivity` の `nolumia/log_files` チャネルで作る。** プラグインは足さない。
   `LogFileProvider` は `androidx.core` の `FileProvider` の子クラスにして、派生アプリが別の `FileProvider`
   （keep の添付など）を宣言していてもぶつからないようにする（同じクラス名の `<provider>` は 1 つにまとめられてしまう）。
5. **アプリの中のログファイル（`logs/app_*.log`）は今までどおり。** 起動をまたいだ記録として残す。保存の時に
   アプリの中へ写しを作るのはやめた（`export_*.log` は作らない）。

## 理由

- **自前のチャネル**: `file_picker`（android_file_picker 2.1.3）は buildscript で AGP 8.5.2 を抱え込み、雛形の
  AGP 9 の release ビルドとぶつかる（keep で実測）。`share_plus` も足せば済むが、要るのは Intent 2 つだけで、
  プラグインを足すと Gradle と版上げの手間が増える。
- **選ぶ画面**: Download へ黙って書く（MediaStore）こともできるが、どこに置いたかを持ち主が選べるほうが分かりやすく、
  Drive へ直接置ける。権限も要らない（選んだ 1 つのファイルだけ書ける）。
- **取り消しで何も出さない**: 「保存しました」が出ると、保存されていないのに保存されたと思う（今回の不具合そのもの）。

## 結果

- `AppLogger.exportLogs()` は `Future<LogExportResult>`（`LogExportSaved`・`LogExportCancelled`・`LogExportFailed`）を
  返し、`shareLogs()` が増えた。派生アプリで `AppLogger` を実装している試験の代役は合わせて直す。
- 文言は `logsDownloadSuccess` を `logsSavedTo`・`logsSaved` に替え、`logsShare`・`logsShareError` を足した。
- `android/app/build.gradle` に `androidx.core:core-ktx` を足した（`FileProvider` のため）。共有できる場所は manifest の `<provider>` の meta-data で `res/xml/log_file_paths.xml` を指す。
  ⚠ 子クラスのコンストラクタに `res/xml` を渡す形（1.9 から）は、エミュレーターで `getUriForFile` が IllegalArgumentException になった。
