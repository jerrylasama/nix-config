{ den, inputs, ... }:
{
  den.aspects.agents = {
    homeManager =
      {
        lib,
        pkgs,
        ...
      }:
      let
        codex = inputs.customPackages.${pkgs.system}.codex;
        codexSettings = {
          model = "gpt-5.6-luna";
          model_reasoning_effort = "max";
          approvals_reviewer = "auto_review";
          service_tier = "default";
          plan_mode_reasoning_effort = "max";

          tui.status_line = [
            "model-with-reasoning"
            "context-remaining"
            "five-hour-limit"
            "weekly-limit"
          ];
        };
        codexSettingsJson = (pkgs.formats.json { }).generate "codex-settings.json" codexSettings;
      in
      {
        home.packages = [
          pkgs.pi-coding-agent
        ];

        programs.codex = {
          enable = true;
          package = codex;
          # Codex writes project trust into config.toml itself. Let the activation
          # below own a mutable copy instead of linking this file into /nix/store.
          settings = null;
        };

        home.activation.mutableCodexConfig = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
          config_path="$HOME/.codex/config.toml"
          config_dir="$(dirname -- "$config_path")"
          run mkdir -p "$config_dir"

          if [ -e "$config_path" ]; then
            dynamic="$(${lib.getExe pkgs.remarshal} --if toml --of json "$config_path")"
          else
            dynamic='{}'
          fi
          static="$(cat ${lib.escapeShellArg codexSettingsJson})"
          merged="$(${lib.getExe pkgs.jq} -n \
            '$dynamic * $static' \
            --argjson static "$static" \
            --argjson dynamic "$dynamic")"

          temporary="$(mktemp "$config_dir/.config.toml.home-manager.XXXXXX")"
          trap 'rm -f -- "$temporary"' EXIT
          printf '%s\n' "$merged" | ${lib.getExe pkgs.remarshal} --if json --of toml > "$temporary"
          run chmod 600 "$temporary"
          run mv -f -- "$temporary" "$config_path"
          trap - EXIT
          unset config_dir config_path dynamic merged static temporary
        '';
      };
  };
}
