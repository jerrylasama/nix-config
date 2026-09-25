{ den, ... }:
{
  den.aspects.toolchains = {
    homeManager =
      { config, pkgs, ... }:
      let
        llvm = pkgs.llvmPackages;
      in
      {
        home.packages = [
          pkgs.gcc
          pkgs.gnumake
          pkgs.cmake
          pkgs.ninja
          pkgs.pkg-config

          llvm.clang-unwrapped
          llvm.lld
          llvm.lldb

          pkgs.go
          pkgs.gopls

          pkgs.rustc
          pkgs.cargo
          pkgs.rustfmt
          pkgs.clippy
          pkgs.rust-analyzer

          pkgs.nodejs
          pkgs.typescript
          pkgs.vtsls

          pkgs.jdk21
          pkgs.kotlin
          pkgs.gradle

          pkgs.perl
        ];

        programs.uv = {
          enable = true;
          settings = {
            python-downloads = "automatic";
            python-preference = "only-managed";
          };
        };

        home.sessionVariables = {
          GRADLE_USER_HOME = "${config.xdg.cacheHome}/gradle";
        };
      };
  };
}
