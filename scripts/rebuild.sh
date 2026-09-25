#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$ROOT_DIR"

# Rebuild and activate a host from this flake. Usage: rebuild.sh <host> [action]
# wsl uses nixos-rebuild (switch|boot|test|dry-activate);
# macbook uses the flake's darwin-rebuild (switch|build|activate|rollback).
host="${1:?usage: rebuild.sh <host> [action] (default: switch; valid actions per host, see header)}"
action="${2:-switch}"

case "$host" in
wsl)
	case "$action" in
	switch|boot|test|dry-activate) ;;
	*)
		echo "invalid action for wsl: $action (valid: switch, boot, test, dry-activate)" >&2
		exit 1
		;;
	esac
	sudo nixos-rebuild "$action" --flake .#wsl
	;;
macbook|darwin)
	case "$action" in
	switch|build|activate|rollback) ;;
	*)
		echo "invalid action for macbook: $action (valid: switch, build, activate, rollback)" >&2
		exit 1
		;;
	esac
	sudo nix run --impure .#darwinConfigurations.macbook.config.system.build.darwin-rebuild -- "$action" --impure --flake .#macbook
	;;
*)
	echo "unknown host: $host (expected: wsl or macbook; darwin works as an alias)" >&2
	exit 1
	;;
esac
