{ den, lib, ... }:
let
  # Pure flake evaluation cannot read the caller's environment. The fallback
  # matches the default account in a fresh NixOS-WSL image. An impure build
  # can override it with SUDO_USER or USER when a different account is used.
  detectedUser =
    let
      sudoUser = builtins.getEnv "SUDO_USER";
      loginUser = builtins.getEnv "USER";
    in
    if sudoUser != "" then
      sudoUser
    else if loginUser != "" then
      loginUser
    else
      "nixos";
in
{
  den.hosts.x86_64-linux.wsl = {
    hostName = "wsl";
    wsl.enable = true;
    users.${detectedUser}.classes = [ "homeManager" ];
  };

  den.aspects.wsl = {
    includes = [
      den.aspects.containers
    ];

    nixos = { lib, pkgs, ... }: {
      wsl = {
        enable = true;
        defaultUser = detectedUser;
      };

      networking.hostName = "wsl";

      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
      };

      nixpkgs.config = {
        allowUnfreePredicate =
          pkg:
          lib.elem (lib.getName pkg) [
            "android-sdk-cmdline-tools"
            "cmdline-tools"
            "android-sdk-platform-tools"
            "platform-tools"
            "android-sdk-build-tools"
            "build-tools"
            "android-sdk-platforms"
            "platforms"
          ];
        android_sdk.accept_license = true;
      };

      users.manageLingering = true;
      users.users.${detectedUser} = {
        extraGroups = [ "docker" ];
        linger = true;
      };

      environment.systemPackages = [
        pkgs.docker
        pkgs.docker-compose
      ];

      virtualisation.docker = {
        enable = true;
        enableOnBoot = true;
      };

      system.stateVersion = "26.05";
    };
  };

  den.aspects.${detectedUser} = {
    includes = [
      den.batteries.primary-user
      (den.batteries.user-shell "zsh")

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
}
