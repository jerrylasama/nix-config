# AGENTS.md

NixOS-WSL + nix-darwin flake built on the [den](https://github.com/denful/den) framework. Reusable Home Manager modules live in `aspects/`, host definitions in `hosts/`, den wiring in `modules/den.nix`, and custom packages in `packages/`.

## Common commands

`just --list` shows all recipes; details in [docs/JUSTFILE.md](docs/JUSTFILE.md).

```bash
just verify                 # Full host verification: tools, pi config, guards, browser probes
just extensions             # Pi extension safety tests only (tirith, dcg, protected-path guards)
just rebuild <host> [action] # Rebuild and activate wsl or macbook (default action: switch)
just upgrade                # Update flake.lock to the latest pinned inputs and commit the change
```

## Conventions

- Commit messages follow `type(scope): one liner` with types: feat, fix, chore, docs, build, ci, refactor, test. One concern per commit.
- Never push or force-push unless explicitly asked in the conversation.
- Run `nix fmt` on changed `.nix` files.
- Run `just verify` before finalizing changes. It is read-only and safe to run at any time.
