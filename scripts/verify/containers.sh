# Sourced by scripts/verify.sh: flutter, Docker, and system-tracing checks
# (the flat region between the network and LazyVim sections).
# shellcheck shell=bash

check_tool flutter --version

check_tool docker --version
check_tool docker compose version

if [ "$(uname -s)" = "Linux" ]; then
  check_tool strace --version
  check_tool ltrace --version
fi
