#!/usr/bin/env bash
set -euo pipefail

# Rebuild and activate a host from this flake. Usage: rebuild.sh <host> [action]
# wsl uses nixos-rebuild (switch|boot|test|dry-activate);
# macbook uses the flake's darwin-rebuild (switch|build|activate|rollback).
host="${1:?usage: rebuild.sh <host> [switch|boot]}"
action="${2:-switch}"

case "$host" in
wsl)
	sudo nixos-rebuild "$action" --flake .#wsl
	;;
macbook)
	sudo nix run --impure .#darwinConfigurations.macbook.config.system.build.darwin-rebuild -- "$action" --impure --flake .#macbook
	;;
*)
	echo "unknown host: $host (expected: wsl or macbook)" >&2
	exit 1
	;;
esac
