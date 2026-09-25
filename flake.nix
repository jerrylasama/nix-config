{
  description = "Portable Nix development workstation for NixOS-WSL and Darwin";

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

    darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
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
      androidSdkConfig = import ./lib/nixpkgs-config.nix { inherit lib; };
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

      # The single definition of the portable package set; the packages
      # output below derives from it.
      agentPackageNames = [
        "codex"
        "dcg"
        "gcx"
        "playwright-cli"
        "tirith"
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
        lib.genAttrs agentPackageNames (name: pkgs.callPackage ./packages/${name} { }) // androidPackages
      );

      # `nix fmt` with no args must not hand an empty stdin to nixfmt; format
      # tracked .nix files instead. `nix run .#formatter` needs an `apps` entry.
      nixfmtFormatter =
        system:
        let
          pkgs = inputs.nixpkgs.legacyPackages.${system};
        in
        (pkgs.writeShellScriptBin "nixfmt" ''
          if [ "$#" -eq 0 ]; then
            set -- $(${pkgs.git}/bin/git ls-files '*.nix')
            [ "$#" -eq 0 ] && exit 0
          fi
          exec ${pkgs.nixfmt}/bin/nixfmt "$@"
        '').overrideAttrs
          (old: {
            meta = (old.meta or { }) // {
              mainProgram = "nixfmt";
            };
          });

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
      packages = lib.mapAttrs (_system: packages: lib.getAttrs agentPackageNames packages) customPackages;
      formatter = lib.genAttrs supportedSystems nixfmtFormatter;
      apps = lib.genAttrs supportedSystems (system: {
        formatter = {
          type = "app";
          program = "${nixfmtFormatter system}/bin/nixfmt";
        };
      });
    };
}
