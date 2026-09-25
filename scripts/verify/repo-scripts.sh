# Sourced by scripts/verify.sh: repository shell-script linting.
# shellcheck shell=bash

printf '\nChecking repository shell scripts\n'
check_tool shellcheck --version
if shellcheck scripts/*.sh scripts/verify/*.sh; then
  pass "shellcheck scripts/*.sh scripts/verify/*.sh"
else
  fail "shellcheck scripts/*.sh scripts/verify/*.sh"
fi
