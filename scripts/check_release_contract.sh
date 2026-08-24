#!/usr/bin/env bash
#
# scripts/check_release_contract.sh — builds the release artifacts the way the
# release pipeline builds them, and checks that this repository still holds up
# its end of the contract that pipeline relies on.
#
# Release APK/AAB are produced by a build host that runs, in three stages:
#
#   stage 1  build   the app's own code runs; NO signing key is mounted
#                    → NOLUMIA_SIGNING=none, artifacts come out unsigned
#   stage 2  sign    the key is mounted; the app's code does NOT run
#                    → apksigner/jarsigner over the artifacts alone
#   stage 3  verify  the measured certificate fingerprint, applicationId and
#                    versionName are matched against what was declared
#
# Splitting it that way keeps the signing key out of reach of pub packages and
# Gradle plugins. The price is that stages 2 and 3 never see the repository —
# they find the artifacts by name, in fixed directories. Those names and
# directories are the contract, and every one of them is produced by
# android/app/build.gradle. Nothing else in the repository references them, so
# an edit there breaks the release build with no local symptom at all: the
# debug build still works, the tests still pass, and the failure only shows up
# on the build host, after merge.
#
# This check closes that gap. It runs stage 1 exactly as the pipeline does and
# then asserts what stages 2 and 3 are about to look for.
#
# Usage:
#   ./scripts/check_release_contract.sh              # build, then check
#   ./scripts/check_release_contract.sh --no-build   # check an existing build/
#   ./scripts/check_release_contract.sh --help
#
# Environment:
#   BUILD_NUMBER=<n>   Android versionCode (default: git commit count)
#
# Prerequisites: flutter on PATH and a working Android SDK. `unzip` and
# `aapt2`, when present, enable two further checks; they are skipped with a
# note when absent, so the script stays usable on a bare toolchain.
set -uo pipefail

log()  { printf '[contract] %s\n' "$*" >&2; }
die()  { printf '[contract][error] %s\n' "$*" >&2; exit 2; }

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

do_build=1
for arg in "$@"; do
  case "$arg" in
    --no-build) do_build=0 ;;
    -h | --help) sed -n '2,38p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) die "unknown argument: $arg (try --help)" ;;
  esac
done

if [ -t 1 ]; then
  BOLD=$'\033[1m'; RED=$'\033[31m'; GREEN=$'\033[32m'; DIM=$'\033[2m'; OFF=$'\033[0m'
else
  BOLD=''; RED=''; GREEN=''; DIM=''; OFF=''
fi

FAILED=0

# check <description> — reads the outcome from the caller's `if`, so each
# assertion below reads as one line of contract plus one line of consequence.
pass() { printf '%s  ✓%s %s\n' "$GREEN" "$OFF" "$1"; }
fail() {
  printf '%s  ✗%s %s\n' "$RED" "$OFF" "$1"
  shift
  for line in "$@"; do printf '      %s\n' "$line"; done
  FAILED=$((FAILED + 1))
}
skip() { printf '%s  – %s (skipped: %s)%s\n' "$DIM" "$1" "$2" "$OFF"; }

# ─── The names the pipeline will look for ──────────────────────────────────
# Derived the same way android/app/build.gradle derives them, so a rename in
# build.gradle that this script does not follow shows up as a missing file
# rather than as a check that quietly stopped testing anything.

version="$(sed -n 's/^version: *//p' pubspec.yaml | sed 's/+.*//' | tr -d '[:space:]')"
[ -n "$version" ] || die "could not read 'version:' from pubspec.yaml."

application_id="$(sed -n 's/^ *def appApplicationId *= *"\(.*\)".*/\1/p' android/app/build.gradle)"
[ -n "$application_id" ] || die "could not read appApplicationId from android/app/build.gradle."

archives_base="$(sed -n 's/^ *app\.archivesBaseName *= *//p' android/gradle.properties 2>/dev/null | tr -d '[:space:]')"
[ -n "$archives_base" ] || archives_base="${application_id##*.}"

build_number="${BUILD_NUMBER:-$(git rev-list --count HEAD 2>/dev/null || printf 1)}"

per_app="${archives_base}-${version}-release"
apk_agp="build/app/outputs/apk/release/${per_app}.apk"
apk_flutter="build/app/outputs/flutter-apk/${per_app}.apk"
aab="build/app/outputs/bundle/release/${per_app}.aab"
apk_unsigned_marker="build/app/outputs/apk/release/app-release-unsigned.apk"
apk_generic="build/app/outputs/flutter-apk/app-release.apk"

log "═══════════════════════════════════════════════"
log "  applicationId : $application_id"
log "  version       : $version+$build_number"
log "  artifact base : $per_app"
log "═══════════════════════════════════════════════"

# ─── stage 1, as the pipeline runs it ──────────────────────────────────────

if [ "$do_build" -eq 1 ]; then
  command -v flutter >/dev/null 2>&1 || die "flutter is not on PATH."

  # Two tracked files are rewritten by the build below:
  #
  #   lib/shared/build_info.dart
  #     written by scripts/generate_build_info.sh, a few lines down.
  #
  #   android/.../GeneratedPluginRegistrant.java
  #     rewritten by `flutter build --release`, which registers only the
  #     plugins a release build actually links. integration_test comes from a
  #     dev dependency, so the release build drops it and the debug build puts
  #     it back — which is why this never surfaced while the gate built debug.
  #
  # Both are generated but committed. Leaving either rewritten would report a
  # dirty tree here and break the next `git pull --ff-only` on a build host, so
  # put back whatever was there — committed content or a developer's
  # uncommitted edits — on the way out, including when the build fails.
  generated_committed=(
    lib/shared/build_info.dart
    android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java
  )
  backup_dir=''
  restore_generated_sources() {
    [ -n "$backup_dir" ] || return 0
    local n=0 f
    for f in "${generated_committed[@]}"; do
      n=$((n + 1))
      if [ -f "$backup_dir/$n" ]; then
        cp -p "$backup_dir/$n" "$f"
      fi
    done
    rm -rf "$backup_dir"
    backup_dir=''
  }
  backup_dir="$(mktemp -d)"
  trap restore_generated_sources EXIT
  n=0
  for f in "${generated_committed[@]}"; do
    n=$((n + 1))
    if [ -f "$f" ]; then
      cp -p "$f" "$backup_dir/$n"
    fi
  done

  # Everything below mirrors stage 1 of the pipeline, in the same order.
  #
  # The wipe is not housekeeping: per-app filenames carry the version, so
  # after a version bump the previous build's artifacts sit in the same
  # directories under a different name, and a glob picks them up. Both this
  # check and the pipeline would then be reading an artifact from a build that
  # never happened here.
  log "removing previous artifacts ..."
  rm -rf build/app/outputs

  log "resolving dependencies ..."
  flutter pub get --enforce-lockfile || die "pub get --enforce-lockfile failed."

  # The pipeline runs this when it is present, and passes the same build
  # number Gradle receives, so the About screen agrees with the versionCode.
  if [ -f scripts/generate_build_info.sh ]; then
    log "generating build info ..."
    BUILD_NUMBER="$build_number" bash scripts/generate_build_info.sh >/dev/null \
      || die "scripts/generate_build_info.sh failed — the pipeline runs it too."
  fi

  # NOLUMIA_SIGNING=none is what the pipeline sets. Without it Gradle falls
  # back to the debug keystore and the artifacts come out debug-signed, which
  # is the exact failure stage 3 exists to catch.
  log "building APK (release, unsigned) ..."
  NOLUMIA_SIGNING=none flutter build apk --release --build-number="$build_number" \
    || die "flutter build apk --release failed."

  log "building AAB (release, unsigned) ..."
  NOLUMIA_SIGNING=none flutter build appbundle --release --build-number="$build_number" \
    || die "flutter build appbundle --release failed."
fi

# ─── What stages 2 and 3 are about to look for ─────────────────────────────

printf '\n%sRelease contract%s\n' "$BOLD" "$OFF"

# The signing stage globs `*-release.apk` excluding `app-release.apk` across
# the whole outputs tree, and signs every hit. The verify stage then reads one
# APK out of flutter-apk/ specifically. A per-app copy has to exist in both
# places: AGP writes one directory, the Flutter CLI copies into the other
# after Gradle has already exited, so build.gradle seeds both itself.
if [ -f "$apk_agp" ]; then
  pass "per-app APK next to AGP's output — $apk_agp"
else
  fail "per-app APK next to AGP's output — $apk_agp" \
    "The signing stage globs *-release.apk (excluding app-release.apk) and would" \
    "sign nothing, failing with \"署名対象の APK が見つからない\"." \
    "Produced by the assemble<Variant> doLast block in android/app/build.gradle."
fi

if [ -f "$apk_flutter" ]; then
  pass "per-app APK next to the Flutter CLI's copy — $apk_flutter"
else
  fail "per-app APK next to the Flutter CLI's copy — $apk_flutter" \
    "The verify stage reads its APK from flutter-apk/ only, and would fail with" \
    "\"APK が見つからない\" even though the signing stage had just succeeded." \
    "Produced by the assemble<Variant> doLast block in android/app/build.gradle."
fi

if [ -f "$aab" ]; then
  pass "per-app AAB — $aab"
else
  fail "per-app AAB — $aab" \
    "Both the signing and the verify stage glob *-release.aab excluding" \
    "app-release.aab, and would fail with \"署名対象の AAB が見つからない\"." \
    "Produced by the bundle<Variant> doLast block in android/app/build.gradle."
fi

# The version in those filenames is Gradle's versionName, which reaches it
# through local.properties. The verify stage reads the versionName back out of
# the built APK and refuses to store an artifact whose version disagrees with
# pubspec.yaml. Naming the files exactly, rather than globbing, means the three
# assertions above have already checked that agreement.
if [ -f "$apk_flutter" ]; then
  pass "artifact filenames carry pubspec's version ($version)"
fi

# Signing off is the whole reason stage 1 can run the app's own build code
# safely. AGP renames its output to -unsigned when a build type has no
# signingConfig, so the marker below is a direct read of whether
# NOLUMIA_SIGNING=none still takes effect — no external tool required.
if [ -f "$apk_unsigned_marker" ]; then
  pass "NOLUMIA_SIGNING=none drops the signingConfig — $apk_unsigned_marker"
else
  fail "NOLUMIA_SIGNING=none drops the signingConfig — $apk_unsigned_marker" \
    "AGP renames its output to app-release-unsigned.apk only when the release" \
    "build type has no signingConfig. Its absence means Gradle signed this" \
    "build — with the debug keystore, since no release key exists here." \
    "The pipeline would then hand a debug-signed artifact to the signing stage" \
    "and stage 3 would reject it (\"debug 鍵で署名されている\")." \
    "Set by \`unsignedRelease\` in android/app/build.gradle."
fi

# The Flutter CLI looks for the default filename after Gradle exits and fails
# the whole build without it. In unsigned mode AGP no longer writes that name,
# so build.gradle puts a copy back.
if [ -f "$apk_generic" ]; then
  pass "default-named APK for the Flutter CLI — $apk_generic"
else
  fail "default-named APK for the Flutter CLI — $apk_generic" \
    "In unsigned mode AGP writes app-release-unsigned.apk, but the Flutter CLI" \
    "hard-codes app-release.apk and fails with \"Gradle build failed to produce" \
    "an .apk file\". build.gradle copies the default name back for it."
fi

# Belt and braces over the marker check: read the archives themselves for a
# JAR signature. This is the one that would catch a release signed by
# something other than AGP's own signingConfig.
if command -v unzip >/dev/null 2>&1; then
  signed_entries() {
    unzip -l "$1" 2>/dev/null | grep -cE 'META-INF/.*\.(RSA|DSA|EC)$'
  }
  for archive in "$apk_flutter" "$aab"; do
    [ -f "$archive" ] || continue
    if [ "$(signed_entries "$archive")" -eq 0 ]; then
      pass "unsigned as stage 1 must leave it — $(basename "$archive")"
    else
      fail "unsigned as stage 1 must leave it — $(basename "$archive")" \
        "The archive carries a META-INF signature block, so something signed it" \
        "during the build. Signing belongs in stage 2, where the app's own code" \
        "does not run."
    fi
  done
else
  skip "archives carry no signature block" "unzip is not installed"
fi

# The verify stage compares the APK's package name against the applicationId
# declared for this app on the build host, and refuses a mismatch. What this
# repository controls is the other side of that comparison.
aapt2_bin=''
if command -v aapt2 >/dev/null 2>&1; then
  aapt2_bin=aapt2
elif [ -n "${ANDROID_SDK_ROOT:-}" ]; then
  aapt2_bin="$(find "$ANDROID_SDK_ROOT/build-tools" -maxdepth 2 -name aapt2 -type f 2>/dev/null | sort -r | head -1)"
fi

if [ -n "$aapt2_bin" ] && [ -f "$apk_flutter" ]; then
  built_id="$("$aapt2_bin" dump packagename "$apk_flutter" 2>/dev/null | tr -d '[:space:]')"
  if [ "$built_id" = "$application_id" ]; then
    pass "APK's applicationId matches build.gradle ($application_id)"
  else
    fail "APK's applicationId matches build.gradle" \
      "declared in android/app/build.gradle : $application_id" \
      "measured in the built APK           : ${built_id:-<unreadable>}" \
      "The verify stage compares the measured value against the applicationId" \
      "declared for this app on the build host and rejects a mismatch."
  fi
else
  skip "APK's applicationId matches build.gradle" "aapt2 not found"
fi

# ─── Result ────────────────────────────────────────────────────────────────

printf '\n'
if [ "$FAILED" -eq 0 ]; then
  printf '%sThe release contract holds.%s\n' "$GREEN" "$OFF"
  exit 0
fi

printf '%s%d contract check(s) failed.%s\n' "$RED" "$FAILED" "$OFF"
printf 'Every one of them is produced by android/app/build.gradle — see the\n'
printf 'per-app copy block and `unsignedRelease` there, and docs/RELEASE.md.\n'
exit 1
