{ den, ... }:
{
  den.aspects.agents = {
    homeManager = { pkgs, ... }: {
      home.packages = [
        pkgs.codex
        pkgs.pi-coding-agent
      ];
    };
  };
}
