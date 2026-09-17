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
      null;

  # Den collects aspect names while constructing every flake output. Use a
  # harmless placeholder at that stage so pure evaluations of Linux hosts do
  # not fail because the Darwin account is unavailable.
  darwinUser = if detectedUser != null then detectedUser else "darwin-user";
in
{
  den.hosts.aarch64-darwin.macbook = {
    users.${darwinUser}.classes = [ "homeManager" ];
  };

  den.aspects.macbook = {
    darwin = {
      assertions = [
        {
          assertion = detectedUser != null;
          message = ''
            Unable to determine the Darwin account from the evaluation environment.
            Run darwin-rebuild with --impure so SUDO_USER or USER is available.
          '';
        }
      ];

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

  den.aspects.${darwinUser} = {
    includes = [
      den.batteries.primary-user
      (den.batteries.user-shell "zsh")
      den.aspects.workstation
    ];
  };
}
