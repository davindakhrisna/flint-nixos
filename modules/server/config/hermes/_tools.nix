{inputs}: {
  config,
  lib,
  pkgs,
  ...
}: let
  hermes = config.services.hermes-agent;
  packages = import ./_packages.nix {inherit inputs hermes lib pkgs;};
  inherit (packages) headroom tiktokenCache cuaDriver localExtract codexDelegate serveProject pairWhatsApp liveCheck;
in {
  environment.systemPackages = [pairWhatsApp codexDelegate serveProject liveCheck];
  security.sudo.extraRules = [
    {
      users = [hermes.user];
      runAs = "kryisnn";
      commands = [
        {
          command = "${lib.getExe codexDelegate} *";
          options = ["NOPASSWD"];
        }
      ];
    }
    {
      users = [hermes.user];
      runAs = "root";
      commands = [
        {
          command = "${lib.getExe serveProject} *";
          options = ["NOPASSWD"];
        }
      ];
    }
  ];

  services = {
    gnome.at-spi2-core.enable = true;

    # Local-only search needs neither Redis nor a hosted search API.
    searx = {
      enable = true;
      settings = {
        use_default_settings.engines.keep_only = ["duckduckgo" "bing" "wikipedia"];
        engines = [
          {
            name = "bing";
            disabled = false;
          }
        ];
        # SearXNG replaces this map; no optional plugins or downloaded rule feeds.
        plugins = {};
        server = {
          bind_address = "127.0.0.1";
          port = 9121;
          secret_key = "hermes-local-search";
          limiter = false;
        };
        search.formats = ["html" "json"];
        general.enable_metrics = false;
        outgoing = {
          request_timeout = 6;
          max_request_timeout = 12;
        };
      };
    };

    hermes-agent = {
      package = import ./_runtime.nix {inherit inputs lib pkgs;};
      settings = import ./_settings.nix;
      # Ship the bridge into writable state; the wheel omits these scripts.
      hermesHomeFiles = packages.bridgeFiles // {"SOUL.md" = builtins.readFile ./hermes-soul.md;};
      extraPackages = [pkgs.nodejs pkgs.agent-browser pkgs.chromium pkgs.graphify pkgs.rtk pkgs.git pkgs.xterm headroom cuaDriver codexDelegate serveProject pkgs.sudo];
      extraPlugins = [localExtract];
      environment = {
        SEARXNG_URL = "http://127.0.0.1:9121";
        AGENT_BROWSER_ARGS = "--force-renderer-accessibility";
        AGENT_BROWSER_EXECUTABLE_PATH = "${pkgs.chromium}/bin/chromium";
        HERMES_CUA_DRIVER_CMD = lib.getExe cuaDriver;
        CUA_DRIVER_RS_TELEMETRY_ENABLED = "0";
        CUA_DRIVER_RS_UPDATE_CHECK = "0";
        DISPLAY = ":99";
        XAUTHORITY = "/run/hermes-desktop/Xauthority";
        TIKTOKEN_CACHE_DIR = "${tiktokenCache}";
        HEADROOM_BEACON = "off";
        HEADROOM_TELEMETRY = "off";
        HEADROOM_MCP_CHECK_PROXY = "0";
      };
      mcpServers.headroom = {
        command = lib.getExe headroom;
        args = ["mcp" "serve"];
        env = {
          TIKTOKEN_CACHE_DIR = "${tiktokenCache}";
          HEADROOM_BEACON = "off";
          HEADROOM_TELEMETRY = "off";
          HEADROOM_MCP_CHECK_PROXY = "0";
        };
      };
    };
  };
}
