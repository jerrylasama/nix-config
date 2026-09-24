# SOPS, age, and YubiKey

The CLI tools include `sops`, `age`, and `age-plugin-yubikey`, and `aspects/secrets.nix` imports the sops-nix home-manager module on both hosts. It decrypts sops files during activation and writes each entry as a plain file owned by the user. The module stays inactive until at least one `sops.secrets` entry is declared, so adding the tooling changes nothing by itself.

## Age key

The module decrypts with the age identity at `~/.config/sops/age/keys.txt`, set in `aspects/secrets.nix`. Create it once per machine:

```bash
mkdir -p ~/.config/sops/age
age-keygen -o ~/.config/sops/age/keys.txt
chmod 600 ~/.config/sops/age/keys.txt
```

`age-keygen -y ~/.config/sops/age/keys.txt` prints the matching public key for `.sops.yaml`.

The key file is machine-local. Home Manager never reads or replaces it, and it must stay out of Git and the Nix store. Keep a copy in a password manager or on offline media, because a secret encrypted only to this key cannot be recovered without it.

## Declaring secrets

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

## YubiKey

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
