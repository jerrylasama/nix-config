{ den, inputs, ... }:
{
  den.aspects.grafana = {
    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ inputs.customPackages.${pkgs.stdenv.hostPlatform.system}.gcx ];
      };
  };
}
