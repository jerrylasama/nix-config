{ inputs, den, ... }:
{
  den.aspects.secrets = {
    homeManager =
      { config, ... }:
      {
        imports = [ inputs.sops-nix.homeManagerModules.sops ];

        # Default age identity for sops decryption. Generate it with:
        #   age-keygen -o ~/.config/sops/age/keys.txt
        # Override per host or user if a different identity is needed.
        sops.age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
      };
  };
}
