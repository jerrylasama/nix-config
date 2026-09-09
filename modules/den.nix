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
    ../hosts/darwin.nix

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

  den.aspects.workstation = {
    includes = [
      den.aspects.common-cli
      den.aspects.shell
      den.aspects.editor
      den.aspects.agents
      den.aspects.toolchains
      den.aspects.language-tools
      den.aspects.browser-tools
      den.aspects.grafana
      den.aspects.reverse-engineering
      den.aspects.network-tools
      den.aspects.containers
      den.aspects.mobile
    ];
  };

  den.default = {
    nixos.system.stateVersion = "26.05";
    darwin.system.stateVersion = 7;
    homeManager.home.stateVersion = "26.05";

    includes = [
      den.batteries.define-user
    ];
  };
}
