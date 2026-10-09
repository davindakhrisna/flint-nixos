# Medium and Heavy Coding Tools

`dev = "medium"` and `dev = "heavy"` include RTK, Headroom, Graphify, and 9Router.

- RTK filters noisy shell output before it enters the conversation.
- Headroom runs as a local stdio MCP server with compression, retrieval, and stats tools.
- Codex, OMP, and Antigravity CLI use RTK for every supported noisy command and Headroom for every large, eligible input.

The profile does not run `headroom wrap codex`, start or probe a proxy, change an OpenAI endpoint, or read Codex authentication files. Headroom's upload beacon and RTK telemetry are disabled. Home Manager registers Headroom through `codex mcp`, plus native JSON configuration for Antigravity and OMP. The JSON registration merges only the managed Headroom entry, preserves other servers/settings, and does not depend on the CLI installer finishing first. Codex's global `AGENTS.md`, Antigravity's `~/.gemini/config/AGENTS.md`, and Oh My Pi's global `RULES.md` enforce Graphify use when the current directory has `graphify-out/graph.json`; Antigravity initializes a missing graph once per coding session using the user-authorized `graphify extract . --code-only`, while Codex and OMP ask before initializing it. 9Router is installed as a separate CLI and does not change agent providers or credentials.

Antigravity's global rules require completing authorized work, planning substantial tasks, preserving unrelated edits, checking callers, and meaningful verification. It automatically matches skill descriptions before acting, reads the selected SKILL.md, and announces the selection. Ponytail applies to coding work; design and review skills activate when their scope matches. All shared skill directories are provisioned automatically, except `grill-me`, which Antigravity provides natively. The CLI skill path links to the same tree as `~/.gemini/config/skills`; medium/heavy profiles also provision `token-optimizer` for all three harnesses.

The complete documented Codex slash-command catalog, plus `/handoff`, is mapped in [AI workflows](ai-workflows.md). Native Antigravity controls keep their real behavior; portable prompts become skills. Every shared command file is also imported, with `/prompt-<name>` used when a name is already taken. See Antigravity's [skills](https://www.antigravity.google/docs/skills/) and [MCP](https://www.antigravity.google/docs/mcp) documentation.

All development profiles seed Antigravity's writable `~/.gemini/antigravity-cli/settings.json` with agent-decided artifact review, completion notifications, and disabled tips, feedback surveys, and telemetry. Existing values, selected models, trusted workspaces, and other settings win over these defaults; malformed settings are left untouched. Tool permissions retain Antigravity's normal review behavior. Use `/config`, `/model`, and `/permissions` to adjust them. See the [CLI settings reference](https://www.antigravity.google/docs/cli/reference/#configuration-keys-settingsjson).

OMP receives shared skills/commands, RTK/Headroom/Graphify rules, and native Headroom registration at `~/.omp/agent/mcp.json` for its default profile. Model/provider choices remain local in `~/.omp/agent/config.yml` and `models.yml`. Named OMP profiles have separate MCP configuration and need their own registration. OMP updates are staged and smoke-tested before replacing the executable, so an interrupted download preserves the working installation.

CLI updates start in the background after Home Manager reloads user services. A switch leaves an update already running alone; the next run uses the new updater. Download progress is available with `journalctl --user -u flint-update-ai-tools.service -f`.

## Apply

```bash
nh os switch
```

Restart the harnesses, then verify:

```bash
rtk --version
headroom --version
codex mcp get headroom --json
agy mcp list
# In OMP: /mcp list, then /mcp test headroom
graphify --help
9router --help
```

In a new `agy` session, use `/skills` to check the shared skills and `/codex-workflows` for the full command map, `/mcp` to check Headroom's connection and tools, and `/config` to inspect the seeded defaults. RTK and Graphify are terminal commands governed by the global rules; Headroom is an MCP tool. The setup aligns workflow and tooling, not the underlying models' capabilities.

## Graphify

If `./graphify-out/graph.json` exists, Codex, Antigravity CLI, and Oh My Pi use `graphify query "where is authentication handled?"` before source inspection and `graphify update .` after relevant code changes. If it does not exist, Antigravity runs `graphify extract . --code-only` once for the coding session, including during `/init`; the user has authorized this initialization. Codex and OMP still ask first. Failed or unsupported extraction falls back to normal source search, with no repeated attempts in the same session. Graphify's code extractor does not cover this Nix-heavy repository, so use ordinary file search here. Restart the agents after switching profiles to load the new rules.

The current lock provides RTK 0.47.0. Headroom 0.39.1 is built from pinned upstream source and Cargo dependencies in `modules/system/packages/_headroom.nix`. Switching to `dev = "light"` removes each managed MCP entry only when its command and arguments still match Flint's registration. Invalid native JSON configs are left untouched, and activation reports the failure. The next switch also removes Serena's MCP entry and `uv` tool installation.

Use raw commands when exact output matters. Headroom MCP has per-call context overhead, so reserve it for large inputs and retrieve the original when compressed detail is insufficient.

Sources: [RTK](https://github.com/rtk-ai/rtk), [Headroom MCP](https://github.com/headroomlabs-ai/headroom/blob/main/docs/content/docs/mcp.mdx), [Graphify](https://github.com/Graphify-Labs/graphify), [Oh My Pi rules](https://github.com/can1357/oh-my-pi/blob/main/docs/context-files.md).
