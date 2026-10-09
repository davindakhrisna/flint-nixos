# Codex CLI catalog: https://learn.chatgpt.com/docs/developer-commands?surface=cli
# Native commands keep their real UI/session behavior. Other entries become skills.
{
  native = [
    "permissions"
    "plugins"
    "hooks"
    "clear"
    "rename"
    "copy"
    "diff"
    "exit"
    "skills"
    "feedback"
    "logout"
    "mcp"
    "model"
    "fast"
    "plan"
    "goal"
    "fork"
    "btw"
    "resume"
    "new"
    "quit"
    "usage"
    "statusline"
    "title"
  ];

  workflows = {
    init = {
      description = "Initialize repository instructions and Graphify for a new coding session; use for /init or a request to initialize the workspace.";
      prompt = ''
        Inspect the current workspace and any existing AGENTS.md before changing it.
        Check ./graphify-out/graph.json first. If absent, the user has authorized
        running graphify extract . --code-only for this workspace; do not ask again.
        If present, query it to locate relevant source paths, then verify against source.
        If extraction fails or does not cover the repository language, report the
        limitation once and continue with rg. Do not retry initialization every turn.
        Inspect actual build manifests, scripts, source layout, and existing guidance.
        Create or minimally update AGENTS.md with verified structure, commands,
        conventions, and validation instructions. Preserve existing user instructions.
        Do not overwrite it with a generic template or invent test commands. Check the
        diff and report initialization status, usable checks, and applicable skills.
      '';
    };
    handoff = {
      description = "Create or consume a portable work handoff across Codex, Claude Code, OMP, and Antigravity; use for /handoff or continuing from a supplied handoff.";
      prompt = ''
        If the user supplies a handoff, read it, verify its paths and working-tree
        claims against the current workspace, and continue the outstanding task.
        Otherwise write a concise handoff to the user-specified path, or HANDOFF.md
        in the workspace. Preserve unrelated existing content; update an existing
        task handoff only when it describes this same task.
        Include the objective, user constraints and authorization, active skills,
        decisions and reasons, changed files, checks run and exact outcomes,
        failures/blockers, remaining work, and the next concrete action. Include
        Graphify status and whether initialization was already attempted. Distinguish
        facts from assumptions. Exclude secrets and authentication/session databases.
        End with a ready-to-paste continuation prompt referencing the handoff path.
        This transfers documented context, not hidden history, model state, or tool
        permissions. Do not claim to switch, resume, or compact another harness.
      '';
    };
    review = {
      description = "Review a working tree, commit, or branch for actionable regressions; use for /review or an ordinary code review request.";
      prompt = ''
        Follow the requested review target. Without one, review staged, unstaged,
        and relevant untracked changes. Check repository instructions and git status,
        inspect the diff and surrounding callers, and verify suspected regressions.
        Prioritize correctness, security, data loss, and missing behavioral coverage.
        Report only actionable findings with severity, file/line, triggering scenario,
        and consequence. Avoid speculative findings, style-only feedback, or repeating
        findings already fixed. State checks and residual gaps; if there are no
        findings, say so. Do not modify the implementation unless asked to fix it.
        Use ponytail; use specialized review skills only when their scope matches.
      '';
    };
    compact = {
      description = "Prepare a portable context checkpoint for /compact when moving to a fresh Antigravity chat.";
      prompt = ''
        Use the handoff skill to save a concise checkpoint of the current task.
        Explain that a prompt skill cannot remove messages from the current context.
        Give the user the exact continuation prompt to use after native /clear or
        /new. Do not clear the chat yourself or claim context tokens were freed.
      '';
    };
    status = {
      description = "Summarize the current workspace and task status for /status.";
      prompt = ''
        Report the workspace, branch and working-tree status, current objective,
        progress, active skills, Graphify status, last checks and blockers. Report
        model, permissions, and context usage only when exposed by this session;
        otherwise point to /model, /permissions, /context, and /usage. Never infer
        live token usage or permissions from stale settings.
      '';
    };
    personality = {
      description = "Apply a requested communication style within this chat for /personality.";
      prompt = ''
        Apply the supplied style for this conversation: friendly, pragmatic, none,
        or the user's own wording. With no style, ask which they prefer. This changes
        response style only; do not edit global rules or change task permissions.
      '';
    };
    mention = {
      description = "Read user-named files into the current task context for /mention.";
      prompt = ''
        Resolve the supplied paths in the current workspace and read relevant content.
        Ask for the path if missing. Do not scan credentials or unrelated home files.
        Use native @path completion for UI attachment; reading a file does not create
        an attachment chip. Continue the user's associated request if supplied.
      '';
    };
    "debug-config" = {
      description = "Diagnose Antigravity rules, skills, settings and MCP discovery for /debug-config.";
      prompt = ''
        Inspect relevant workspace .agents configuration and global .gemini/config
        rules, skills, and MCP configuration, plus CLI settings. Use /config, /skills,
        /hooks, and /mcp for live state. Report conflicting settings, shadowed names,
        broken links, invalid JSON/frontmatter, and missing executables. Never print
        secret env values, authorization headers, tokens, or credential files.
        Diagnose first; modify configuration only within the user's requested scope.
      '';
    };
    import = {
      description = "Adapt explicitly selected prompts, skills or handoffs from another coding harness for /import.";
      prompt = ''
        Inventory the user-selected source directory and existing target customizations.
        Convert portable prompts into Antigravity skills while preserving descriptions,
        argument intent, and referenced resources. Prefer Flint's managed shared files
        when working in this configuration. Reuse native command equivalents; explain
        unsupported session/UI features. Do not copy authentication, provider endpoints,
        private session databases, or tool permissions. For a supplied conversation
        summary use handoff; do not pretend to import hidden chat state. Ask for a
        source path if the user has not identified the collection.
      '';
    };
  };

  # These aliases guide the user to native controls; they never fake UI actions.
  redirects = {
    agent = "Use native /agents to select or inspect agents. Do not spawn agents just to open this control.";
    subagents = "Use native /agents to inspect existing agents; creating new agents requires the user's task to authorize delegation.";
    apps = "Use native /plugin for Antigravity integrations and /mcp for external tools. Codex app accounts and connectors do not transfer with prompts.";
    keymap = "Use native /keybindings to inspect and change terminal shortcuts.";
    vim = "Use native /config and the editorMode setting (vim or default). Do not claim to toggle the live composer from a prompt.";
    theme = "Use native /config and colorScheme to choose an Antigravity theme; Codex theme identifiers do not transfer.";
    ps = "Use native /tasks to inspect this session's background tasks. Do not enumerate unrelated user processes.";
    stop = "Use native /tasks to stop the selected session tasks, or Esc to interrupt generation. Do not kill unrelated processes or claim that this prompt stops the execution loop.";
    clean = "Codex's /clean aliases /stop. In Antigravity use /tasks to stop selected tasks. This command does not delete files.";
    side = "Use native /btw followed by the question for a side question while the main task continues.";
    experimental = "Use native /config for settings supported by this installed Antigravity version. Codex feature flags do not configure Antigravity.";
    memories = "Use native /learn for durable lessons, or explicitly edit project AGENTS.md for persistent instructions. Codex's memory database and its enablement toggles do not transfer.";
    raw = "Use /config to inspect altScreenMode and verbosity for terminal presentation. These are approximations; do not claim to enable Codex raw-scrollback mode.";
    ide = "Use @path to supply files or paste the relevant editor selection. CLI prompts cannot import Codex IDE connection state; use Antigravity's native editor integration for live context.";
    app = "Use Antigravity's native surfaces or a handoff to continue elsewhere. A prompt cannot open the current Codex chat in the ChatGPT desktop app or migrate its session ID.";
    archive = "There is no verified Codex-style archive operation exposed here. Use /rename to label the session and /resume to find it later. Do not edit session databases or claim it was archived.";
    delete = "A portable prompt cannot implement Codex's session deletion. Check this Antigravity version's native session controls; do not delete transcripts or session databases to emulate it.";
    approve = "Use Antigravity's native approval prompt or /permissions to review the denied action. A prompt is not an approval grant; do not bypass or weaken controls.";
    "setup-default-sandbox" = "This is a Codex Windows-only setup command. On this NixOS system inspect native /permissions and terminal-sandbox settings; no Windows sandbox setup is applicable.";
    "sandbox-add-read-dir" = "Codex's Windows read-directory grant is not portable. Use native /add-dir for workspace scope and /permissions for access; adding workspace context is not itself a permission grant.";
    pets = "Codex terminal pets are a product feature, not a portable prompt workflow. Do not install or activate a pet or fabricate support in Antigravity.";
    pet = "Codex /pet aliases /pets; this product feature cannot be injected into Antigravity with a skill.";
  };
}
