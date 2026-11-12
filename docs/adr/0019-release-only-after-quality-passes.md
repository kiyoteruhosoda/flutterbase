# 0019. 版上げ（＝配布）は、同じ commit の Quality が全部緑になった後だけ

- 状態: 採用
- 日付: 2026-11-12
- 関係するもの: task #994（目的 #993）、ADR-0005（配布は deck）、nolumiadeck ADR-0063・ADR-0119

## 文脈

main への push で、`version_bump.yml`（版を上げて main へ push）と `quality.yml`（検査）が**並んで**走っていた。
deck は main への push の知らせを受け、pubspec の版が変わっていれば焼いて配る。だから検査が赤でも版が上がり、
配られた。2026-11-12、AutoRule の main の Quality（integration-tests）が赤のまま 1.33.0 が配られた。
持ち主「試験が緑のときだけ配る」。

## 決定

1. **版上げを `quality.yml` の最後のジョブ `bump-version` にする。** `needs` で同じ workflow のほかのジョブ全部を待ち、
   全部成功したときだけ動く（1 つでも赤・打ち切りなら skipped）。版上げの push が無ければ deck は配らない。
2. main への push のときだけ実際に版を上げる。PR と手動の Quality では版を上げず、下の 4 の検査だけをする。
3. **CI の設定（`.forgejo/`）だけの push では版を上げない**（2026-10-25 からの決まり）。以前の `paths-ignore` と同じく、
   push の前後の差分が全部 `.forgejo/` の下なら上げない。前の commit が分からないとき（枝の作り直しなど）は上げる。
4. **ジョブを足したら `needs` にも足す。** 足し忘れると、そのジョブが赤でも配られる。`scripts/check_bump_waits_for_quality.py`
   が PR ごとに「`bump-version` がほかの全ジョブを待っているか」を確かめ、ずれていれば落とす。
5. **手動の版上げ（`version_bump.yml` の workflow_dispatch）は残す。** push の引き金だけを外した。
   版を上げて commit・tag・push する手順は `scripts/release_version_bump.sh` 1 本にまとめ、両方から呼ぶ。
6. 自分の版上げの push（利用者 actions-push、CI を飛ばす印付き）で起きた run では何もしない（従来どおり）。

## 理由

- **Forgejo の workflow_run に頼らない。** forge（Forgejo 15）で別の workflow の終わりを引き金にできるかは確かでなく、
  使えても「どの commit の結果か」を後から突き合わせる必要がある。`needs` は同じ run・同じ commit の結果だけを見るので、
  取り違えが起きない。
- 検査の commit の上に版上げを積んで push する。その間に main が進んでいれば push は早送りできずに落ち、
  検査していない commit を配ることは無い（後の push の run が改めて版を上げる）。
- 同じ枝で新しい push が来ると Quality は古い run を打ち切る（`concurrency`）。古い run の版上げも打ち切られるが、
  新しい run が自動の版上げ（前回の tag からの commit を全部見る）で拾う。

## 影響

- 版上げは Quality の終わり（いまは数分〜十数分）まで待つ。その分、配布が遅れる。
- PR の検査が 1 本増える（`Quality / 版上げ…`。PR では待ちの確かめだけで数十秒）。
- 派生アプリにも同じ形を写す（autorule・keep・noticeapp・foodexpiryapp・wbstimer・PlainPad・authapp・QRgen・photonestapp）。
  派生の Quality にジョブが多ければ（integration-tests など）、`needs` にそれも並べる。
