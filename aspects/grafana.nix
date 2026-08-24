{ den, ... }:
{
  den.aspects.grafana = {
    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.gcx ];
      };
  };
}
