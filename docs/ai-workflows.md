# Coding harness workflows

Antigravity is configured for the full **53-command documented Codex CLI catalog** as checked on 2026-10-09, plus `/handoff` and the `/clean` alias. This is a workflow mapping: model internals, authentication, session databases, permissions, and product-only features cannot be transplanted by prompts.

The source of truth is `modules/home/dev/config/_antigravity-commands.nix`. `/codex-workflows` exposes this map inside Antigravity. The catalog was compared with the [official Codex command reference](https://learn.chatgpt.com/docs/developer-commands?surface=cli) and [Antigravity's CLI reference](https://www.antigravity.google/docs/cli/reference/).

## Native commands

These use Antigravity's existing controls, with Antigravity's semantics:

`/permissions`, `/plugins`, `/hooks`, `/clear`, `/rename`, `/copy`, `/diff`, `/exit`, `/skills`, `/feedback`, `/logout`, `/mcp`, `/model`, `/fast`, `/plan`, `/goal`, `/fork`, `/btw`, `/resume`, `/new`, `/quit`, `/usage`, `/statusline`, `/title`.

For example, Antigravity `/fast` is an execution-mode control, not Codex's Fast service tier; account usage and goal controls also belong to the active harness. No prompt claims to operate another harness's controls.

## Portable prompt workflows

| Command | Behavior |
| --- | --- |
| `/compact` | Prepare a portable context checkpoint for /compact when moving to a fresh Antigravity chat. |
| `/debug-config` | Diagnose Antigravity rules, skills, settings and MCP discovery for /debug-config. |
| `/handoff` | Create or consume a portable work handoff across Codex, Claude Code, OMP, and Antigravity; use for /handoff or continuing from a supplied handoff. |
| `/import` | Adapt explicitly selected prompts, skills or handoffs from another coding harness for /import. |
| `/init` | Initialize repository instructions and Graphify for a new coding session; use for /init or a request to initialize the workspace. |
| `/mention` | Read user-named files into the current task context for /mention. |
| `/personality` | Apply a requested communication style within this chat for /personality. |
| `/review` | Review a working tree, commit, or branch for actionable regressions; use for /review or an ordinary code review request. |
| `/status` | Summarize the current workspace and task status for /status. |

`/init` initializes Graphify if absent and creates or carefully updates project `AGENTS.md` from actual source/build evidence. Existing instructions are preserved. Graphify initialization is already authorized for Antigravity coding sessions; failed or unsupported extraction falls back to normal search without repeated retries.

`/handoff` writes `HANDOFF.md` (or your chosen path) with the task, constraints, decisions, changed files, test outcomes, Graphify status, and next action. It also consumes supplied handoffs from Codex, Claude Code, or OMP. `/compact` uses this checkpoint workflow and tells you to use `/clear` or `/new`; it cannot itself remove context messages.

## Compatibility commands

These names are available as skills. They explain the real native equivalent or an explicit limitation, rather than claiming an unsupported operation succeeded.

| Codex command | Antigravity mapping |
| --- | --- |
| `/agent` | Use native /agents to select or inspect agents. Do not spawn agents just to open this control. |
| `/app` | Use Antigravity's native surfaces or a handoff to continue elsewhere. A prompt cannot open the current Codex chat in the ChatGPT desktop app or migrate its session ID. |
| `/approve` | Use Antigravity's native approval prompt or /permissions to review the denied action. A prompt is not an approval grant; do not bypass or weaken controls. |
| `/apps` | Use native /plugin for Antigravity integrations and /mcp for external tools. Codex app accounts and connectors do not transfer with prompts. |
| `/archive` | There is no verified Codex-style archive operation exposed here. Use /rename to label the session and /resume to find it later. Do not edit session databases or claim it was archived. |
| `/clean` | Codex's /clean aliases /stop. In Antigravity use /tasks to stop selected tasks. This command does not delete files. |
| `/delete` | A portable prompt cannot implement Codex's session deletion. Check this Antigravity version's native session controls; do not delete transcripts or session databases to emulate it. |
| `/experimental` | Use native /config for settings supported by this installed Antigravity version. Codex feature flags do not configure Antigravity. |
| `/ide` | Use @path to supply files or paste the relevant editor selection. CLI prompts cannot import Codex IDE connection state; use Antigravity's native editor integration for live context. |
| `/keymap` | Use native /keybindings to inspect and change terminal shortcuts. |
| `/memories` | Use native /learn for durable lessons, or explicitly edit project AGENTS.md for persistent instructions. Codex's memory database and its enablement toggles do not transfer. |
| `/pet` | Codex /pet aliases /pets; this product feature cannot be injected into Antigravity with a skill. |
| `/pets` | Codex terminal pets are a product feature, not a portable prompt workflow. Do not install or activate a pet or fabricate support in Antigravity. |
| `/ps` | Use native /tasks to inspect this session's background tasks. Do not enumerate unrelated user processes. |
| `/raw` | Use /config to inspect altScreenMode and verbosity for terminal presentation. These are approximations; do not claim to enable Codex raw-scrollback mode. |
| `/sandbox-add-read-dir` | Codex's Windows read-directory grant is not portable. Use native /add-dir for workspace scope and /permissions for access; adding workspace context is not itself a permission grant. |
| `/setup-default-sandbox` | This is a Codex Windows-only setup command. On this NixOS system inspect native /permissions and terminal-sandbox settings; no Windows sandbox setup is applicable. |
| `/side` | Use native /btw followed by the question for a side question while the main task continues. |
| `/stop` | Use native /tasks to stop the selected session tasks, or Esc to interrupt generation. Do not kill unrelated processes or claim that this prompt stops the execution loop. |
| `/subagents` | Use native /agents to inspect existing agents; creating new agents requires the user's task to authorize delegation. |
| `/theme` | Use native /config and colorScheme to choose an Antigravity theme; Codex theme identifiers do not transfer. |
| `/vim` | Use native /config and the editorMode setting (vim or default). Do not claim to toggle the live composer from a prompt. |

## Shared prompts and automatic skills

All directories under `modules/home/dev/config/skills/` are discovered at evaluation time; Antigravity uses native `/grill-me` instead of duplicating it. All Markdown prompts under `modules/home/dev/config/commands/` are imported intact, with positional and `$ARGUMENTS` binding explained to the model. Names colliding with a native command or skill are prefixed with `prompt-`:

| Shared command | Antigravity command |
| --- | --- |
| `study.md` | `/prompt-study` (the full skill is also `/study`) |
| `improve-codebase-architecture.md` | `/prompt-improve-codebase-architecture` (the full skill keeps its name) |
| `thermo-nuclear.md` | `/thermo-nuclear` |

Global rules require choosing relevant skills without waiting for explicit commands: ponytail for coding, frontend-design/impeccable for UI, codebase-design for module design, study for Obsidian, and the review skills when their specific scope applies. Review skills are model-invocable. Explicit requests take precedence; irrelevant skills are not loaded. Selection remains model-driven, so `/skills` confirms availability, not guaranteed compliance on every turn.

Apply with `nh os switch`, then start a new `agy` session. `/skills`, `/codex-workflows`, `/config`, and `/mcp` show the resulting setup. In OMP, `/mcp test headroom` checks the native connection. Shared profile changes are validated with `./scripts/check.sh`.
