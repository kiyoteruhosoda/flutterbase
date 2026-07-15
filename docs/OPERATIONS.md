# Operations

この文書は、デプロイ・リセット・マイグレーションなど、運用時に発生しやすい事象の一次切り分け手順をまとめます。

## デプロイ時の確認観点

デプロイは次の境界ごとに分けて確認します。

| 境界 | 確認対象 | 代表的な失敗 |
|---|---|---|
| Image | 実行イメージと revision | 古い image、想定外の tag |
| Runtime | ホスト kernel / cgroup / libc | バイナリ互換性不足 |
| Database | 起動状態 / healthcheck | 初期化待ち、volume 破損 |
| Migration | migration ツール / schema | migration binary の起動失敗、SQL エラー |

境界を分けることで、単一の巨大な `if` / `switch` 的な切り分けではなく、責務ごとの Strategy として原因を特定しやすくします。

## MariaDB reset 後に `sqlx: GLIBC_2.39 not found` が出る場合

### 症状

`./deploy.sh reset` などで DB volume を削除し、MariaDB の healthcheck が `healthy` になった後、migration フェーズで次のエラーが出ます。

```text
sqlx: /lib/x86_64-linux-gnu/libc.so.6: version `GLIBC_2.39' not found (required by sqlx)
DB migration failed after 3 attempts
```

この場合、MariaDB 自体は起動できています。失敗している境界は **Database** ではなく **Migration runtime** です。

### 原因

`sqlx` CLI バイナリが、実行コンテナまたはホストに入っている glibc より新しい glibc を要求しています。

典型例:

* Ubuntu 24.04 など glibc 2.39 系で build した `sqlx` を、Debian bookworm / bullseye 系の image で実行している
* CI で作った `sqlx` バイナリを、NAS や古い distro ベースのコンテナへコピーしている
* migration image と builder image の OS 世代が揃っていない

### 推奨対応

migration image の中で、実行環境と同じ libc 世代に合わせて `sqlx` を build / install してください。DDD の境界で考えると、migration 実行は API や Web とは別の Infrastructure concern なので、専用 image に閉じ込めるのが安全です。

推奨方針:

1. `sqlx` をホストや別 OS 世代の CI artifact からコピーしない
2. `migrate` service の Dockerfile 内で `cargo install sqlx-cli --no-default-features --features mysql` を実行する
3. builder stage と runtime stage の distro 系統を合わせる
4. どうしても単体バイナリを配布する場合は、配布先より古い glibc で build する

例:

```dockerfile
FROM rust:1-bookworm AS builder
RUN cargo install sqlx-cli --locked --no-default-features --features mysql

FROM debian:bookworm-slim AS migrate
COPY --from=builder /usr/local/cargo/bin/sqlx /usr/local/bin/sqlx
COPY migrations /app/migrations
WORKDIR /app
CMD ["sqlx", "migrate", "run"]
```

builder と runtime をどちらも bookworm 系にしておくと、`sqlx` が要求する glibc と runtime の glibc がずれにくくなります。

### 確認コマンド

migration コンテナ内で次を確認します。

```sh
ldd --version
sqlx --version
ldd "$(command -v sqlx)"
```

`ldd` の glibc version が `sqlx` の要求 version より古い場合は、migration image の作り直しが必要です。

### 暫定回避

すぐに復旧が必要な場合は、次のどちらかを選びます。

* runtime と同じ OS 世代の環境で `sqlx` を再 build して image を作り直す
* `sqlx` CLI を使わず、API binary に組み込んだ migration runner など、同一 image 内で build 済みの実行経路へ切り替える

ただし、ホストへ新しい glibc を手動導入する対応は推奨しません。NAS や appliance 系環境では OS 全体の互換性を壊すリスクがあります。
