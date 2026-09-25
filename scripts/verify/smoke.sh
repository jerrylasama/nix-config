# Sourced by scripts/verify.sh: Playwright browser smoke test. The open,
# snapshot, and close steps share one browser lifecycle and must stay together.
# shellcheck shell=bash
# VERIFY_RUNTIME_DIR is defined by the driver.
# shellcheck disable=SC2154

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
