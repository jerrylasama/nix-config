{ den, inputs, ... }:
{
  den.aspects.browser-tools = {
    homeManager =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      let
        playwrightCli = inputs.customPackages.${pkgs.system}.playwright-cli;
        cliConfig = builtins.toJSON {
          browser = {
            browserName = "chromium";
            launchOptions = {
              executablePath = "${pkgs.chromium}/bin/chromium";
              headless = true;
              args = [
                "--no-sandbox"
                "--disable-dev-shm-usage"
              ];
            };
          };
        };
      in
      {
        home.packages = [
          playwrightCli
        ]
        ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [ pkgs.chromium ];

        home.file = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
          ".config/playwright/cli.config.json".text = cliConfig;
        };

        home.sessionVariables = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
          CHROME_EXECUTABLE = "${pkgs.chromium}/bin/chromium";
          PLAYWRIGHT_MCP_CONFIG = "${config.home.homeDirectory}/.config/playwright/cli.config.json";
        };
      };
  };
}
