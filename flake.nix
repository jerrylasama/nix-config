{
  description = "Portable Nix development workstation for NixOS-WSL, NixOS, and Darwin";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    den.url = "github:denful/den";
    import-tree.url = "github:denful/import-tree";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs:
    let
      lib = inputs.nixpkgs.lib;
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];
      androidSdkConfig = {
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
      };
      androidSdkExtraLicenses = [
        "android-googletv-license"
        "android-googlexr-license"
        "android-sdk-arm-dbt-license"
        "android-sdk-preview-license"
        "google-gdk-license"
        "intel-android-extra-license"
        "intel-android-sysimage-license"
        "microxr-sysimage-license"
        "mips-android-sysimage-license"
      ];

      customPackages = lib.genAttrs supportedSystems (
        system:
        let
          pkgs = import inputs.nixpkgs {
            inherit system;
            config = androidSdkConfig;
          };
          androidPackages = lib.optionalAttrs (lib.hasSuffix "-linux" system) {
            android-sdk =
              (pkgs.androidenv.composeAndroidPackages {
                platformVersions = [ "36" ];
                buildToolsVersions = [ "36.0.0" ];
                toolsVersion = null;
                extraLicenses = androidSdkExtraLicenses;
                includeCmake = false;
                includeEmulator = false;
                includeNDK = false;
                includeSources = false;
                includeSystemImages = false;
                includeExtras = [ ];
              }).androidsdk;
          };
        in
        {
          playwright-cli = pkgs.callPackage ./packages/playwright-cli { };
        }
        // androidPackages
      );

      den =
        (inputs.nixpkgs.lib.evalModules {
          modules = [ (inputs.import-tree ./modules) ];
          specialArgs.inputs = inputs // {
            inherit customPackages;
          };
        }).config.flake;
    in
    den
    // {
      packages = lib.mapAttrs (_system: packages: {
        inherit (packages) playwright-cli;
      }) customPackages;
      formatter = lib.genAttrs supportedSystems (system: inputs.nixpkgs.legacyPackages.${system}.nixfmt);
    };
}
