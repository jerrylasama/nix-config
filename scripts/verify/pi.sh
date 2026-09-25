# Sourced by scripts/verify.sh: Pi configuration and safety-policy checks.
# shellcheck shell=bash
# VERIFY_RUNTIME_DIR is defined by the driver.
# shellcheck disable=SC2154

printf '\nChecking Pi configuration and safety policy\n'
pi_test_home="$VERIFY_RUNTIME_DIR/pi-home"
mkdir -p "$pi_test_home/.pi/agent"
if HOME="$pi_test_home" run_probe pi --version; then
  pass "wrapped pi --version succeeds without secrets.env"
else
  fail "wrapped pi --version without secrets.env"
fi

pi_settings="$HOME/.pi/agent/settings.json"
# Byte-compare against the single source of truth in the repo; the deployed
# file is written from it by aspects/agents.nix (chmod 600, no symlink).
if [ -f "$pi_settings" ] && [ ! -L "$pi_settings" ] && [ "$(file_mode "$pi_settings")" = 600 ] &&
  cmp -s "$pi_settings" "$ROOT_DIR/dotfiles/pi/settings.json"; then
  pass "Pi settings are owner-only and match dotfiles/pi/settings.json"
else
  fail "Pi settings are missing, not owner-only, or do not match dotfiles/pi/settings.json (run just rebuild)"
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

# The pi bash tool analyzes commands in the posix dialect, so verify the guard
# the way it is actually invoked.
if dcg --robot test --dialect posix "printf safe" >/dev/null 2>&1 &&
  ! dcg --robot test --dialect posix "git reset --hard" >/dev/null 2>&1; then
  pass "Destructive Command Guard allows safe commands and blocks destructive commands"
else
  fail "Destructive Command Guard decision smoke test"
fi

# All-dialect analysis reads an unquoted flake ref as a PowerShell comment and
# denies it, which is why the guard pins the dialect. Catch a regression here.
if dcg --robot test --dialect posix "nix build .#wsl" >/dev/null 2>&1; then
  pass "Destructive Command Guard allows unquoted Nix flake refs"
else
  fail "Destructive Command Guard blocked an unquoted Nix flake ref"
fi

if ! tirith check --offline -- "echo payload | base64 -d | bash" >/dev/null 2>&1; then
  pass "Tirith blocks an obfuscated execute chain"
else
  fail "Tirith decision smoke test"
fi
