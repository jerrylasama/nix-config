# Just commands

`just` is a thin facade over the scripts in `scripts/`; the scripts remain the real interface and work without `just`. Run `just --list` to see the available recipes at any time. They are documented here for convenience.

## Rebuilding a host

`just rebuild <host>` rebuilds and activates a host from this flake. The supported hosts are `wsl` (NixOS-WSL, rebuilt with `nixos-rebuild`) and `macbook` (Apple Silicon macOS, rebuilt with the flake's `darwin-rebuild`). For the Mac, `darwin` is accepted as an alias for the host's flake name `macbook`, so `just rebuild darwin` and `just rebuild macbook` do the same thing.

The optional action parameter defaults to `switch`. Valid actions differ per host:

| Host      | Actions                              |
| --------- | ------------------------------------ |
| `wsl`     | `switch`, `boot`, `test`, `dry-activate` |
| `macbook` | `switch`, `build`, `activate`, `rollback` |

`boot` stages a new system configuration for the next reboot and is NixOS-only. Examples:

```bash
just rebuild wsl
just rebuild macbook
just rebuild wsl boot
```

Rebuilds run locally on the target machine; they are not cross-host deploys. Run `just rebuild wsl` on the WSL host and `just rebuild macbook` on the Mac.

## Upgrading

`just upgrade` updates `flake.lock` to the latest pinned inputs and commits the change; without `just`, run `nix flake update --commit-lock-file`:

```bash
just upgrade
just rebuild wsl
```

The lockfile commit is not enough on its own; follow up with `just rebuild <host>` on the target host to activate the updated inputs.

## Scanning for secrets

`just scan` runs `gitleaks detect`, which scans the working tree and the full git history for leaked secrets. A non-zero exit means findings were reported; gitleaks prints its own summary of what it found, so there is nothing extra to read. It is the plain command with no flags:

```bash
just scan
```

## Verification

`just verify` runs `./scripts/verify.sh`, the full host verification: tools, pi config, guards, and browser probes. `just extensions` runs `node scripts/test-pi-extensions.mjs`, the pi extension safety tests only (tirith, dcg, protected-path guards).

By default the tirith test loads the deployed extension at `~/.pi/agent/extensions/tirith-guard.ts`, so a prior home-manager activation must have run; set `TIRITH_EXTENSION_PATH` to test the repository source directly instead. The guard itself honors `TIRITH_BIN` to point at a specific tirith binary.
