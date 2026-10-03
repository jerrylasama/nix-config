{ den, inputs, ... }:
{
  den.aspects.grafana = {
    homeManager =
      { config, pkgs, ... }:
      {
        home.packages = [ inputs.customPackages.${pkgs.stdenv.hostPlatform.system}.gcx ];

        # Default gcx profile: an on-prem Grafana stack with a service-account
        # token kept in sops. The template renders ~/.config/gcx/config.yaml
        # with the decrypted token at activation (see docs/SOPS_AGE_YUBIKEY.md).
        sops.defaultSopsFile = ../secrets/gcx.yaml;
        sops.secrets.gcx-token = { };
        sops.templates.gcx-config.content = ''
          version: 1
          stacks:
            default:
              grafana:
                server: https://observability.lab.jerrylasama.com
                token: ${config.sops.placeholder.gcx-token}
                org-id: 1
          contexts:
            default:
              stack: default
          current-context: default
        '';
        # mkOutOfStoreSymlink: the rendered file appears only after the
        # sops-nix launchd agent runs (post-activation), so the link must be
        # created without requiring the target to exist yet.
        home.file.".config/gcx/config.yaml".source =
          config.lib.file.mkOutOfStoreSymlink config.sops.templates.gcx-config.path;
      };
  };
}
