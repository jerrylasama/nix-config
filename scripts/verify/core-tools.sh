# Sourced by scripts/verify.sh: workstation tool checks.
# shellcheck shell=bash

printf 'Checking Nix workstation commands\n'

check_tool git --version
check_tool gh --version
check_tool tea --version
check_tool deploy --version
check_tool ansible --version
check_tool gpg2 --version
check_tool sops --version
check_tool age --version
check_tool age-plugin-yubikey --version
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
