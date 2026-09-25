# Sourced by scripts/verify.sh: reverse-engineering tools and Ghidra headless.
# shellcheck shell=bash
# VERIFY_RUNTIME_DIR is defined by the driver.
# shellcheck disable=SC2154

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
