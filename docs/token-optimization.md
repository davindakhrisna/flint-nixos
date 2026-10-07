# Maximal Coding Tools

`dev = "maximal"` includes RTK, Headroom, Graphify, and 9Router.

- RTK filters noisy shell output before it enters the conversation.
- Headroom runs as a local stdio MCP server with compression, retrieval, and stats tools.
- Codex and Antigravity CLI use RTK for every supported noisy command and Headroom for every large, eligible input.

The profile does not run `headroom wrap codex`, start or probe a proxy, change an OpenAI endpoint, or read Codex authentication files. Headroom's upload beacon and RTK telemetry are disabled. Home Manager registers Headroom through `codex mcp` and `agy mcp`. Codex's global `AGENTS.md`, Antigravity's `~/.gemini/config/AGENTS.md`, and Oh My Pi's global `RULES.md` enforce Graphify use when the current directory has `graphify-out/graph.json`; otherwise, the agents ask before initializing it. 9Router is installed as a separate CLI and does not change agent providers or credentials.

Antigravity's global rules also require completing authorized work, preserving unrelated edits, meaningful verification, and reading relevant provisioned skills before applying them. The six skills managed in `modules/home/dev/_skills.nix` remain available under `~/.gemini/config/skills`; the maximal profile adds `token-optimizer`. These paths follow Antigravity's [global rules](https://www.antigravity.google/docs/rules/) and [MCP configuration](https://www.antigravity.google/docs/mcp) conventions.

## Apply

```bash
nh os switch
```

Restart Codex and Antigravity CLI, then verify:

```bash
rtk --version
headroom --version
codex mcp get headroom --json
agy mcp list
graphify --help
9router --help
```

## Graphify

If `./graphify-out/graph.json` exists, Codex, Antigravity CLI, and Oh My Pi use `graphify query "where is authentication handled?"` before source inspection and `graphify update .` after relevant code changes. If it does not exist, they ask you whether to initialize it; only after your approval do they run `graphify extract . --code-only`. Graphify's code extractor does not cover this Nix-heavy repository, so use ordinary file search here. Restart the agents after switching profiles to load the new rules.

The current lock provides RTK 0.47.0. Headroom 0.39.1 is built from pinned upstream source and Cargo dependencies in `modules/system/packages/_headroom.nix`. Switching to `dev = "minimal"` removes each managed MCP entry only when it still matches Flint's managed command. The next switch also removes Serena's MCP entry and `uv` tool installation.

Use raw commands when exact output matters. Headroom MCP has per-call context overhead, so reserve it for large inputs and retrieve the original when compressed detail is insufficient.

Sources: [RTK](https://github.com/rtk-ai/rtk), [Headroom MCP](https://github.com/headroomlabs-ai/headroom/blob/main/docs/content/docs/mcp.mdx), [Graphify](https://github.com/Graphify-Labs/graphify), [Oh My Pi rules](https://github.com/can1357/oh-my-pi/blob/main/docs/context-files.md).
