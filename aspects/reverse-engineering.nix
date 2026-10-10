{ den, ... }:
{
  den.aspects.reverse-engineering = {
    homeManager = { lib, pkgs, ... }: {
      home.packages = [
        pkgs.radare2
        pkgs.binwalk
        pkgs.ghidra

        pkgs.android-tools
        pkgs.apktool
        pkgs.jadx
        pkgs.ilspycmd
      ]
      ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [
        pkgs.strace
        # ltrace's dejagnu suite is flaky and fails the build (nixpkgs#449414, #475879)
        (pkgs.ltrace.overrideAttrs (_: {
          doCheck = false;
        }))
      ];
    };
  };
}
