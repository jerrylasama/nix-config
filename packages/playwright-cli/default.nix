{ lib, buildNpmPackage, ... }:

buildNpmPackage rec {
  pname = "playwright-cli";
  version = "0.1.18";

  src = ./.;
  npmDepsHash = "sha256-I1ZC7FvbV9gvGoi585pEVKe5t6OI+Y+Ph6zcMMaEDF0=";
  dontNpmBuild = true;
  npmInstallFlags = [ "--ignore-scripts" ];
  npmPruneFlags = [ "--ignore-scripts" ];

  meta = {
    description = "Official Playwright CLI for coding agents";
    homepage = "https://playwright.dev/agent-cli";
    license = lib.licenses.asl20;
    mainProgram = "playwright-cli";
    platforms = lib.platforms.unix;
  };
}
