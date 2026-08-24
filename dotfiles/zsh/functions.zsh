mkcd() {
  mkdir -p -- "$1" && cd -- "$1"
}
groot() {
  local root
  root=$(git rev-parse --show-toplevel 2>/dev/null) || return
  cd -- "$root"
}
