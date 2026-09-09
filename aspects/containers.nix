{ den, ... }:
{
  den.aspects.containers = {
    homeManager = { pkgs, ... }: {
      home.packages = [
        pkgs.docker
        pkgs.docker-compose
      ];

      # Docker Desktop already manages ~/.docker/cli-plugins/docker-compose on
      # macOS. Keep that machine-local symlink unmanaged; docker-compose is
      # still available from home.packages above.
    };

    nixos = { pkgs, ... }: {
      environment.systemPackages = [
        pkgs.docker
        pkgs.docker-compose
      ];
    };
  };
}
