# Facade over scripts/. The scripts are the real interface and work without
# `just`; these recipes only save typing.

set shell := ["bash", "-euo", "pipefail", "-c"]

# Full host verification: tools, pi config, guards, browser probes.
verify:
	./scripts/verify.sh

# Pi extension safety tests only (tirith, dcg, protected-path guards).
extensions:
	node scripts/test-pi-extensions.mjs

# Rebuild and activate a host: `just rebuild <host> [action]`; see docs/JUSTFILE.md.
rebuild host action="switch":
	./scripts/rebuild.sh {{ quote(host) }} {{ quote(action) }}

# Update flake.lock to the latest pinned inputs and commit the change.
# Follow up with `just rebuild wsl` or `just rebuild darwin` on the target host.
upgrade:
	nix flake update --commit-lock-file
