{ den, inputs, ... }:
{
  den.aspects.mobile = {
    homeManager =
      { lib, pkgs, ... }:
      let
        isLinux = pkgs.stdenv.hostPlatform.isLinux;
        system = pkgs.stdenv.hostPlatform.system;
        android = if isLinux then inputs.customPackages.${system}.android-sdk else null;
        sdkRoot = if isLinux then "${android}/libexec/android-sdk" else null;
      in
      {
        home.packages = [ pkgs.flutter ] ++ lib.optional isLinux android;

        home.sessionVariables = lib.mkIf isLinux {
          ANDROID_HOME = sdkRoot;
          ANDROID_SDK_ROOT = sdkRoot;
        };
      };
  };
}
