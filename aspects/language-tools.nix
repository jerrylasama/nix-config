{ den, ... }:
{
  den.aspects.language-tools = {
    homeManager = { pkgs, ... }: {
      home.packages = [
        pkgs.jdt-language-server
        pkgs.kotlin-language-server
        pkgs.perlnavigator

        pkgs.ruff
        pkgs.basedpyright

        pkgs.dotnet-sdk_10
        pkgs.csharp-ls

        pkgs.nixd
        pkgs.nixfmt
      ];
    };
  };
}
