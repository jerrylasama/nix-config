#!/usr/bin/env bash
# Thin driver: shared setup and helpers, then the sourced check modules in
# scripts/verify/ run in a fixed order, then the summary. Do not run modules
# directly; they share this shell's state and strictness.
set -Eeuo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$ROOT_DIR"

failures=0

# These tools keep native state in the user's home directory by default. The
# verifier must also work from CI and Nix sandboxes where that directory may be
# read-only.
umask 077
VERIFY_RUNTIME_DIR=$(mktemp -d "${TMPDIR:-/tmp}/nix-config-verify.XXXXXX")
export GRADLE_USER_HOME="$VERIFY_RUNTIME_DIR/gradle"
export FLUTTER_SUPPRESS_ANALYTICS=true
export RTK_DB_PATH="$VERIFY_RUNTIME_DIR/rtk-history.db"
export XDG_CACHE_HOME="$VERIFY_RUNTIME_DIR/cache"
mkdir -p "$GRADLE_USER_HOME" "$XDG_CACHE_HOME"

pass() {
  printf 'PASS  %s\n' "$1"
}

fail() {
  printf 'FAIL  %s\n' "$1" >&2
  failures=$((failures + 1))
}

note() {
  printf 'INFO  %s\n' "$1"
}

# GNU stat takes -c, BSD/macOS stat takes -f. Try GNU first: `stat -f` on GNU
# prints a filesystem dump to stdout before failing, which poisons the command
# substitution even with the `||` fallback.
file_mode() {
  stat -c '%a' "$1" 2>/dev/null || stat -f '%Lp' "$1" 2>/dev/null
}

run_probe() {
  local command_name=$1
  shift

  if command -v timeout >/dev/null 2>&1; then
    timeout 15s "$command_name" "$@" >/dev/null 2>&1
  else
    "$command_name" "$@" >/dev/null 2>&1
  fi
}

check_tool() {
  local command_name=$1
  shift

  if ! command -v "$command_name" >/dev/null 2>&1; then
    fail "$command_name is not on PATH"
    return
  fi

  if [ "$#" -eq 0 ]; then
    pass "$command_name is on PATH"
  elif run_probe "$command_name" "$@"; then
    pass "$command_name $*"
  else
    fail "$command_name $*"
  fi
}

# Each module relies on the helpers and state above; the list order is the
# execution order and must not change.
verify_modules=(
  core-tools
  repo-scripts
  pi
  toolchains
  analysis-tools
  network-tools
  containers
  editors
  smoke
)

for module_name in "${verify_modules[@]}"; do
  # shellcheck source=scripts/verify/core-tools.sh
  source "$ROOT_DIR/scripts/verify/$module_name.sh"
done

if [ "$failures" -ne 0 ]; then
  printf '\n%d required checks failed.\n' "$failures" >&2
  exit 1
fi

printf '\nAll required current-platform checks passed.\n'
