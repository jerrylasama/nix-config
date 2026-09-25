# AGENTS.md

This repository is a NixOS-WSL and nix-darwin flake built on the [den](https://github.com/denful/den) framework. Reusable Home Manager modules live in `aspects/`, host definitions in `hosts/`, den wiring in `modules/den.nix`, and custom packages in `packages/`.

## Common commands

Four `just` recipes cover the daily workflow. Run `just --list` to see them on any machine; details are in [docs/JUSTFILE.md](docs/JUSTFILE.md).

```bash
just verify                  # Full host verification: tools, pi config, guards, browser probes
just extensions              # Pi extension safety tests only (tirith, dcg, protected-path guards)
just rebuild <host> [action] # Rebuild and activate wsl or macbook (default action: switch)
just upgrade                 # Update flake.lock to the latest pinned inputs and commit the change
```

## Conventions

Commit messages follow `type(scope): one liner`, with types feat, fix, chore, docs, build, ci, refactor, and test. Keep one concern per commit, since the history doubles as the changelog. Never push or force-push unless the user asks for that exact action in the current conversation. Run `nix fmt` on changed `.nix` files, and run `just verify` before finalizing changes; it is read-only and safe to run at any time.

## Lessons from earlier sessions

A `just -n` dry-run only proves that just can print a command. It never validates that the command works or matches reality, which is how a wrong macOS host name survived several dry-run checks here. When documentation describes a script, read the script itself and compare the strings before trusting either one.

Stubbing a script for safe testing has its own trap. The bodies in `scripts/rebuild.sh` are tab-indented, so a replacement like `sed 's|^sudo |echo sudo |'` matched nothing and the real rebuild commands ran anyway. Anchor patterns carefully, or grep the stub afterwards to confirm the replacement actually landed before trusting it.

Keep the Justfile a thin facade. The real logic lives in `scripts/`, with rebuild dispatch in `rebuild.sh` and the host checks in `verify.sh`. New logic belongs in the scripts, and recipes stay one-liners.

The macOS rebuild passes `--impure` twice, once to the outer `nix run` and once to the inner `darwin-rebuild`, because `hosts/darwin.nix` resolves the account name from `SUDO_USER` or `USER` at evaluation time and asserts that impure evaluation is allowed. Rebuilds also run locally on the target host; no cross-host deploy is configured, so `just rebuild macbook` only makes sense on the Mac itself.

Finally, `nix flake check` can pass while a documented command path is broken. The user-facing strings in the README, the Justfile comments, and the docs must be checked against the scripts they describe.
