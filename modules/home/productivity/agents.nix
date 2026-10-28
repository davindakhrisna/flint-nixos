{
  flake.homeModules.agents = {
    lib,
    pkgs,
    osConfig ? {},
    ...
  }: let
    enabled = osConfig.var.features.agents or false;

    skillsDir = ./config/instructions/skills;
    rulesDir = ./config/instructions/rules;

    ruleFiles = lib.filterAttrs (
      name: type: type == "regular" && lib.hasSuffix ".md" name
    ) (builtins.readDir rulesDir);

    combinedRules = lib.concatMapStringsSep "\n\n---\n\n" (
      name: builtins.readFile (rulesDir + "/${name}")
    ) (builtins.attrNames ruleFiles);

    dshPkgs = pkgs.callPackage ../../system/packages/_dsh.nix {};

    updateAiTools = pkgs.writeShellApplication {
      name = "update-ai-tools";
      runtimeInputs = with pkgs; [
        coreutils
        curl
        findutils
        gawk
        git
        gnugrep
        gnused
        gnutar
        gzip
        nodejs
        patchelf
        pnpm
        util-linux
      ];
      text = ''
        export PATH="$HOME/.local/bin:$PATH"
        export PNPM_HOME="$HOME/.local/share/pnpm"
        mkdir -p "$HOME/.local/bin" "$HOME/.cache" "$PNPM_HOME"

        exec 9>"$HOME/.cache/update-ai-tools.lock"
        flock -n 9 || exit 0

        # 1. Codex + seed MCP servers into writable ~/.codex/config.toml
        if curl -fsSL https://chatgpt.com/codex/install.sh |
            CODEX_NON_INTERACTIVE=1 CODEX_INSTALL_DIR="$HOME/.local/bin" sh; then
          mkdir -p "$HOME/.codex"
          touch "$HOME/.codex/config.toml"
          if ! grep -q "\[mcp_servers.codebase-memory\]" "$HOME/.codex/config.toml"; then
            cat >> "$HOME/.codex/config.toml" << 'EOF'

        [features]
        hooks = true

        [mcp_servers.codebase-memory]
        command = "codebase-memory-mcp"

        [mcp_servers.serena]
        command = "serena-mcp"
        startup_timeout_sec = 30
        EOF
          fi
        else
          echo "Warning: Codex installation failed or was skipped" >&2
        fi

        # 2. Antigravity CLI
        if curl -fsSL https://antigravity.google/cli/install.sh | bash -s -- --dir "$HOME/.local/bin"; then
          if [[ -f "$HOME/.local/bin/agy" ]]; then
            tmp_agy=$(mktemp "$HOME/.local/bin/agy.tmp.XXXXXX")
            cp "$HOME/.local/bin/agy" "$tmp_agy"
            patchelf --set-interpreter ${lib.escapeShellArg pkgs.stdenv.cc.bintools.dynamicLinker} "$tmp_agy"
            chmod +x "$tmp_agy"
            mv -f "$tmp_agy" "$HOME/.local/bin/agy"
          fi
        else
          echo "Warning: Antigravity installation failed or was skipped" >&2
        fi

        npm install -g --prefix "$HOME/.local" --force @deepseek-ai/dsh @deepseek-harness-tui/dsh-tui

        find "$HOME/.local" "$HOME/.dsh" -path "*/node-addon-require-builtin/lib/index.js" 2>/dev/null | while read -r target; do
          if ! grep -q "expose-internals" "$target"; then
            cat << 'EOF' > "$target"
        "use strict";
        var __importDefault = (this && this.__importDefault) || function (mod) {
            return (mod && mod.__esModule) ? mod : { "default": mod };
        };
        Object.defineProperty(exports, "__esModule", { value: true });
        exports.requireBuiltin = requireBuiltin;
        exports.isAllowedInternalId = isAllowedInternalId;
        exports.getBindingInfo = getBindingInfo;
        const node_path_1 = __importDefault(require("node:path"));

        let api = null;
        function getApi() {
            if (!api) {
                const { createEntryApi } = require('node-addon-native-custom-loader');
                api = createEntryApi(node_path_1.default.resolve(__dirname, '..'));
            }
            return api;
        }

        function requireBuiltin(moduleId) {
            try {
                return require(moduleId);
            } catch {
                return getApi().requireBuiltin(moduleId);
            }
        }
        function isAllowedInternalId(moduleId) {
            return typeof moduleId === 'string' && (moduleId.startsWith('internal/') || !moduleId.includes('/'));
        }
        function getBindingInfo() {
            try {
                return getApi().getBindingInfo();
            } catch {
                return { mode: 'napi', product: 'require-builtin', backend: 'expose-internals', abi: 'native' };
            }
        }
        exports.default = {
            requireBuiltin,
            isAllowedInternalId,
            getBindingInfo,
        };
        EOF
          fi
        done

        find "$HOME/.local" "$HOME/.dsh" -path "*/@deepseek-harness-tui/dsh-tui/bin/dsh-tui.js" 2>/dev/null | while read -r tui_js; do
          sed -i 's/spawn(process\.execPath, \[entry,/spawn(process.execPath, ["--expose-internals", entry,/g' "$tui_js"
          sed -i 's/spawn(process\.execPath, \[profileBin,/spawn(process.execPath, ["--expose-internals", profileBin,/g' "$tui_js"
        done

        dsh_bin="$HOME/.local/lib/node_modules/@deepseek-ai/dsh/lib/bin.js"
        if [[ -f "$dsh_bin" ]]; then
          rm -f "$HOME/.local/bin/dsh"
          ln -sf "${dshPkgs.dsh}/bin/dsh" "$HOME/.local/bin/dsh"
        fi

        dsh_tui_bin="$HOME/.local/lib/node_modules/@deepseek-harness-tui/dsh-tui/bin/dsh-tui.js"
        if [[ -f "$dsh_tui_bin" ]]; then
          for cmd in dsh-tui dst; do
            rm -f "$HOME/.local/bin/$cmd"
            ln -sf "${dshPkgs.dshTui}/bin/$cmd" "$HOME/.local/bin/$cmd"
          done
        fi

        # Ensure dsh-tui profile is initialized declaratively on fresh installs
        if [[ -x "$HOME/.local/bin/dsh" ]] && [[ ! -d "$HOME/.dsh/profiles/dsh-tui/node_modules/@deepseek-harness-tui/dsh-tui" ]]; then
          "$HOME/.local/bin/dsh" plugin --profile dsh-tui add "@deepseek-harness-tui/dsh-tui" || true
        fi
      '';
    };
  in {
    config = lib.mkIf enabled {
      home = {
        sessionPath = [
          "$HOME/.local/bin"
          "$HOME/.local/share/pnpm"
        ];
        sessionVariables = {
          PNPM_HOME = "$HOME/.local/share/pnpm";
        };
        packages = [
          updateAiTools
          pkgs.nodejs
          pkgs.pnpm
          dshPkgs.dsh
          dshPkgs.dshTui
          dshPkgs.dst
        ];

        file = {
          ".codex/AGENTS.md".text = combinedRules;
          ".dsh/AGENTS.md".text = combinedRules;
          ".gemini/GEMINI.md".text = combinedRules;

          ".agents/rules" = {
            source = rulesDir;
            recursive = true;
          };
          ".gemini/antigravity-cli/rules" = {
            source = rulesDir;
            recursive = true;
          };

          ".agents/skills" = {
            source = skillsDir;
            recursive = true;
          };
          ".gemini/antigravity-cli/skills" = {
            source = skillsDir;
            recursive = true;
          };
        };

        activation.updateAiTools = lib.hm.dag.entryAfter ["reloadSystemd"] ''
          [[ -n "''${DRY_RUN_CMD:-}" ]] ||
            ${pkgs.systemd}/bin/systemctl --user start --no-block update-ai-tools.service || true
        '';
      };

      systemd.user = {
        services.update-ai-tools = {
          Unit.Description = "Install and update AI CLI tools";
          Service = {
            Type = "oneshot";
            TimeoutStartSec = "5min";
            ExecStart = lib.getExe updateAiTools;
          };
        };

        timers.update-ai-tools = {
          Unit.Description = "Keep AI CLI tools current";
          Timer = {
            OnStartupSec = "1m";
            OnUnitActiveSec = "1h";
            Persistent = true;
          };
          Install.WantedBy = ["timers.target"];
        };
      };
    };
  };
}
