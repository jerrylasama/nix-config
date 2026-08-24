{ den, ... }:
{
  den.aspects.containers = {
    homeManager = { pkgs, ... }: {
      home.packages = [
        pkgs.docker
        pkgs.docker-compose
      ];

      # This links the declarative Compose plugin without touching the user's
      # Docker config, which may contain registry credentials.
      home.file.".docker/cli-plugins/docker-compose".source =
        "${pkgs.docker-compose}/libexec/docker/cli-plugins/docker-compose";
    };

    nixos = { pkgs, ... }: {
      environment.systemPackages = [
        pkgs.docker
        pkgs.docker-compose
      ];
    };
  };
}
