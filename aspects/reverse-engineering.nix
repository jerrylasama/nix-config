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
        pkgs.ltrace
      ];
    };
  };
}
