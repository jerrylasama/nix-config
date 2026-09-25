{ den, inputs, ... }:
{
  den.aspects.agents = {
    homeManager =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      let
        codex = inputs.customPackages.${pkgs.stdenv.hostPlatform.system}.codex;
        dcg = inputs.customPackages.${pkgs.stdenv.hostPlatform.system}.dcg;
        tirith = inputs.customPackages.${pkgs.stdenv.hostPlatform.system}.tirith;
        pi = pkgs.pi-coding-agent;
        # The generated files are vendored; the reason and re-vendor procedure
        # live in packages/tirith/default.nix. The pi extension is generated
        # with TIRITH_BIN set to the store path; it is kept as a PATH lookup
        # so it works from home.packages.
        tirithPiExtension = ../dotfiles/pi/extensions/tirith-guard.ts;
        tirithCodexGateway = ../dotfiles/tirith/gateway.yaml;
        tirithGatewayConfig = "${config.home.homeDirectory}/.config/tirith/gateway.yaml";
        # Single source of truth for Pi's deployed settings.json. Byte-compared
        # against the deployed file by scripts/verify.sh.
        piSettingsJson = ../dotfiles/pi/settings.json;
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

            status=0
            ${lib.getExe pi} "$@" || status=$?

            # Pi keys packages by source, so the git install and a local
            # checkout are two packages. Both load, and their bundled tools
            # collide, which aborts startup before any extension can react.
            # After an install, keep the checkout this machine works in and
            # drop the other registration. On a development host that is the
            # working tree under ~/src; elsewhere it is the git clone, which
            # only exists once the install above created it.
            if [ "''${1:-}" = "install" ]; then
              guard=""
              for candidate in "''${PI_EXTENSIONS_ROOT:-}" "$HOME/src/pi-extensions" "$HOME/.pi/agent/git/gitlab.com/jlasama-lab/pi-extensions"; do
                if [ -n "$candidate" ] && [ -f "$candidate/tools/sync-packages.mjs" ]; then
                  guard="$candidate/tools/sync-packages.mjs"
                  break
                fi
              done
              if [ -n "$guard" ]; then
                ${lib.getExe pkgs.nodejs} "$guard" --fix || true
              fi
            fi

            exit "$status"
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

          # Agent-side tirith guard. The gateway proxies MCP tool calls, so it
          # never sees codex's own shell tool; what it adds is tirith's check
          # tools plus policy enforcement on any shell-shaped MCP tool.
          mcp_servers."tirith-gateway" = {
            command = lib.getExe tirith;
            args = [
              "gateway"
              "run"
              "--upstream-bin"
              (lib.getExe tirith)
              "--upstream-arg"
              "mcp-server"
              "--config"
              tirithGatewayConfig
            ];
          };
        };
        codexSettingsJson = (pkgs.formats.json { }).generate "codex-settings.json" codexSettings;
      in
      {
        home.packages = [
          dcg
          piWrapped
          # Agent-only guard. No tirith shell hooks: they intercept interactive
          # input, so they would gate the human's prompt and miss every agent.
          tirith
        ];

        home.file = {
          ".pi/agent/extensions/tirith-guard.ts".source = tirithPiExtension;
          ".pi/agent/extensions/dcg-guard.ts".source = ../dotfiles/pi/extensions/dcg-guard.ts;
          ".pi/agent/extensions/protected-path-guard.ts".source =
            ../dotfiles/pi/extensions/protected-path-guard.ts;
          ".pi/agent/secrets.env.example".source = ../dotfiles/pi/secrets.env.example;
          ".config/tirith/gateway.yaml".source = tirithCodexGateway;
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
          cat ${piSettingsJson} > "$temporary"
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
