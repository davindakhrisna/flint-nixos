{pkgs, ...}: let
  inherit (pkgs) git nodejs pnpm;

  # Patch node-addon-require-builtin for NixOS internals compatibility
  patchRequireBuiltin = ''
    find "$HOME/.local" "$HOME/.dsh" -path "*/node-addon-require-builtin/lib/index.js" 2>/dev/null | while read -r target; do
      if ! grep -q "expose-internals" "$target" 2>/dev/null; then
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
        return { mode: 'napi', product: 'require-builtin', backend: 'expose-internals', abi: 'native' };
    }
    exports.default = {
        requireBuiltin,
        isAllowedInternalId,
        getBindingInfo,
    };
    EOF
      fi
    done
  '';

  # Patch dsh-tui launcher to forward --expose-internals
  patchTui = ''
    find "$HOME/.local" "$HOME/.dsh" -path "*/@deepseek-harness-tui/dsh-tui/bin/dsh-tui.js" 2>/dev/null | while read -r tui_js; do
      ${pkgs.gnused}/bin/sed -i 's/spawn(process\.execPath, \[entry,/spawn(process.execPath, ["--expose-internals", entry,/g' "$tui_js"
      ${pkgs.gnused}/bin/sed -i 's/spawn(process\.execPath, \[profileBin,/spawn(process.execPath, ["--expose-internals", profileBin,/g' "$tui_js"
    done
  '';

  dsh = pkgs.writeShellScriptBin "dsh" ''
    export PATH="${nodejs}/bin:${pnpm}/bin:${git}/bin:${pkgs.coreutils}/bin:${pkgs.findutils}/bin:${pkgs.gnused}/bin:$HOME/.local/bin:$PATH"
    export PNPM_HOME="$HOME/.local/share/pnpm"
    export NPM_CONFIG_PREFIX="$HOME/.local"

    dsh_target="$HOME/.local/lib/node_modules/@deepseek-ai/dsh/lib/bin.js"
    if [ ! -f "$dsh_target" ]; then
      echo "==> Initializing DeepSeek Harness (dsh)..." >&2
      mkdir -p "$HOME/.local/lib" "$HOME/.local/bin" "$HOME/.local/share/pnpm"
      "${nodejs}/bin/npm" install -g --prefix "$HOME/.local" --force @deepseek-ai/dsh @deepseek-harness-tui/dsh-tui
    fi

    ${patchRequireBuiltin}
    ${patchTui}

    exec "${nodejs}/bin/node" --expose-internals "$dsh_target" "$@"
  '';

  dshTui = pkgs.writeShellScriptBin "dsh-tui" ''
    export PATH="${nodejs}/bin:${pnpm}/bin:${git}/bin:${pkgs.coreutils}/bin:${pkgs.findutils}/bin:${pkgs.gnused}/bin:$HOME/.local/bin:$PATH"
    export PNPM_HOME="$HOME/.local/share/pnpm"
    export NPM_CONFIG_PREFIX="$HOME/.local"

    dsh_tui_target="$HOME/.local/lib/node_modules/@deepseek-harness-tui/dsh-tui/bin/dsh-tui.js"
    dsh_target="$HOME/.local/lib/node_modules/@deepseek-ai/dsh/lib/bin.js"
    if [ ! -f "$dsh_tui_target" ] || [ ! -f "$dsh_target" ]; then
      echo "==> Initializing DeepSeek Harness TUI (dsh-tui)..." >&2
      mkdir -p "$HOME/.local/lib" "$HOME/.local/bin" "$HOME/.local/share/pnpm"
      "${nodejs}/bin/npm" install -g --prefix "$HOME/.local" --force @deepseek-ai/dsh @deepseek-harness-tui/dsh-tui
    fi

    ${patchRequireBuiltin}
    ${patchTui}

    if [ -f "$dsh_target" ] && [ ! -d "$HOME/.dsh/profiles/dsh-tui/node_modules/@deepseek-harness-tui/dsh-tui" ]; then
      "${nodejs}/bin/node" --expose-internals "$dsh_target" plugin --profile dsh-tui add "@deepseek-harness-tui/dsh-tui" || true
    fi

    exec "${nodejs}/bin/node" --expose-internals "$dsh_tui_target" "$@"
  '';

  dst = pkgs.writeShellScriptBin "dst" ''
    exec "${dshTui}/bin/dsh-tui" "$@"
  '';
in {
  inherit dsh dshTui dst;
}
