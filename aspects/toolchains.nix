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
          python = {
            versions = [ "3.14.7" ];
            default = [ "3.14.7" ];
          };
          # `--default` shims only `python`/`python3`; uv never exposes pip.
          # Install pip as a uv tool so bare `pip` also resolves.
          tool.packages = [ "pip" ];
        };

        home.sessionPath = [ "$HOME/.local/bin" ];

        home.sessionVariables = {
          GRADLE_USER_HOME = "${config.xdg.cacheHome}/gradle";
        };
      };

    # uv-managed Pythons are upstream (python-build-standalone) binaries that
    # expect a conventional dynamic loader at /lib64/ld-linux-*.so.2. NixOS
    # puts only a stub there, which refuses to run them; nix-ld supplies a
    # working loader so the installed interpreters and shims can execute.
    nixos = {
      programs.nix-ld.enable = true;
    };
  };
}
