# Shared nixpkgs config: the Android SDK unfree allowlist. Imported by
# flake.nix (customPackages) and hosts/wsl.nix (nixpkgs.config); keep the
# two call sites behaviorally identical.
{ lib }:
{
  allowUnfreePredicate =
    pkg:
    lib.elem (lib.getName pkg) [
      "android-sdk-cmdline-tools"
      "cmdline-tools"
      "android-sdk-platform-tools"
      "platform-tools"
      "android-sdk-build-tools"
      "build-tools"
      "android-sdk-platforms"
      "platforms"
    ];
  android_sdk.accept_license = true;
}
