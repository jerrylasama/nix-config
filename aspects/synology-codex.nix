{ den, ... }:
{
  den.aspects.synology-codex = {
    # Pin the Synology host key system-wide (TOFU captured via ssh-keyscan,
    # SHA256:DWYOJBUwdv6E9Cf0fwBLxv0CbAEKX3L632xe1yBuEgs). ssh checks the
    # global known_hosts file in addition to ~/.ssh/known_hosts.
    nixos.programs.ssh.knownHosts.synology = {
      hostNames = [ "synology" ];
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEsx7XGJjOm4KqIQM3AA/rji63qJWFGvsDUE+gFUTeiy";
    };

    homeManager =
      { config, ... }:
      {
        # Synology SSH credentials for the codex user, encrypted with sops/age
        # (see secrets/synology-codex.yaml and docs/SOPS_AGE_YUBIKEY.md).
        # sopsFile is set per secret instead of sops.defaultSopsFile so this
        # aspect never conflicts with grafana's default.
        sops.secrets.synology-codex-key.sopsFile = ../secrets/synology-codex.yaml;
        sops.secrets.synology-codex-pub.sopsFile = ../secrets/synology-codex.yaml;

        # The rendered files appear only after the sops-nix agent runs, so link
        # them out-of-store like the gcx template does (aspects/grafana.nix).
        home.file.".ssh/id_ed25519_synology_codex".source =
          config.lib.file.mkOutOfStoreSymlink config.sops.secrets.synology-codex-key.path;
        home.file.".ssh/id_ed25519_synology_codex.pub".source =
          config.lib.file.mkOutOfStoreSymlink config.sops.secrets.synology-codex-pub.path;

        # Upstream directive names; programs.ssh.settings replaced matchBlocks.
        programs.ssh.enable = true;
        programs.ssh.settings.synology-codex = {
          HostName = "synology";
          User = "codex";
          IdentityFile = "~/.ssh/id_ed25519_synology_codex";
          IdentitiesOnly = true;
        };
      };
  };
}
