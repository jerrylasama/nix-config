# Facade over scripts/. The scripts are the real interface and work without
# `just`; these recipes only save typing.

set shell := ["bash", "-euo", "pipefail", "-c"]

# Full host verification: tools, pi config, guards, browser probes.
verify:
	./scripts/verify.sh

# Pi extension safety tests only (tirith, dcg, protected-path guards).
extensions:
	node scripts/test-pi-extensions.mjs
