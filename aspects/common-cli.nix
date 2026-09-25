{ den, ... }:
{
  den.aspects.common-cli = {
    homeManager = { pkgs, ... }: {
      home.packages = [
        pkgs.ansible
        pkgs.git
        pkgs.gitleaks
        pkgs.gh
        pkgs.tea
        pkgs.deploy-rs
        pkgs.gnupg
        pkgs.rtk

        # Secrets management (sops-nix uses age by default)
        pkgs.sops
        pkgs.age
        pkgs.age-plugin-yubikey

        pkgs.curl
        pkgs.wget

        pkgs.jq
        pkgs.yq

        pkgs.ripgrep
        pkgs.fd
        pkgs.fzf

        pkgs.tree
        pkgs.unzip
        pkgs.zip
        pkgs.just
        pkgs.shellcheck
      ];

      programs.git = {
        enable = true;
        settings = {
          init.defaultBranch = "main";
        };
      };

      programs.direnv = {
        enable = true;
        nix-direnv.enable = true;
      };

      home.sessionVariables = {
        EDITOR = "nvim";
        VISUAL = "nvim";
        PAGER = "less -FRX";
      };
    };
  };
}
