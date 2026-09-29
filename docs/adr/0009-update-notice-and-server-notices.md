# 0009. 新しい版の知らせとサーバーからのお知らせを、対の Web の API から読む

- 状態: 採用
- 日付: 2026-09-29

## 文脈

deck で作ったアプリは、対の Web（fastapitemplate 型）と同じ assay の口座で入る
（ADR-0007 / ADR-0008）。使う人に伝えたいことが 2 種類ある:

1. **新しい版が出た。** アプリは share.nolumia.com から APK で配るので、ストアの
   更新通知が無い。photonestapp は自前で知らせている（photonestapp ADR-0038）が、
   雛形には無く、派生のたびに書き写すことになる
2. **運用側からのお知らせ**（止める予定・新しい機能など）。Web には通知の仕組みが
   入った（fastapitemplate ADR-0047: `/api/notifications`、バナー／ベル／Web Push の
   チャネル）。アプリでも同じものを見たい

どちらも「サインインした人」に向けたもので、対の Web はアプリのアクセストークンを
`Authorization: Bearer` で受け取れる（`/api/app/me` と同じ。`APP_CLIENT_IDS`）。
雛形には、そのトークンで対の Web を呼ぶ部品がまだ無かった（`AuthSession.accessToken()`
のポートだけ。docs/CUSTOMISATION.md）。

## 決定

**どちらも対の Web の API から、サインインした人のトークンで読む。** サインインが
無いビルド・サインインしていない間は、何もしない（呼ばない・出さない）。

- **呼ぶ部品**: `WebApiClient`（Infrastructure）。`AuthSession.accessToken()` のトークンを
  付け、401 なら 1 度だけ `forceRefresh` で取り直して再送する。宛先は
  `https://<APP_LINK_HOST>`（`SignInSettings.webBaseUrl`。サインインの戻り先と同じ Web）
- **新しい版**: `GET /api/app-release/latest`（fastapitemplate ADR-0048）。Web は
  リリースの道具が APK の隣に置く `latest.json` を読んで答える。比べるのは **`build`**
  （Android の versionCode）と、このビルドの `BuildInfo.buildNumber`——`scripts/build.sh`
  が `flutter build --build-number` に渡すのと同じ値を焼く。`version` は表示にだけ使う
  - サーバーの `build` が大きければ、メイン画面の上に MaterialBanner
    「新しい版 {version} があります」と「ダウンロード」「閉じる」を出す。
    `download_url` が無ければ「ダウンロード」は出さない。ダウンロードは外部ブラウザで開く
    （`ExternalLinkLauncher`）
  - **「閉じる」はその build だけを消す。** 閉じた build 番号を shared_preferences に
    1 つ覚え、それより新しい build が出たらまた出す
  - 失敗（届かない・サインインが切れた・形が違う）は**何も出さない**。ログに warning を残す
- **お知らせ**: `GET /api/notifications` と `POST …/{id}/read`・`…/read-all`・
  `…/{id}/dismiss`（fastapitemplate ADR-0047）
  - ヘッダーのベルに未読数（`unread_count`）。押すと下から一覧（チャネルに `bell` を
    含むもの）。未読は太字と点。押すと既読にしてリンクを開く
  - バナー: チャネルに `banner` を含み `dismissed_at` が空のうち、いちばん新しい 1 件。
    押すとリンクを開いて閉じる（dismiss）。「閉じる」も dismiss。**新しい版のバナーが
    あればそちらを優先する**（出すのは常に 1 本）
  - リンクは `https://…` ならそのまま、`/items` のような Web のパスは
    `https://<APP_LINK_HOST>/items` にして外部ブラウザで開く（アプリにその画面は無い）。
    それ以外（`http:`・`javascript:` など）は開かない
  - 状態は**サーバーが受け付けてから**進める（既存の画面と同じ規則）
- **いつ読むか**: 起動時、サインインした直後、アプリが前面に戻ったとき。前面に戻るたびに
  読まないよう、自動の分は **5 分**あける（`minInterval`）。起動・サインイン・ベルを
  開いたときはあけずに読む。サインアウトしたら表示を捨てる
- 置き場所は既存の層のとおり: Domain（`AppRelease`・`AppNotice`・リポジトリの形）、
  Application（ユースケース）、Infrastructure（`WebApiClient`・`WebApi…Repository`・
  `SharedPreferencesDismissedUpdateRepository`）、Presentation（`availableUpdateProvider`・
  `noticeInboxProvider`・`NoticeBanner`・`NoticeBellButton`）

## 理由

- **新しい版の出所を Web にする。** `latest.json` は share.nolumia.com に公開されて
  いるが、アプリから直接読むと「どの URL を読むか」をアプリごとに焼くことになる。
  対の Web はもう宛先として持っている（`APP_LINK_HOST`）ので、足す設定が無い。
  Web 側は同じ値をブラウザ向けの案内にも使える
- **比べるのは build。** version の文字列比較（`1.10.0` と `1.9.0`）を避けられ、
  リリースの道具が単調に増やす値なので「新しい」の意味が一つに決まる
- **閉じるのを build ごとにする。** 1 回閉じたら二度と出ない、にすると次の版を
  知らせられない。毎回出す、にすると入れられない事情のある人を毎回邪魔する
- **失敗は黙る。** 知らせは親切であって、出せないことを画面のエラーにする理由が無い
- **ベルはサインインしていないと出さない。** これまでの雛形のベルは押しても何も起きない
  飾りだった。鳴ることの無いベルは置かない

採らなかった案:

- **FCM（端末への push）で届ける** ——アプリを開いていないときにも届くが、Firebase の
  プロジェクト・google-services.json・Web 側の送信が要る。**task #59 で別に入れる。**
  ここで入れた一覧・既読・dismiss はそのまま使える
- **Web Push のエンドポイントを使う** ——ブラウザ専用（Service Worker）で、アプリには
  使えない
- **お知らせにアプリ内の画面（ルート）を作る** ——一覧は下から出るシートで足りる。
  ルートを足すと router・ディープリンクの面も増える

## 影響

- 依存は増えない（`http` はサインインで入っている）
- 対の Web が ADR-0047 / ADR-0048 の API を持っていないと、どちらも**何も出ない**
  （404 は失敗として黙る）。古い Web と組んでも壊れない
- ヘッダーのベルは、サインインの無いビルドとサインインしていない間は出なくなった
- 端末への push（アプリを閉じているときに届く）は task #59
