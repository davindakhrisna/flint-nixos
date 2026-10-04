let
  enabledTools = ["terminal" "file" "memory" "session_search" "skills" "todo" "clarify" "browser" "web" "computer_use" "delegation" "mcp-headroom"];
in {
  model = {
    default = "Agentic";
    provider = "9router";
    base_url = "";
    api_key = "";
    api_mode = "chat_completions";
  };
  providers."9router" = {
    name = "9router";
    base_url = "http://localhost:20128/v1";
    key_env = "OPENAI_API_KEY";
    api_mode = "chat_completions";
    default_model = "Agentic";
    models = ["Casual" "Agentic"];
  };
  plugins.enabled = ["web-local-extract"];
  terminal.backend = "local";
  browser = {
    backend = "off";
    cloud_provider = "local";
    engine = "chrome";
    headed = true;
    allow_private_urls = true;
    inactivity_timeout = 120;
    record_sessions = false;
  };
  web = {
    search_backend = "searxng";
    extract_backend = "local-extract";
    keyless_fallback = false;
    keyless_rescue = false;
  };
  computer_use = {
    cua_telemetry = false;
    no_overlay = true;
    ax_max_elements = 200;
  };
  auth.adopt_external_logins = false;
  platforms.whatsapp.bridge_port = 9122;
  # The dashboard also uses the CLI tool selection.
  platform_toolsets = {
    cli = enabledTools;
    whatsapp = enabledTools;
  };
}
