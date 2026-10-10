{ den, ... }:
{
  den.aspects.synology-codex = {
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

        programs.ssh.matchBlocks.synology-codex = {
          hostName = "synology";
          user = "codex";
          identityFile = "~/.ssh/id_ed25519_synology_codex";
          identitiesOnly = true;
        };
      };
  };
}
