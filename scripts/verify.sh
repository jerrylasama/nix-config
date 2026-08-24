#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$ROOT_DIR"

failures=0

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
check_tool pi --version

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
  if flutter doctor >/tmp/nix-config-flutter-doctor.log 2>&1; then
    pass "flutter doctor"
  else
    note "flutter doctor reported expected missing platform components; see /tmp/nix-config-flutter-doctor.log"
  fi
fi

if command -v systemctl >/dev/null 2>&1 && systemctl is-system-running >/dev/null 2>&1; then
  if systemctl is-active --quiet docker; then
    pass "systemctl docker service is active"
  else
    fail "systemctl docker service is active"
  fi
else
  note "systemd is not running in this session; Docker daemon service check skipped"
fi

printf '\nRunning Playwright smoke test\n'
browser_started=0
if playwright-cli open https://example.com >/tmp/nix-config-playwright-open.log 2>&1; then
  browser_started=1
  pass "playwright-cli open https://example.com"
else
  fail "playwright-cli open https://example.com"
fi

if [ "$browser_started" -eq 1 ]; then
  if playwright-cli snapshot >/tmp/nix-config-playwright-snapshot.log 2>&1; then
    pass "playwright-cli snapshot"
  else
    fail "playwright-cli snapshot"
  fi

  if playwright-cli close >/tmp/nix-config-playwright-close.log 2>&1; then
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
