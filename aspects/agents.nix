{ den, ... }:
{
  den.aspects.agents = {
    homeManager = { pkgs, ... }: {
      home.packages = [
        pkgs.pi-coding-agent
      ];

      programs.codex = {
        enable = true;

        settings = {
          model = "gpt-5.6-luna";
          model_reasoning_effort = "max";
          approvals_reviewer = "auto_review";
          service_tier = "default";
          plan_mode_reasoning_effort = "max";

          projects."/path/to/nix-config" = {
            trust_level = "trusted";
          };

          tui.status_line = [
            "model"
            "context-remaining"
            "five-hour-limit"
            "weekly-limit"
          ];
        };
      };
    };
  };
}
