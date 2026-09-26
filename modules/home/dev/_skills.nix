{
  config,
  lib,
  ...
}: {
  config = lib.mkIf (builtins.elem config.dev ["minimal" "full"]) {
    home.file = {
      # Global Agent Skills
      ".agents/skills" = {
        source = ./config/skills;
        recursive = true;
        force = true;
      };

      # Oh My Pi Skills
      ".omp/agent/skills" = {
        source = ./config/skills;
        recursive = true;
        force = true;
      };

      # Global Agent Commands
      ".agents/commands" = {
        source = ./config/commands;
        recursive = true;
        force = true;
      };

      # Oh My Pi Commands
      ".omp/agent/commands" = {
        source = ./config/commands;
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
      ".gemini/config/skills/thermo-nuclear-code-quality-review" = {
        source = ./config/skills/thermo-nuclear-code-quality-review;
        recursive = true;
        force = true;
      };
      ".gemini/config/skills/improve-codebase-architecture" = {
        source = ./config/skills/improve-codebase-architecture;
        recursive = true;
        force = true;
      };
    };

    home.activation.syncCodexSkills = lib.hm.dag.entryAfter ["writeBoundary"] ''
      $DRY_RUN_CMD mkdir -p "$HOME/.codex/skills"
      for skill_dir in ${./config/skills}/*; do
        if [ -d "$skill_dir" ]; then
          skill_name=$(basename "$skill_dir")
          $DRY_RUN_CMD rm -rf "$HOME/.codex/skills/$skill_name"
          $DRY_RUN_CMD cp -rL "$skill_dir" "$HOME/.codex/skills/$skill_name"
          $DRY_RUN_CMD chmod -R u+w "$HOME/.codex/skills/$skill_name"
        fi
      done
    '';
  };
}
