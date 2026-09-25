# Sourced by scripts/verify.sh: compiler and language toolchain checks.
# shellcheck shell=bash

check_tool gcc --version
check_tool clang --version
check_tool clangd --version
check_tool clang-format --version
check_tool clang-tidy --version
# lld is a multi-call driver whose only output is an error message directing
# the caller to ld.lld (or ld64.lld, lld-link, wasm-ld), so no argument probe
# exits 0. The real flavor is probed with --version below.
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
# perlnavigator ignores --help and --version: it always tries to start its
# LSP connection and fails fast with a nonzero status, so there is no probe
# that exits 0 without a connected client.
check_tool perlnavigator

check_tool uv --version
check_tool ruff --version
check_tool basedpyright --version

check_tool dotnet --version

check_tool nixd --version
check_tool nixfmt --version

check_tool playwright-cli --help
check_tool gcx --help
