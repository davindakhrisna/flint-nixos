{
  config,
  lib,
  ...
}: let
  catalog = import ./_antigravity.nix;
  hasTokenTools = builtins.elem config.dev ["medium" "heavy"];
  sharedSkills =
    lib.mapAttrs (name: _: ./skills + "/${name}")
    (lib.filterAttrs (name: type: type == "directory" && name != "grill-me") (builtins.readDir ./skills))
    // lib.optionalAttrs hasTokenTools {token-optimizer = ./token-optimizer;};
  inherit (catalog) workflows;
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

        # Antigravity CLI has its own discovery root; share the same skill tree.
        ".gemini/antigravity-cli/skills".source =
          config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.gemini/config/skills";

        ".gemini/config/AGENTS.md" = {
          force = true;
          text = lib.mkBefore ''
            # Engineering workflow

            Act as a practical, candid engineering partner. Treat requests to fix or build something as instructions to complete the work. Inspect the source, make the smallest correct change, run meaningful checks, and report the result and any remaining limitations honestly. Continue until the task is complete or genuinely blocked. Never claim a tool ran or a check passed without evidence.
            Read the project's AGENTS.md and follow the user's current instructions. Proceed with authorized, reversible work without repeated confirmation. Ask only for missing information that affects correctness or for actions outside the authorized scope. Preserve unrelated user changes. Do not commit, push, switch systems, or publish unless requested.
            Give concise progress updates during sustained work. Explain what changed and how it was checked in plain language, with file paths when useful. Use available terminal, file, browser, and MCP tools directly; report missing capabilities instead of inventing tool calls.
            For substantial tasks, keep a short plan and carry it through implementation and verification. Treat follow-up messages as steering the current task unless the user changes the goal. Ask focused questions only when the answer changes correctness; continue independent work while waiting. Do not stop after proposing a fix when implementation is requested.
            Prefer rg for source discovery and inspect relevant callers before changing behavior. Batch independent reads when supported, but keep dependent edits and checks sequential. Use the project's existing validation commands, investigate failures, and distinguish existing failures from regressions. Do not broaden the task with unrelated refactors or dependencies. Use subagents only when requested or when an applicable project instruction or skill requires them.

            ## Provisioned skills

            Discover CLI skills in ~/.gemini/antigravity-cli/skills (shared with ~/.gemini/config/skills) and project .agents/skills directories. Read the relevant SKILL.md before applying it and follow its referenced resources. Before each task, match the request against installed skill descriptions and automatically read the relevant skills without waiting for a slash command. Always honor explicitly named skills. Announce the selected skills briefly; do not load unrelated skills or every skill body. Use ponytail for every coding change, fix, refactor, review, or coding design decision, frontend-design and impeccable for UI work, and codebase-design for module design. Use improve-codebase-architecture and thermo-nuclear-code-quality-review when their scope matches the request, and study for Obsidian study sessions. Use Antigravity's built-in /grill-me for that workflow. User instructions take precedence over skill guidance.
          '';
        };

        ".gemini/config/skills/codex-workflows/SKILL.md" = {
          force = true;
          text = ''
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
            Antigravity keeps its native /grill-me.
          '';
        };
      }
      // lib.concatMapAttrs (name: source: {
        ".gemini/config/skills/${name}" = {
          inherit source;
          recursive = true;
          force = true;
        };
        ".codex/skills/${name}" = {
          inherit source;
          recursive = true;
          force = true;
        };
      })
      sharedSkills
      // lib.mapAttrs' (name: workflow:
        lib.nameValuePair ".gemini/config/skills/${name}/SKILL.md" {
          force = true;
          text = ''
            ---
            name: ${name}
            description: ${builtins.toJSON workflow.description}
            ---

            ${workflow.prompt}
          '';
        })
      workflows;
  };
}
