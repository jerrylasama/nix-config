# Facade over scripts/. The scripts are the real interface and work without
# `just`; these recipes only save typing.

set shell := ["bash", "-euo", "pipefail", "-c"]

# Full host verification: tools, pi config, guards, browser probes.
verify:
	./scripts/verify.sh

# Pi extension safety tests only (tirith, dcg, protected-path guards).
extensions:
	node scripts/test-pi-extensions.mjs

# Rebuild and switch the NixOS-WSL host (run on the wsl machine).
rebuild-wsl:
	sudo nixos-rebuild switch --flake .#wsl

# Rebuild and switch the darwin host (run on the macbook; --impure is
# required so usernames resolve from SUDO_USER/USER at eval time).
rebuild-darwin:
	sudo nix run --impure .#darwinConfigurations.macbook.config.system.build.darwin-rebuild -- switch --impure --flake .#macbook
