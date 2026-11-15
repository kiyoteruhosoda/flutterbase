#!/usr/bin/env bash
#
# Runs a command that drives Gradle while holding an exclusive lock on the
# Gradle user home, so that two CI jobs sharing the same cache volume take
# turns instead of fighting over Gradle's own cache locks (keep task #487;
# brought to the template for the main CI red of 2026-11-15, task #995).
#
# Usage:
#   bash scripts/with-gradle-lock.sh <command...>
#
# ⚠ CI jobs share the named-volume Gradle cache (`GRADLE_USER_HOME`) between
#   main and PRs. concurrency is per ref, so main and PR checks run side by
#   side. Gradle resolves cache contention by "asking the owner over UDP to
#   let go", but across containers the request never arrives and the later
#   one fails with "Timeout waiting to lock journal cache". So the steps that
#   use Gradle are serialised with flock on a file in the cache.
# ⚠ A Gradle daemon keeps holding the cache lock after it finishes, so run
#   without the daemon (`org.gradle.daemon=false`), and when done stop it just
#   in case before releasing the lock.
# ⚠ Locally (no `GRADLE_USER_HOME`, or no flock) run as is, without the
#   lock.
#
set -uo pipefail

if [ "$#" -eq 0 ]; then
  echo "with-gradle-lock: no command given" >&2
  exit 2
fi

cd "$(dirname "$0")/.."

# Wait ceiling. The other side's apk build finishes in minutes. Keep it below the job limit (60 min).
WAIT_SECONDS="${GRADLE_LOCK_WAIT_SECONDS:-1500}"

if [ -z "${GRADLE_USER_HOME:-}" ] || ! command -v flock >/dev/null 2>&1; then
  exec "$@"
fi

mkdir -p "$GRADLE_USER_HOME"
LOCK="$GRADLE_USER_HOME/.ci-build.lock"

exec 9>"$LOCK"
started=$(date -u +%s)
if ! flock -n 9; then
  echo "with-gradle-lock: another job is using $GRADLE_USER_HOME; waiting (up to ${WAIT_SECONDS}s)"
  if ! flock -w "$WAIT_SECONDS" 9; then
    echo "with-gradle-lock: gave up waiting for $LOCK after ${WAIT_SECONDS}s" >&2
    exit 1
  fi
  echo "with-gradle-lock: got the lock after $(( $(date -u +%s) - started ))s"
fi

export GRADLE_OPTS="${GRADLE_OPTS:-} -Dorg.gradle.daemon=false"

# Do not pass the lock fd to children (so a lingering process does not keep holding the lock).
status=0
"$@" 9>&- || status=$?

if [ -x android/gradlew ]; then
  (cd android && ./gradlew --stop >/dev/null 2>&1) || true
fi

exit "$status"
