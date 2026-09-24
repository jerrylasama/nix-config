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

The `wsl` output installs the workstation tools, zsh, Neovim, language servers, Docker, Flutter and Android CLI tooling, Ghidra and reverse-engineering tools, and headless Playwright and Chromium tooling. `just verify` runs the same host checks as `./scripts/verify.sh`, and `just extensions` runs only the pi extension safety tests.

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

## Secrets management

The CLI tools include `sops`, `age`, and `age-plugin-yubikey`, and `aspects/secrets.nix` imports the sops-nix home-manager module on both hosts. It decrypts sops files during activation and writes each entry as a plain file owned by the user. The module stays inactive until at least one `sops.secrets` entry is declared, so adding the tooling changes nothing by itself.

### Age key

The module decrypts with the age identity at `~/.config/sops/age/keys.txt`, set in `aspects/secrets.nix`. Create it once per machine:

```bash
mkdir -p ~/.config/sops/age
age-keygen -o ~/.config/sops/age/keys.txt
chmod 600 ~/.config/sops/age/keys.txt
```

`age-keygen -y ~/.config/sops/age/keys.txt` prints the matching public key for `.sops.yaml`.

The key file is machine-local. Home Manager never reads or replaces it, and it must stay out of Git and the Nix store. Keep a copy in a password manager or on offline media, because a secret encrypted only to this key cannot be recovered without it.

### Declaring secrets

List the public keys that may decrypt in a `.sops.yaml` at the repository root:

```yaml
keys:
  - &admin age1...
creation_rules:
  - path_regex: secrets/[^/]+\.(yaml|json|env|ini)$
    age:
      - *admin
```

Edit encrypted files with `sops secrets/example.yaml`. Encrypted files commit to Git like any other file. Declare them in Nix to deploy:

```nix
sops.defaultSopsFile = ../secrets/example.yaml;
sops.secrets.example-token = { };
```

On Linux the module decrypts through the `sops-nix` systemd user service into `$XDG_RUNTIME_DIR/secrets.d/`, with symlinks under `~/.config/sops-nix/secrets/`; `config.sops.secrets.<name>.path` is the path other units consume. On macOS the same work happens in a launchd agent at login. User services that need a secret must start after decryption:

```nix
systemd.user.services.my-service.Unit.After = [ "sops-nix.service" ];
```

The interactive `sops` command looks for the key at `$XDG_CONFIG_HOME/sops/age/keys.txt` and falls back to `~/Library/Application Support/sops/age/keys.txt` on macOS. Either place the key in the fallback location on the Mac or export `SOPS_AGE_KEY_FILE` to point at the existing file.

After adding a recipient to `.sops.yaml`, run `sops updatekeys secrets/example.yaml` to re-encrypt existing files.

### YubiKey

`age-plugin-yubikey` stores an age identity in a YubiKey's PIV slot. The private key is generated on the card and never leaves it; the exported identity file holds only a reference stanza. YubiKey 4 and 5 series work; the NEO and the blue Security Key lack PIV support.

```bash
age-plugin-yubikey --generate                            # creates a key on the card
age-plugin-yubikey --list                                # prints recipients, age1yubikey1...
age-plugin-yubikey --identity --slot 1 > yubikey-identity.txt
```

Set a PIN when prompted; the PIV default is `123456` and should be changed. To decrypt with sops, append the identity stanza to `~/.config/sops/age/keys.txt` or point `SOPS_AGE_KEY_FILE` at the identity file, add the `age1yubikey1...` recipient to `.sops.yaml`, and keep `age-plugin-yubikey` on PATH. sops runs the plugin during decryption, which prompts for the PIN and, when configured, a touch.

The card must be reachable. Linux hosts need the PC/SC daemon (`services.pcscd.enable = true`). On NixOS-WSL there is no direct USB access, so attach the reader to WSL with `usbipd-win` first. If activation-time decryption must use the YubiKey, pass the plugin to the module as well:

```nix
sops.age.plugins = [ pkgs.age-plugin-yubikey ];
```

Always add a software age key as a second recipient in the same creation rule. Files encrypted only to a lost or broken YubiKey cannot be opened again, and moving the secrets to a replacement card needs a surviving recipient.
