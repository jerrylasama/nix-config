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
