{
  inputs,
  den,
  lib,
  ...
}:
{
  imports = [
    inputs.den.flakeModule

    ../hosts/wsl.nix

    ../aspects/common-cli.nix
    ../aspects/shell.nix
    ../aspects/editor.nix
    ../aspects/agents.nix
    ../aspects/toolchains.nix
    ../aspects/language-tools.nix
    ../aspects/browser-tools.nix
    ../aspects/grafana.nix
    ../aspects/reverse-engineering.nix
    ../aspects/network-tools.nix
    ../aspects/containers.nix
    ../aspects/mobile.nix
  ];

  den.schema.user.classes = lib.mkDefault [ "homeManager" ];

  den.default = {
    nixos.system.stateVersion = "26.05";
    homeManager.home.stateVersion = "26.05";

    includes = [
      den.batteries.define-user
    ];
  };
}
