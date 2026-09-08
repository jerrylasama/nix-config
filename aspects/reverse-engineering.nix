{ den, ... }:
{
  den.aspects.reverse-engineering = {
    homeManager = { lib, pkgs, ... }: {
      home.packages =
        with pkgs;
        [
          radare2
          binwalk
          ghidra

          android-tools
          apktool
          jadx
          ilspycmd
        ]
        ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [
          strace
          ltrace
        ];
    };
  };
}
