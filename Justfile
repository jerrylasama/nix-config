# Facade over scripts/. The scripts are the real interface and work without
# `just`; these recipes only save typing.

set shell := ["bash", "-euo", "pipefail", "-c"]

# Full host verification: tools, pi config, guards, browser probes.
verify:
	./scripts/verify.sh

# Pi extension safety tests only (tirith, dcg, protected-path guards).
extensions:
	node scripts/test-pi-extensions.mjs

# Rebuild a NixOS host and activate it. Default action is `switch`;
# pass `boot` to stage it for the next boot instead (activate by
# restarting WSL: `wsl --shutdown`). Usage: just rebuild wsl [boot]
rebuild host action="switch":
	sudo nixos-rebuild {{ action }} --flake .#{{ host }}

# Rebuild and switch the darwin host (macbook). Different toolchain, so it
# stays its own recipe; --impure is required so usernames resolve from
# SUDO_USER/USER at eval time.
rebuild-darwin:
	sudo nix run --impure .#darwinConfigurations.macbook.config.system.build.darwin-rebuild -- switch --impure --flake .#macbook

# Update flake.lock to the latest pinned inputs and commit the change.
# Follow up with `just rebuild wsl` or `just rebuild-darwin` on the target host.
upgrade:
	nix flake update --commit-lock-file
