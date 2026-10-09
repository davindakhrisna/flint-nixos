{
  config,
  lib,
  ...
}: let
  catalog = import ./_antigravity-commands.nix;
  sharedSkills = lib.filterAttrs (name: type: type == "directory" && name != "grill-me") (builtins.readDir ./skills);
  sharedCommands = lib.filterAttrs (name: type: type == "regular" && lib.hasSuffix ".md" name) (builtins.readDir ./commands);
  workflows =
    catalog.workflows
    // builtins.mapAttrs (name: prompt: {
      description = "Map Codex /${name} to Antigravity controls when the user requests that command.";
      inherit prompt;
    })
    catalog.redirects;
in {
  config = lib.mkIf (builtins.elem config.dev ["light" "medium" "heavy"]) {
    home.file =
      {
        # Global Agent Skills
        ".agents/skills" = {
          source = ./skills;
          recursive = true;
          force = true;
        };

        # Oh My Pi Skills
        ".omp/agent/skills" = {
          source = ./skills;
          recursive = true;
          force = true;
        };

        # Global Agent Commands
        ".agents/commands" = {
          source = ./commands;
          recursive = true;
          force = true;
        };

        # Oh My Pi Commands
        ".omp/agent/commands" = {
          source = ./commands;
          recursive = true;
          force = true;
        };

        # Antigravity CLI has its own discovery root; share the same skill tree.
        ".gemini/antigravity-cli/skills".source =
          config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.gemini/config/skills";

        ".gemini/config/skills/codex-workflows/SKILL.md".text = ''
          ---
          name: codex-workflows
          description: Explain the complete Codex slash-command mapping in Antigravity; use for /codex-workflows or questions about migrating Codex commands.
          ---

          Native Antigravity commands (use their actual UI, not a prompt simulation):
          ${lib.concatMapStringsSep ", " (name: "/${name}") catalog.native}.

          Portable prompt workflows installed as skills:
          ${lib.concatMapStringsSep ", " (name: "/${name}") (builtins.attrNames catalog.workflows)}.

          Compatibility commands below explain the native equivalent or capability
          limitation. They do not execute UI commands, grant permissions, migrate
          provider accounts, or modify internal session databases:

          ${lib.concatStringsSep "\n" (lib.mapAttrsToList (name: prompt: "- /${name}: ${prompt}") catalog.redirects)}

          /compact creates a handoff checkpoint; it cannot itself free context. Use
          native /clear or /new and load the handoff in the next chat. Antigravity
          /fast has its own execution semantics, not Codex's service-tier semantics.
          /goal, /plan, account usage, and other native controls also follow Antigravity
          semantics. Never claim exact internal feature parity from this mapping.

          Every shared skill directory is discovered from Flint's skills source;
          Antigravity keeps its native /grill-me. Every shared command prompt is
          imported intact with argument-binding instructions. A collision with a
          skill, workflow, or native name is exposed as /prompt-<name> instead.
        '';
      }
      // lib.mapAttrs' (name: _:
        lib.nameValuePair ".gemini/config/skills/${name}" {
          source = ./skills + "/${name}";
          recursive = true;
          force = true;
        })
      sharedSkills
      // lib.mapAttrs' (name: workflow:
        lib.nameValuePair ".gemini/config/skills/${name}/SKILL.md" {
          text = ''
            ---
            name: ${name}
            description: ${builtins.toJSON workflow.description}
            ---

            ${workflow.prompt}
          '';
        })
      workflows
      // lib.concatMapAttrs (file: _: let
        name = lib.removeSuffix ".md" file;
        command =
          if builtins.hasAttr name sharedSkills || builtins.hasAttr name workflows || builtins.elem name catalog.native
          then "prompt-${name}"
          else name;
      in {
        ".gemini/config/skills/${command}/SKILL.md".text = ''
          ---
          name: ${command}
          description: ${builtins.toJSON "Run the shared /${name} command workflow with the user's supplied arguments."}
          ---

          Read [the original command prompt](prompt.md) and follow it. Resolve named
          skills from the installed catalog and read their SKILL.md before using them.
          Bind $ARGUMENTS to the text supplied after /${command}, $1, $2, etc. to its
          positional arguments, and $@[N] to arguments N onward. These placeholders
          describe user input; do not pass them literally to a shell or treat input
          as shell code. Ask only for arguments the workflow actually requires.
        '';
        ".gemini/config/skills/${command}/prompt.md".source = ./commands + "/${file}";
      })
      sharedCommands;

    home.activation.syncCodexSkills = lib.hm.dag.entryAfter ["writeBoundary"] ''
      $DRY_RUN_CMD mkdir -p "$HOME/.codex/skills"
      for skill_dir in ${./skills}/*; do
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
