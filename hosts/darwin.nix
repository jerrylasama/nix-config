{ den, ... }:
let
  # The account is intentionally resolved during impure evaluation instead
  # of embedding a personal username in the shared repository. Both the
  # outer `nix run` and the inner `darwin-rebuild` invocation must therefore
  # receive `--impure`.
  detectedUser =
    let
      sudoUser = builtins.getEnv "SUDO_USER";
      loginUser = builtins.getEnv "USER";
    in
    if sudoUser != "" && sudoUser != "root" then
      sudoUser
    else if loginUser != "" && loginUser != "root" then
      loginUser
    else
      throw ''
        Unable to determine the Darwin account from the evaluation environment.
        Run darwin-rebuild with --impure so SUDO_USER or USER is available.
      '';
in
{
  den.hosts.aarch64-darwin.macbook = {
    users.${detectedUser}.classes = [ "homeManager" ];
  };

  den.aspects.macbook = {
    darwin = {
      home-manager = {
        backupFileExtension = "before-nix-darwin";
        useGlobalPkgs = true;
        useUserPackages = true;
      };

      nix.enable = true;
      nix.settings.experimental-features = [
        "nix-command"
        "flakes"
      ];

      nixpkgs.hostPlatform = "aarch64-darwin";
    };
  };

  den.aspects.${detectedUser} = {
    includes = [
      den.batteries.primary-user
      (den.batteries.user-shell "zsh")
      den.aspects.workstation
    ];
  };
}
