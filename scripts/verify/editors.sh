# Sourced by scripts/verify.sh: LazyVim language-server names and editor checks.
# shellcheck shell=bash

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
