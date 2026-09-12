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
        codex = inputs.customPackages.${pkgs.stdenv.hostPlatform.system}.codex;
        dcg = inputs.customPackages.${pkgs.stdenv.hostPlatform.system}.dcg;
        pi = pkgs.pi-coding-agent;
        tirithPiExtension = pkgs.runCommand "tirith-pi-extension.ts" { } ''
          export HOME="$TMPDIR/tirith-home"
          mkdir -p "$HOME"
          ${lib.getExe pkgs.tirith} setup pi-cli --scope user --update-configs --force --quiet
          install -Dm755 "$HOME/.pi/agent/extensions/tirith-guard.ts" "$out"
        '';
        piSettings = {
          defaultProvider = "hyper";
          defaultModel = "glm-5.3-flash";
          defaultThinkingLevel = "high";
          enabledModels = [ "hyper/*" ];
          defaultTools = [
            "read"
            "grep"
            "find"
            "ls"
            "bash"
            "edit"
            "write"
          ];

          theme = "dark";
          tuiMode = "regular";
          quietStartup = false;
          defaultProjectTrust = "ask";
          enableInstallTelemetry = false;
          enableAnalytics = false;

          doubleEscapeAction = "tree";
          treeFilterMode = "default";
          compaction = {
            enabled = true;
            reserveTokens = 16384;
            keepRecentTokens = 20000;
          };
          branchSummary = {
            reserveTokens = 16384;
            skipPrompt = false;
          };
          retry = {
            enabled = true;
            maxRetries = 3;
            baseDelayMs = 2000;
            maxAgentDelayMs = 60000;
            provider = {
              timeoutMs = 3600000;
              maxRetries = 0;
              maxRetryDelayMs = 60000;
            };
          };
          steeringMode = "one-at-a-time";
          followUpMode = "one-at-a-time";
          transport = "auto";
          httpIdleTimeoutMs = 300000;
          websocketConnectTimeoutMs = 15000;
          terminal = {
            showImages = true;
            imageWidthCells = 60;
            clearOnShrink = false;
            hyperlinks = "auto";
            images = "auto";
            trueColor = "auto";
          };
          images = {
            autoResize = true;
            blockImages = false;
          };

          # Keep credentials in Pi's provider process, but remove every
          # documented provider credential from agent-generated shells.
          shellCommandPrefix = ''
            unset ANTHROPIC_API_KEY ANT_LING_API_KEY AZURE_OPENAI_API_KEY OPENAI_API_KEY DEEPSEEK_API_KEY NVIDIA_API_KEY GEMINI_API_KEY AWS_BEARER_TOKEN_BEDROCK MISTRAL_API_KEY GROQ_API_KEY CEREBRAS_API_KEY CLOUDFLARE_API_KEY CLOUDFLARE_ACCOUNT_ID CLOUDFLARE_GATEWAY_ID XAI_API_KEY OPENROUTER_API_KEY AI_GATEWAY_API_KEY ZAI_API_KEY ZAI_CODING_CN_API_KEY OPENCODE_API_KEY RADIUS_API_KEY HF_TOKEN FIREWORKS_API_KEY TOGETHER_API_KEY BASETEN_API_KEY KIMI_API_KEY MINIMAX_API_KEY MINIMAX_CN_API_KEY QWEN_TOKEN_PLAN_API_KEY QWEN_TOKEN_PLAN_CN_API_KEY XIAOMI_API_KEY XIAOMI_TOKEN_PLAN_CN_API_KEY XIAOMI_TOKEN_PLAN_AMS_API_KEY XIAOMI_TOKEN_PLAN_SGP_API_KEY HYPER_API_KEY AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN AWS_PROFILE AWS_WEB_IDENTITY_TOKEN_FILE AWS_CONTAINER_CREDENTIALS_FULL_URI AWS_CONTAINER_CREDENTIALS_RELATIVE_URI AWS_CONTAINER_AUTHORIZATION_TOKEN AWS_CONTAINER_AUTHORIZATION_TOKEN_FILE GOOGLE_APPLICATION_CREDENTIALS
          '';

          packages = [
            "npm:@charmland/pi-hyper-provider@0.3.2"
            "npm:pi-clear@0.1.1"
            "npm:pi-web-access@0.29.0"
            "npm:pi-subagents@0.67.0"
            "npm:@juicesharp/rpiv-ask-user-question@2.10.0"
          ];
          extensions = [
            "extensions/tirith-guard.ts"
            "extensions/dcg-guard.ts"
            "extensions/protected-path-guard.ts"
          ];
        };
        piSettingsJson = (pkgs.formats.json { }).generate "pi-settings.json" piSettings;
        piWrapped = pkgs.writeShellApplication {
          name = "pi";
          text = ''
            secrets_file="$HOME/.pi/agent/secrets.env"

            if [ -e "$secrets_file" ] || [ -L "$secrets_file" ]; then
              if [ -L "$secrets_file" ] || [ ! -f "$secrets_file" ]; then
                printf 'pi: ignoring %s: it must be a regular, non-symlink file\n' "$secrets_file" >&2
              elif ! permissions="$(${pkgs.coreutils}/bin/stat -c '%a' -- "$secrets_file")"; then
                printf 'pi: ignoring %s: unable to verify its permissions\n' "$secrets_file" >&2
              elif (( (8#$permissions & 8#77) != 0 )); then
                printf 'pi: ignoring %s: remove all group/world permissions (chmod 600)\n' "$secrets_file" >&2
              else
                set -a
                # shellcheck disable=SC1090
                . "$secrets_file"
                set +a
              fi
            fi
            unset permissions secrets_file

            exec ${lib.getExe pi} "$@"
          '';
        };
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
          dcg
          piWrapped
          pkgs.tirith
        ];

        home.file = {
          ".agents/skills/unslop/SKILL.md".source = ../dotfiles/pi/skills/unslop/SKILL.md;
          ".pi/agent/extensions/tirith-guard.ts".source = tirithPiExtension;
          ".pi/agent/extensions/dcg-guard.ts".source = ../dotfiles/pi/extensions/dcg-guard.ts;
          ".pi/agent/extensions/protected-path-guard.ts".source =
            ../dotfiles/pi/extensions/protected-path-guard.ts;
          ".pi/agent/secrets.env.example".source = ../dotfiles/pi/secrets.env.example;
        };

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

        home.activation.mutablePiSettings = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
          pi_dir="$HOME/.pi/agent"
          settings_path="$pi_dir/settings.json"
          if [ -L "$HOME/.pi" ] || [ -L "$pi_dir" ]; then
            echo "Pi: refusing to manage settings through a symlinked ~/.pi or ~/.pi/agent directory." >&2
            exit 1
          fi
          run mkdir -p "$pi_dir"
          run chmod 700 "$HOME/.pi" "$pi_dir"

          temporary="$(mktemp "$pi_dir/.settings.json.home-manager.XXXXXX")"
          trap 'rm -f -- "$temporary"' EXIT
          cat ${lib.escapeShellArg piSettingsJson} > "$temporary"
          run chmod 600 "$temporary"
          run mv -f -- "$temporary" "$settings_path"
          trap - EXIT

          if [ ! -e "$pi_dir/secrets.env" ]; then
            echo "Pi: optional API-key file is absent; copy $pi_dir/secrets.env.example to $pi_dir/secrets.env and chmod 600 it, or use /login for Hyper OAuth."
          fi
          unset pi_dir settings_path temporary
        '';
      };
  };
}
