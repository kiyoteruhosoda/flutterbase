#!/usr/bin/env bash
# Rename the flutterbase template in one shot.
#
# Usage:
#   scripts/rename_app.sh <new_dart_name> <new_android_package>
#
# Example:
#   scripts/rename_app.sh my_cool_app com.mycompany.coolapp
#
# What this script touches:
#   - pubspec.yaml            (name: field only)
#   - lib/**, test/**, integration_test/**  (package:flutterbase/... imports)
#   - android/app/build.gradle (namespace, applicationId)
#   - android/app/src/main/kotlin/...  (MainActivity package + directory layout)
#   - docs/komodo-registration.md      (generated: what the build host needs)
#
# What this script does NOT touch — edit these by hand:
#   - pubspec.yaml `description` and `version`
#   - AndroidManifest.xml `android:label` and the deep-link intent filters
#     (App Link host + custom scheme) — see docs/DEEP_LINKS.md
#   - lib/shared/config/app_config.dart (appName, fontFamily, etc.)
#   - README.md
#   - assets/icon/app_icon.png + app_icon_foreground.png
#   - flutter_launcher_icons: adaptive_icon_background colour in pubspec.yaml
#   - android/app/src/main/res/values/colors.xml (ic_launcher_background)
#   - android/app/debug.keystore (run scripts/generate_debug_keystore.sh once)
#   - android/gradle.properties (optional: app.archivesBaseName override)
#
# Assumptions:
#   - GNU sed (on macOS install via `brew install gnu-sed` then call as `gsed`
#     and set SED=gsed, or adjust the sed -i flags below).
#   - Working tree is clean before running.
#   - Run from the repository root.

set -euo pipefail

SED="${SED:-sed}"

die() { echo "error: $*" >&2; exit 1; }

# ─── Argument parsing ─────────────────────────────────────────────────────
if [[ $# -ne 2 ]]; then
    echo "usage: scripts/rename_app.sh <new_dart_name> <new_android_package>" >&2
    exit 2
fi

NEW_DART_NAME="$1"
NEW_ANDROID_PKG="$2"

# Dart package names: lowercase letters, digits, underscores; must start with letter.
if ! [[ "$NEW_DART_NAME" =~ ^[a-z][a-z0-9_]*$ ]]; then
    die "'$NEW_DART_NAME' is not a valid Dart package name (lowercase, digits, underscores; start with letter)"
fi

# Android package: at least two dot-separated segments, each [a-z][a-z0-9_]*.
if ! [[ "$NEW_ANDROID_PKG" =~ ^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+$ ]]; then
    die "'$NEW_ANDROID_PKG' is not a valid Android package identifier (e.g. com.example.app)"
fi

# ─── Pre-flight ───────────────────────────────────────────────────────────
if [[ ! -f pubspec.yaml ]]; then
    die "pubspec.yaml not found — run this script from the repository root"
fi

if ! git diff --quiet || ! git diff --cached --quiet; then
    die "working tree is dirty — commit or stash changes before running"
fi

OLD_DART_NAME="$(awk '/^name:/ {print $2; exit}' pubspec.yaml)"
# Matches: def appNamespace = "com.example.flutterbase"
OLD_ANDROID_PKG="$(awk -F'"' '/^def appNamespace/ {print $2; exit}' android/app/build.gradle)"

[[ -n "$OLD_DART_NAME"   ]] || die "could not read current Dart package name from pubspec.yaml"
[[ -n "$OLD_ANDROID_PKG" ]] || die "could not read current Android namespace from android/app/build.gradle"

echo "Renaming Dart package:    $OLD_DART_NAME -> $NEW_DART_NAME"
echo "Renaming Android package: $OLD_ANDROID_PKG -> $NEW_ANDROID_PKG"

OLD_KOTLIN_DIR="android/app/src/main/kotlin/$(echo "$OLD_ANDROID_PKG" | tr '.' '/')"
NEW_KOTLIN_DIR="android/app/src/main/kotlin/$(echo "$NEW_ANDROID_PKG" | tr '.' '/')"

[[ -d "$OLD_KOTLIN_DIR" ]] || die "expected Kotlin source at '$OLD_KOTLIN_DIR' but it does not exist"

# ─── 1. pubspec.yaml: name: field ─────────────────────────────────────────
$SED -i.bak "1s|^name: $OLD_DART_NAME$|name: $NEW_DART_NAME|" pubspec.yaml

# ─── 2. Dart import cascade ──────────────────────────────────────────────
# Rewrite every `package:<old>/...` reference in lib/, test/, integration_test/.
find lib test integration_test -type f -name '*.dart' -print0 \
    | xargs -0 $SED -i.bak "s|package:${OLD_DART_NAME}/|package:${NEW_DART_NAME}/|g"

# ─── 3. android/app/build.gradle: appNamespace + appApplicationId ────────
# Rewrites the two string constants at the top of the file; namespace and
# applicationId inside the android { } block reference these via Groovy
# variables, so they update transitively.
$SED -i.bak \
    -e "s|^def appNamespace     = \"$OLD_ANDROID_PKG\"|def appNamespace     = \"$NEW_ANDROID_PKG\"|" \
    -e "s|^def appApplicationId = \"$OLD_ANDROID_PKG\"|def appApplicationId = \"$NEW_ANDROID_PKG\"|" \
    android/app/build.gradle

# ─── 4. Move Kotlin source tree ──────────────────────────────────────────
mkdir -p "$(dirname "$NEW_KOTLIN_DIR")"
# Guard against moving a directory into itself, which occurs when the new
# package is a child of the old one (e.g. com.example.app ->
# com.example.app.sub).  In that case git mv fails because Git cannot move
# a directory inside itself; stage the move via a temporary path instead.
if [[ "$NEW_KOTLIN_DIR" == "$OLD_KOTLIN_DIR/"* ]]; then
    TEMP_KOTLIN_DIR="$(mktemp -d)"
    # Ensure the temp dir is removed on any exit (normal, error, or signal).
    # Note: this two-step approach (copy → git rm → git add) loses per-file
    # Git rename history for the affected Kotlin files; this is an inherent
    # trade-off when git mv cannot move a directory into a subdirectory of itself.
    trap 'rm -rf "$TEMP_KOTLIN_DIR"' EXIT ERR
    cp -r "$OLD_KOTLIN_DIR/." "$TEMP_KOTLIN_DIR/"
    git rm -r --quiet "$OLD_KOTLIN_DIR"
    mkdir -p "$NEW_KOTLIN_DIR"
    cp -r "$TEMP_KOTLIN_DIR/." "$NEW_KOTLIN_DIR/"
    git add "$NEW_KOTLIN_DIR"
    rm -rf "$TEMP_KOTLIN_DIR"
    trap - EXIT ERR
else
    git mv "$OLD_KOTLIN_DIR" "$NEW_KOTLIN_DIR"
fi

# ─── 5. Rewrite MainActivity.kt package line ─────────────────────────────
MAIN_ACTIVITY="$NEW_KOTLIN_DIR/MainActivity.kt"
[[ -f "$MAIN_ACTIVITY" ]] || die "expected $MAIN_ACTIVITY after move"
$SED -i.bak "1s|^package $OLD_ANDROID_PKG$|package $NEW_ANDROID_PKG|" "$MAIN_ACTIVITY"

# ─── 6. Clean up .bak files ──────────────────────────────────────────────
# Delete the known single-file backups directly (passing a plain file path
# as the root of `find` does not match -name '*.bak' against that file).
rm -f pubspec.yaml.bak android/app/build.gradle.bak
# Delete backups produced for Dart sources and the moved Kotlin file.
find lib test integration_test "$NEW_KOTLIN_DIR" \
    -name '*.bak' -type f -delete 2>/dev/null || true

# ─── 7. Registration sheet for the release build host ────────────────────
#
# Renaming the app is only half of forking the template. The other half lives
# outside this repository: the release build host has to be told that this app
# exists, which signing key is its own, and — the part that is easy to skip —
# which certificate fingerprint it is allowed to produce. That declaration is
# what makes the verify stage able to reject an artifact signed by the wrong
# key; without it the build simply has nothing to compare against.
#
# None of that can be done from here, so write down exactly what has to be
# handed over, with this app's values already filled in. The one field that
# cannot be filled in yet is the fingerprint: it does not exist until the key
# does.
APP_SLUG="$NEW_DART_NAME"
APP_ENV_PREFIX="$(echo "$APP_SLUG" | tr '[:lower:]' '[:upper:]' | tr -c 'A-Z0-9' '_' | $SED 's/_*$//')"
REGISTRATION_DOC="docs/komodo-registration.md"

cat >"$REGISTRATION_DOC" <<REGISTRATION
# リリースビルドの登録メモ（$APP_SLUG）

\`scripts/rename_app.sh\` が生成しました。**登録が済んだらこのファイルは
消して構いません**（残す場合は指紋を埋めてから）。

配布する APK / AAB を焼くのはこのリポジトリの CI ではなく、ビルドホスト側の
リリース経路です（仕組みは \`docs/RELEASE.md\`）。そこに**このアプリを登録する
までは、main に入れても何も焼かれません。**

## 1. 署名鍵を作る

ビルドホストで、このアプリ専用のアップロード鍵を 1 つ発行します。鍵の実体は
リポジトリには入りません。既存アプリの手順に合わせてください。

- 鍵の別名（alias）: \`$APP_SLUG-upload\`
- 稼働用の置き場: ビルドホストの署名鍵ディレクトリ配下 \`$APP_SLUG/\`
- 保管の正: NAS 側の署名鍵ディレクトリ（**バックアップはここ 1 箇所**）

⚠ Play App Signing を使うならこれは「アップロード鍵」で、紛失しても Play
Console からリセットを申請できます。**Play に出さないアプリではこの鍵が
そのまま配布鍵になり、紛失すると更新を配れなくなります。**

## 2. パスワードを Secret として登録する

| 変数名 | 中身 |
|---|---|
| \`SIGN_${APP_ENV_PREFIX}_STORE_PASS\` | キーストアのパスワード |
| \`SIGN_${APP_ENV_PREFIX}_KEY_PASS\` | 鍵のパスワード |

## 3. 証明書指紋を測る

作った鍵から SHA-256 指紋を取り出し、下のブロックの \`CERT_SHA256\` に
書き写します。

\`\`\`
keytool -list -v -keystore upload-keystore.jks -alias $APP_SLUG-upload \\
  | sed -n 's/.*SHA256: *//p' | head -1
\`\`\`

⚠ **これは「このアプリはこの鍵で署名される」という宣言です。**ビルドのたびに
実測の指紋と突き合わされ、一致しなければ保管されません。**鍵を作り直したら
ここも更新してください。**

## 4. リポジトリ定義を足す

ビルドホストのリポジトリ定義（\`repos.toml\`）へ、次のブロックを追加します。
\`environment\` の値は 3 連引用符で囲む TOML の複数行文字列です。

\`\`\`toml
[[repo]]
name = "$APP_SLUG"
tags = ["managed"]
[repo.config]
server = "<ビルドホスト名>"
repo = "<owner>/$APP_SLUG"
git_provider = "github.com"
git_account = "<git アカウント>"
branch = "main"
environment = '''
APP             = $APP_SLUG
APPLICATION_ID  = $NEW_ANDROID_PKG
KEY_ALIAS       = $APP_SLUG-upload
CERT_SHA256     = <手順 3 で測った指紋>
STORE_PASS      = [[SIGN_${APP_ENV_PREFIX}_STORE_PASS]]
KEY_PASS        = [[SIGN_${APP_ENV_PREFIX}_KEY_PASS]]
PUB_ARGS        = --enforce-lockfile
'''

[repo.config.on_pull]
path = "."
shell_mode = true
command = "<リリーススクリプトのパス>"
\`\`\`

⚠ 既存アプリの定義は \`environment\` を 3 連ダブルクォートで書いています。
どちらでも構いませんが、**周りに合わせてください。**

⚠ **\`on_clone\` は書かないこと。** clone は on_clone と on_pull を両方走らせる
ため、両方に書くと 1 回のクローンでビルドが 2 周します。しかもリリース
スクリプトは読み終えた設定を即座に消す（アプリのコードから署名パスワードが
読めないようにするため）ので、2 周目は必ず失敗します。

⚠ \`PUB_ARGS = --enforce-lockfile\` は、\`pubspec.lock\` がビルダーの Flutter で
解決できるときだけ付けてください。落ちる場合は、その Flutter で
\`pubspec.lock\` を作り直してコミットするのが正しい直し方です
（\`docs/OPERATIONS.md\`）。

## 5. main への push で発火するようにする

このリポジトリの GitHub webhook を、ビルドホストの受け口へ向けます。
これが無いと、登録だけしても push でビルドが始まりません。

## 6. 確認

- \`./scripts/check_release_contract.sh\` が手元で通ること
- ビルドホストで 1 回ビルドが完走し、成果物と署名レポートが保管されること
- 署名レポートの証明書 DN が **Android Debug ではない**こと
REGISTRATION

echo "wrote $REGISTRATION_DOC"

# ─── 8. Sanity check ─────────────────────────────────────────────────────
LEAKED="$(grep -rl "package:${OLD_DART_NAME}" lib test integration_test 2>/dev/null || true)"
if [[ -n "$LEAKED" ]]; then
    echo "warning: residual package:${OLD_DART_NAME} imports remain in:" >&2
    echo "$LEAKED" >&2
fi

cat <<MSG

rename complete.

next steps (manual):
  1. edit lib/shared/config/app_config.dart
       - appName, appDescription, appTagline, homeSubtitle, homeCardTitle,
         designSystemLabel/Name/Url/License, fontFamily (if swapping fonts)
  2. edit pubspec.yaml
       - description:
       - version:
       - flutter_launcher_icons.adaptive_icon_background (if brand colour changed)
       - fonts.family (if swapping fonts — must match AppConfig.fontFamily)
  3. edit android/app/src/main/AndroidManifest.xml
       - android:label
       - the autoVerify intent filter's android:host, and the custom
         scheme's android:scheme — both must match
         AppConfig.appLinkHost / AppConfig.customLinkScheme in
         lib/shared/app_config.dart.  Then publish the new
         .well-known/assetlinks.json for the domain: see docs/DEEP_LINKS.md.
  4. replace assets/icon/app_icon.png and app_icon_foreground.png,
     then run:  dart run flutter_launcher_icons
     remember to update the brand colour in
     android/app/src/main/res/values/colors.xml (ic_launcher_background)
     to match pubspec.yaml > flutter_launcher_icons.adaptive_icon_background
  5. (once per fork) pin a shared debug keystore so every machine signs
     debug builds with the same key — required to avoid
     INSTALL_FAILED_UPDATE_INCOMPATIBLE when switching APKs between
     dev machines or CI:
       bash scripts/generate_debug_keystore.sh
       git add android/app/debug.keystore
  6. (optional) override APK/AAB base filename by adding
       app.archivesBaseName=<name>
     to android/gradle.properties.  Default is the last segment of
     applicationId, which rename_app.sh has just rewritten.
  7. update README.md line 1
  8. run: flutter clean && flutter pub get && dart analyze && flutter test
  9. register this app with the release build host — nothing is built for
     it until that is done.  The values it needs, with this app's already
     filled in, are in the generated docs/komodo-registration.md.
     Delete that file once the registration is in place.

MSG
