# 0012. 新しい版を Google Play の仕組み（In-App Updates）で知らせて入れる

- 状態: 採用
- 日付: 2026-11-03
- 関係するもの: [0009](0009-update-notice-and-server-notices.md)、
  photonestapp ADR 0048（同じ形の手本）、task #854

## 文脈

この雛形から作ったアプリは、deck の配る段で share.nolumia.com と Google Play の内部テストの
両方へ出る。Play から入れた人には、Play が裏で自動更新するが、入るのは Wi-Fi と充電中のときが
多く、新しい版が出たことはアプリの中から分からない。

ADR-0009 の「新しい版」バナーは対の Web の `latest.json` を読み、APK のダウンロードを
ブラウザで開く。サインインが無いと出ず、入手先は share.nolumia.com（持ち主のログインの後ろ）。
Play から入れた人にとって、入手先は Play そのものの方がよい。

持ち主「アップデート通知の仕組み入れたい。photonestみたいな。baseにも入れたい」（2026-11-03）。

## 決定

- 起動したとき（メイン画面の最初のフレーム）と前面に戻ったときに Play に聞く
  （`in_app_update` の `checkForUpdate`）。**サインインの有無に関わらず**聞く。
  新しい版があれば、メイン画面の上にバナーを出す。
- 「更新」で Play の確認を出し、裏でダウンロードする（flexible）。済んだら「再起動」で入れる。
  画面を覆う immediate は使わない。断られたら「更新」に戻す。
- 閉じる口は無い。入れれば消える。
- Play 以外から入れた版（share.nolumia.com の APK・手元のビルド）と、Play に聞けないときは、
  何も出さない（Play が誤りを返すのを黙って「無し」とする。ログは debug）。
- **バナーは常に 1 本。** Play の新しい版 → 対の Web の新しい版（ADR-0009）→ サーバーの
  お知らせ、の順で 1 つだけ出す。Play の版はその場で入れられるので、同じ版を知らせる
  Web の方より先にする。
- 形: ポート `StoreUpdateGateway`（Application）、`PlayStoreUpdateGateway`
  （`lib/infrastructure/store/`）、ユースケース `Check/Download/InstallStoreUpdateUseCase`、
  画面の状態 `storeUpdateProvider`（none / available / downloading / downloaded）と
  `StoreUpdateBanner`。`NoticeBanner` が先に見る。

## 理由

- **比べるのは Play。** アプリは版の番号を持たない。Play の版と端末の版を Play 自身が比べる
- **サインインと切り離す。** Play に聞くのに対の Web は要らない。サインインの無い派生アプリ
  でも動く
- **Web の知らせは残す。** share.nolumia.com の APK で入れた人には、Play は答えない。
  そちらは ADR-0009 が受け持つ。両方出ると同じ版を 2 回知らせるので、Play を先にして 1 本に
  する

## 影響

- 依存 `in_app_update`（Infrastructure だけ。`tool/check_architecture.dart` の禁止一覧にも
  足した）。photonestapp と同じ版で、AGP 9.1 の release ビルドが通ることを確かめてある
- 試験は偽物の `FakeStoreUpdateGateway`（既定は「無し」）。実機の Play の流れは、内部テストに
  出したアプリで初めて通る（Play が「新しい版」と答えるのは、Play から入れた版より新しい版が
  同じトラックにあるときだけ）
- Play Console 側の設定は要らない
