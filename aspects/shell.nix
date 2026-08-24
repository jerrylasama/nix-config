{ den, ... }:
{
  den.aspects.shell = {
    homeManager = { lib, pkgs, ... }: {
      home.packages = [
        pkgs.zsh
        pkgs.zsh-powerlevel10k
      ];

      programs.zsh = {
        enable = true;
        enableCompletion = true;
        autosuggestion.enable = true;
        syntaxHighlighting.enable = true;

        oh-my-zsh = {
          enable = true;
          plugins = [ "git" ];
        };

        initContent = lib.mkAfter ''
          if [[ -r "$HOME/.config/zsh/aliases.zsh" ]]; then
            source "$HOME/.config/zsh/aliases.zsh"
          fi
          if [[ -r "$HOME/.config/zsh/functions.zsh" ]]; then
            source "$HOME/.config/zsh/functions.zsh"
          fi
          if [[ -r "${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme" ]]; then
            source "${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme"
          fi
          if [[ -r "$HOME/.p10k.zsh" ]]; then
            source "$HOME/.p10k.zsh"
          fi
        '';
      };

      home.file = {
        ".config/zsh/aliases.zsh".source = ../dotfiles/zsh/aliases.zsh;
        ".config/zsh/functions.zsh".source = ../dotfiles/zsh/functions.zsh;
        ".p10k.zsh".source = ../dotfiles/p10k.zsh;
      };
    };
  };
}
