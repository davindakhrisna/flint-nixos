{
  config,
  lib,
  ...
}: {
  config = lib.mkIf (builtins.elem config.dev ["minimal" "full"]) {
    home.file = {
      # Global Agent Skills (All 5 skills)
      ".agents/skills" = {
        source = ./config/skills;
        recursive = true;
        force = true;
      };

      # Codex CLI Skills (All 5 skills)
      ".codex/skills" = {
        source = ./config/skills;
        recursive = true;
        force = true;
      };

      # Pi Coding Agent Skills (All 5 skills)
      ".pi/agent/skills" = {
        source = ./config/skills;
        recursive = true;
        force = true;
      };

      # Google Antigravity CLI Skills
      # Option A: Exclude 'grill-me' because Antigravity already has the built-in /grill-me slash command
      ".gemini/config/skills/codebase-design" = {
        source = ./config/skills/codebase-design;
        recursive = true;
        force = true;
      };
      ".gemini/config/skills/frontend-design" = {
        source = ./config/skills/frontend-design;
        recursive = true;
        force = true;
      };
      ".gemini/config/skills/impeccable" = {
        source = ./config/skills/impeccable;
        recursive = true;
        force = true;
      };
      ".gemini/config/skills/ponytail" = {
        source = ./config/skills/ponytail;
        recursive = true;
        force = true;
      };
    };
  };
}
