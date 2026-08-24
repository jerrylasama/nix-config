{ den, ... }:
{
  den.aspects.common-cli = {
    homeManager = { pkgs, ... }: {
      home.packages = with pkgs; [
        git
        gh
        tea
        deploy-rs

        curl
        wget

        jq
        yq

        ripgrep
        fd
        fzf

        tree
        unzip
        zip
        just
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
