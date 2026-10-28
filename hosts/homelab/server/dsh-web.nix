_: {
  flake.nixosModules.dsh-web = {
    config,
    lib,
    pkgs,
    ...
  }: let
    cfg = config.services.dsh-web;
    dshBin = "/home/${cfg.user}/.local/bin/dsh";
    preStartScript = pkgs.writeShellScript "dsh-web-prestart" ''
      export PATH="/home/${cfg.user}/.local/bin:/etc/profiles/per-user/${cfg.user}/bin:${pkgs.nodejs}/bin:${pkgs.coreutils}/bin:${pkgs.findutils}/bin:${pkgs.gnused}/bin:$PATH"
      export NPM_CONFIG_PREFIX="/home/${cfg.user}/.local"

      if command -v update-ai-tools >/dev/null 2>&1; then
        update-ai-tools || true
      fi

      dsh_target="/home/${cfg.user}/.local/lib/node_modules/@deepseek-ai/dsh/lib/bin.js"
      if [ ! -f "$dsh_target" ]; then
        ${pkgs.nodejs}/bin/npm install -g --prefix "/home/${cfg.user}/.local" --force @deepseek-ai/dsh @deepseek-harness-tui/dsh-tui
      fi

      find "/home/${cfg.user}/.local" -path "*/node-addon-require-builtin/lib/index.js" 2>/dev/null | while read -r target; do
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

      find "/home/${cfg.user}/.local" "/home/${cfg.user}/.dsh" -path "*/@deepseek-harness-tui/dsh-tui/bin/dsh-tui.js" 2>/dev/null | while read -r tui_js; do
        ${pkgs.gnused}/bin/sed -i 's/spawn(process\.execPath, \[entry,/spawn(process.execPath, ["--expose-internals", entry,/g' "$tui_js"
        ${pkgs.gnused}/bin/sed -i 's/spawn(process\.execPath, \[profileBin,/spawn(process.execPath, ["--expose-internals", profileBin,/g' "$tui_js"
      done

      dsh_target="/home/${cfg.user}/.local/lib/node_modules/@deepseek-ai/dsh/lib/bin.js"
      if [ -f "$dsh_target" ]; then
        rm -f "${dshBin}"
        printf '#!/usr/bin/env bash\nexport PATH="%s:$PATH"\nexec "%s" --expose-internals "%s" "$@"\n' \
          "${pkgs.nodejs}/bin" "${pkgs.nodejs}/bin/node" "$dsh_target" > "${dshBin}"
        chmod +x "${dshBin}"
      fi

      dsh_tui_target="/home/${cfg.user}/.local/lib/node_modules/@deepseek-harness-tui/dsh-tui/bin/dsh-tui.js"
      if [ -f "$dsh_tui_target" ]; then
        for cmd in dsh-tui dst; do
          rm -f "/home/${cfg.user}/.local/bin/$cmd"
          printf '#!/usr/bin/env bash\nexport PATH="%s:$PATH"\nexec "%s" --expose-internals "%s" "$@"\n' \
            "${pkgs.nodejs}/bin" "${pkgs.nodejs}/bin/node" "$dsh_tui_target" > "/home/${cfg.user}/.local/bin/$cmd"
          chmod +x "/home/${cfg.user}/.local/bin/$cmd"
        done
      fi

      "${dshBin}" --version
    '';
  in {
    options.services.dsh-web = {
      enable = lib.mkEnableOption "DeepSeek Harness Web GUI service";

      port = lib.mkOption {
        type = lib.types.port;
        default = 3080;
        description = "Port to listen on for the Web GUI.";
      };

      host = lib.mkOption {
        type = lib.types.str;
        default = "127.0.0.1";
        description = "Bind address for the Web GUI.";
      };

      user = lib.mkOption {
        type = lib.types.str;
        default = "kryisnn";
        description = "User under which the DSH Web service runs.";
      };

      publicUrl = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Advertised public URL behind reverse proxy.";
      };

      trustedHosts = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [
          "homelab.auxois-searobin.ts.net"
          "homelab"
        ];
        description = "Accepted host authorities for the Web GUI.";
      };
    };

    config = lib.mkIf cfg.enable {
      systemd.services.dsh-web = {
        description = "DeepSeek Harness Web GUI";
        after = ["network-online.target" "tailscaled.service"];
        wants = ["network-online.target"];
        wantedBy = ["multi-user.target"];

        environment = {
          HOME = "/home/${cfg.user}";
        };

        path = [
          "/home/${cfg.user}/.local/bin"
          "/etc/profiles/per-user/${cfg.user}/bin"
          pkgs.nodejs
          pkgs.coreutils
          pkgs.bash
          pkgs.findutils
          pkgs.gnugrep
          pkgs.gnused
          pkgs.git
          pkgs.rtk
          pkgs.graphify
        ];

        serviceConfig = {
          Type = "simple";
          User = cfg.user;
          Group = "users";
          WorkingDirectory = "/home/${cfg.user}";
          Restart = "on-failure";
          RestartSec = "10s";

          ExecStartPre = preStartScript;
          ExecStart = lib.concatStringsSep " " (
            [
              dshBin
              "web"
              "--no-open"
              "--host"
              cfg.host
              "--port"
              (toString cfg.port)
            ]
            ++ lib.optionals (cfg.publicUrl != null) [
              "--public-url"
              cfg.publicUrl
            ]
            ++ lib.concatMap (host: ["--trusted-host" host]) cfg.trustedHosts
          );
        };
      };
    };
  };
}
