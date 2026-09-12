#!/usr/bin/env bash
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

file_mode() {
  stat -f '%Lp' "$1" 2>/dev/null || stat -c '%a' "$1"
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

printf 'Checking Nix workstation commands\n'

check_tool git --version
check_tool gh --version
check_tool tea --version
check_tool deploy --version
check_tool gpg2 --version
check_tool rtk --version
check_tool rtk gain

check_tool curl --version
check_tool wget --version
check_tool jq --version
check_tool yq --version
check_tool rg --version
check_tool fd --version
check_tool fzf --version
check_tool tree --version
check_tool unzip -v
check_tool zip -v
check_tool just --version

check_tool zsh --version
check_tool nvim --version

check_tool codex --version
check_tool dcg --version
check_tool tirith --version

printf '\nChecking Pi configuration and safety policy\n'
pi_test_home="$VERIFY_RUNTIME_DIR/pi-home"
mkdir -p "$pi_test_home/.pi/agent"
if HOME="$pi_test_home" run_probe pi --version; then
  pass "wrapped pi --version succeeds without secrets.env"
else
  fail "wrapped pi --version without secrets.env"
fi

pi_settings="$HOME/.pi/agent/settings.json"
if [ -f "$pi_settings" ] && [ ! -L "$pi_settings" ] && [ "$(file_mode "$pi_settings")" = 600 ] && jq -e '
  .defaultProvider == "hyper" and
  .defaultModel == "glm-5.3-flash" and
  .defaultThinkingLevel == "high" and
  .enabledModels == ["hyper/*"] and
  .defaultTools == ["read", "grep", "find", "ls", "bash", "edit", "write"] and
  .packages == ["npm:@charmland/pi-hyper-provider@0.3.2"] and
  .extensions == ["extensions/tirith-guard.ts", "extensions/dcg-guard.ts", "extensions/protected-path-guard.ts"] and
  .enableInstallTelemetry == false and
  .enableAnalytics == false and
  .defaultProjectTrust == "ask" and
  (.shellCommandPrefix | contains("HYPER_API_KEY")) and
  (.shellCommandPrefix | contains("ANTHROPIC_API_KEY")) and
  (.shellCommandPrefix | contains("OPENAI_API_KEY")) and
  (.shellCommandPrefix | contains("AWS_SECRET_ACCESS_KEY")) and
  (.shellCommandPrefix | contains("GOOGLE_APPLICATION_CREDENTIALS"))
' "$pi_settings" >/dev/null; then
  pass "Pi settings are owner-only and contain the declarative model, tools, package, and privacy policy"
else
  fail "Pi settings are missing or do not match the declarative policy"
fi

for pi_local_state in "$HOME/.pi/agent/auth.json" "$HOME/.pi/agent/secrets.env"; do
  if [ -L "$pi_local_state" ]; then
    case "$(readlink "$pi_local_state")" in
      /nix/store/*) fail "$pi_local_state must not link into /nix/store" ;;
      *) pass "$pi_local_state is not Nix-owned" ;;
    esac
  elif [ -e "$pi_local_state" ]; then
    pass "$pi_local_state is local mutable state"
  else
    pass "$pi_local_state is absent and not Nix-owned"
  fi
done

printf '%s\n' 'printf "PI_VERIFY_SECRET_SHOULD_NOT_RUN\n" >&2' > "$pi_test_home/.pi/agent/secrets.env"
chmod 0644 "$pi_test_home/.pi/agent/secrets.env"
if HOME="$pi_test_home" pi --version > "$VERIFY_RUNTIME_DIR/pi-insecure-secret.log" 2>&1 &&
  grep -q 'ignoring .*secrets.env' "$VERIFY_RUNTIME_DIR/pi-insecure-secret.log" &&
  ! grep -q 'PI_VERIFY_SECRET_SHOULD_NOT_RUN' "$VERIFY_RUNTIME_DIR/pi-insecure-secret.log"; then
  pass "Pi rejects insecure secrets.env without evaluating or exposing it"
else
  fail "Pi did not safely reject insecure secrets.env"
fi

if node "$ROOT_DIR/scripts/test-pi-extensions.mjs" >/dev/null; then
  pass "Pi extension safety tests"
else
  fail "Pi extension safety tests"
fi

if dcg --robot test "printf safe" >/dev/null 2>&1 &&
  ! dcg --robot test "git reset --hard" >/dev/null 2>&1; then
  pass "Destructive Command Guard allows safe commands and blocks destructive commands"
else
  fail "Destructive Command Guard decision smoke test"
fi

if ! tirith check --offline -- "echo payload | base64 -d | bash" >/dev/null 2>&1; then
  pass "Tirith blocks an obfuscated execute chain"
else
  fail "Tirith decision smoke test"
fi

check_tool gcc --version
check_tool clang --version
check_tool clangd --version
check_tool clang-format --version
check_tool clang-tidy --version
check_tool lld
check_tool ld.lld --version
check_tool lldb --version
check_tool cmake --version
check_tool ninja --version
check_tool make --version

check_tool go version
check_tool gopls version

check_tool rustc --version
check_tool cargo --version
check_tool rustfmt --version
check_tool rust-analyzer --version

check_tool node --version
check_tool corepack --version
check_tool tsc --version
check_tool vtsls --version

check_tool java -version
check_tool javac --version
check_tool jdtls --help

check_tool kotlinc -version
check_tool kotlin -version
check_tool gradle --version

check_tool perl --version
check_tool perlnavigator

check_tool uv --version
check_tool ruff --version
check_tool basedpyright --version

check_tool dotnet --version

check_tool nixd --version
check_tool nixfmt --version

check_tool playwright-cli --help
check_tool gcx --help

check_tool r2 -v
check_tool binwalk --help

check_tool adb version
check_tool apktool --version
check_tool jadx --version
check_tool ilspycmd --help

printf '\nChecking Ghidra headless analysis\n'
ghidra_runtime_dir="$VERIFY_RUNTIME_DIR/ghidra-user"
ghidra_project_dir="$VERIFY_RUNTIME_DIR/ghidra-project"
mkdir -p "$ghidra_runtime_dir" "$ghidra_project_dir"
ghidra_target=$(command -v bash)
if ghidra_target_resolved=$(realpath "$ghidra_target" 2>/dev/null); then
  ghidra_target=$ghidra_target_resolved
elif ghidra_target_resolved=$(readlink -f "$ghidra_target" 2>/dev/null); then
  ghidra_target=$ghidra_target_resolved
fi

if command -v ghidra-analyzeHeadless >/dev/null 2>&1; then
  if GHIDRA_MAXMEM=512M \
    GHIDRA_JAVA_OPTIONS="-Duser.home=$ghidra_runtime_dir" \
    ghidra-analyzeHeadless "$ghidra_project_dir" verify -import "$ghidra_target" \
      -noanalysis -deleteProject >"$VERIFY_RUNTIME_DIR/ghidra-headless.log" 2>&1; then
    pass "ghidra-analyzeHeadless import"
  else
    fail "ghidra-analyzeHeadless import"
  fi
else
  fail "ghidra-analyzeHeadless is not on PATH"
fi

check_tool tcpdump --version
check_tool tshark --version
check_tool nmap --version
check_tool mitmproxy --version
check_tool scapy -h
check_tool socat -V

check_tool flutter --version

check_tool docker --version
check_tool docker compose version

if [ "$(uname -s)" = "Linux" ]; then
  check_tool strace --version
  check_tool ltrace --version
fi

printf '\nChecking language-server names used by LazyVim\n'
for language_server in nixd clangd gopls rust-analyzer vtsls jdtls \
  kotlin-language-server basedpyright perlnavigator csharp-ls; do
  check_tool "$language_server"
done

if command -v nvim >/dev/null 2>&1; then
  if nvim --headless -u "$ROOT_DIR/dotfiles/nvim/init.lua" \
    '+lua assert(vim.fn.executable("nixd") == 1)' '+qa' \
    >/dev/null 2>&1; then
    pass "Neovim headless configuration startup"
  else
    fail "Neovim headless configuration startup"
  fi
fi

if command -v flutter >/dev/null 2>&1; then
  if flutter doctor >"$VERIFY_RUNTIME_DIR/flutter-doctor.log" 2>&1; then
    pass "flutter doctor"
  else
    note "flutter doctor reported expected missing platform components; see $VERIFY_RUNTIME_DIR/flutter-doctor.log"
  fi
fi

if command -v systemctl >/dev/null 2>&1 && systemctl is-system-running >/dev/null 2>&1; then
  if systemctl is-active --quiet docker; then
    pass "systemctl docker service is active"
  else
    note "Docker daemon is not active; start it explicitly with sudo systemctl start docker"
  fi
else
  note "systemd is not running in this session; Docker daemon service check skipped"
fi

printf '\nRunning Playwright smoke test\n'
browser_started=0
if playwright-cli open https://example.com >"$VERIFY_RUNTIME_DIR/playwright-open.log" 2>&1; then
  browser_started=1
  pass "playwright-cli open https://example.com"
else
  fail "playwright-cli open https://example.com"
fi

if [ "$browser_started" -eq 1 ]; then
  if playwright-cli snapshot >"$VERIFY_RUNTIME_DIR/playwright-snapshot.log" 2>&1; then
    pass "playwright-cli snapshot"
  else
    fail "playwright-cli snapshot"
  fi

  if playwright-cli close >"$VERIFY_RUNTIME_DIR/playwright-close.log" 2>&1; then
    pass "playwright-cli close"
  else
    fail "playwright-cli close"
  fi
fi

if [ "$failures" -ne 0 ]; then
  printf '\n%d required checks failed.\n' "$failures" >&2
  exit 1
fi

printf '\nAll required current-platform checks passed.\n'
