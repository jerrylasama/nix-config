# AGENTS.md

- NixOS-WSL + nix-darwin flake on the [den](https://github.com/denful/den) framework.
- Modules: `aspects/` (Home Manager), `hosts/`, `modules/den.nix` (den wiring), `packages/`.

## Commands

```bash
just verify                  # Full host verification: tools, pi config, guards, browser probes
just extensions              # Pi extension safety tests only (tirith, dcg, protected-path guards)
just rebuild <host> [action] # Rebuild and activate a host; hosts and actions: docs/JUSTFILE.md
just upgrade                 # Update flake.lock to the latest pinned inputs and commit the change
```

## Conventions

- Commit messages: `type(scope): one liner`; types feat, fix, chore, docs, build, ci, refactor, test; one concern per commit.
- Never push or force-push unless the user asks for that exact action in the current conversation.
- Run `nix fmt` on changed `.nix` files; run `just verify` before finalizing (read-only, safe anytime).

## Lessons

- `just -n` only prints commands; it never proves a command works or matches reality.
- When docs describe a script, read the script itself and compare strings before trusting either one.
- `scripts/rebuild.sh` bodies are tab-indented; anchor stub `sed` patterns carefully and grep afterwards to confirm they landed.
- Keep the Justfile a thin facade: real logic lives in `scripts/` (`rebuild.sh`, `verify.sh`); recipes stay one-liners.
- The macOS rebuild passes `--impure` twice (outer `nix run` + inner `darwin-rebuild`); `hosts/darwin.nix` resolves the account from `SUDO_USER`/`USER` and asserts impure evaluation.
- Rebuilds run locally on the target host; no cross-host deploy, so `just rebuild macbook` only works on the Mac.
- `nix flake check` can pass while a documented command path is broken; check README, Justfile comments, and docs against the scripts.
