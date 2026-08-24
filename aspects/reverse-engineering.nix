{ den, ... }:
{
  den.aspects.reverse-engineering = {
    homeManager = { lib, pkgs, ... }: {
      home.packages =
        with pkgs;
        [
          radare2
          binwalk

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
