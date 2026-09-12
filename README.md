# Nix development workstation

Declarative development workstation for NixOS-WSL and Apple Silicon macOS. It uses nixpkgs unstable, Den, Home Manager, nix-darwin, and a NixOS-WSL host definition. The Home Manager configuration is split into reusable aspects shared by both hosts.

## Install

On a NixOS-WSL system:

```bash
nix shell nixpkgs#git nixpkgs#openssh

git clone <repository-url> nix-config
cd nix-config

sudo nixos-rebuild switch --flake .#wsl
./scripts/verify.sh
```

The `wsl` output installs the workstation tools, zsh, Neovim, language servers, Docker, Flutter and Android CLI tooling, Ghidra and reverse-engineering tools, and headless Playwright and Chromium tooling.

On Apple Silicon macOS, the `macbook` output installs the same cross-platform user environment through nix-darwin and Home Manager. Bootstrap nix-darwin from this checkout with:

```bash
sudo nix run --impure .#darwinConfigurations.macbook.config.system.build.darwin-rebuild -- switch --impure --flake .#macbook
./scripts/verify.sh
```

## Windows helpers

The scripts in `windows/` run from Windows PowerShell. `.wslconfig` is copied into the Windows user profile.

`bootstrap.ps1` installs WSL, Windows Terminal, Tailscale, Docker Desktop, Wireshark, Npcap, and Ghidra. It also installs the MesloLGS Nerd Font files used by the prompt.

```powershell
.\windows\bootstrap.ps1
```

`collect-windows-inventory.ps1` writes a machine-specific rebuild inventory containing WinGet packages, WSL status, and basic Windows and PowerShell information. The generated `windows-inventory/` directory is intentionally ignored and must not be committed. It does not back up a WSL distribution. To export the full distribution, run:

```powershell
.\windows\collect-windows-inventory.ps1 -OutputDirectory .\windows-inventory

wsl --shutdown
wsl --export <distribution-name> <backup-path>.vhdx --vhd
```

Copy `.wslconfig` to `%USERPROFILE%\.wslconfig`, then run `wsl --shutdown` to apply its WSL2 networking settings.

On NixOS-WSL, Docker is installed without automatic daemon startup, Docker-group membership, or user lingering. Start it explicitly with `sudo systemctl start docker` and use `sudo docker ...` when needed.

## Pi agent

Home Manager owns Pi's global settings and the safety extensions in `~/.pi/agent/extensions/`. Activation replaces `settings.json` with the repository policy, including the pinned `@charmland/pi-hyper-provider` package and the default `hyper/glm-5.3-flash` model. Package caches, model catalogs, sessions, trust decisions, and Hyper runtime metadata remain machine-local under `~/.pi/agent/` and are excluded from Git.

Start Pi interactively, run `/login`, and select Charm Hyper subscription authentication. Pi owns `~/.pi/agent/auth.json`, including OAuth token refreshes; Nix never reads, links, or replaces that file. The Hyper footer defaults remain unchanged: Hypercredit balance is visible and the team name is hidden. The first online interactive launch may install the pinned provider package and populate its dynamic model catalog.

API-key providers can optionally use `~/.pi/agent/secrets.env`. Copy the installed `secrets.env.example`, add shell-style assignments, and restrict it before launching Pi:

```bash
cp ~/.pi/agent/secrets.env.example ~/.pi/agent/secrets.env
chmod 600 ~/.pi/agent/secrets.env
```

The `pi` wrapper ignores symlinks, non-regular files, and files with any group/world permissions. Provider credentials are available to the Pi process but explicitly unset before agent-generated Bash commands run. Agent-generated shell commands are checked by Tirith and Destructive Command Guard through their Pi integrations; the repository only retains DCG's official thin bridge, not its own destructive-command rules. The separate protected-path extension guards credentials accessed through Pi's read, write, edit, and shell tools. These controls reduce accidental disclosure or damage; they are not an OS sandbox. Pi extensions execute with the Pi process's full user access, so review all third-party extension code before changing package pins.

Interactive `/settings`, `/model`, `pi install`, and `/hyper-status` changes can affect the current machine temporarily. Home Manager restores declarative settings on the next activation. OAuth credentials and mutable runtime data intentionally differ between machines.
