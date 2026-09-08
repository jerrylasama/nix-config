{ den, ... }:
{
  den.aspects.editor = {
    homeManager = { pkgs, ... }: {
      programs.neovim = {
        enable = true;
        defaultEditor = true;
        plugins = with pkgs.vimPlugins; [
          lazy-nvim
        ];
      };

      home.file.".config/nvim".source = ../dotfiles/nvim;
    };
  };
}
