---
name: token-optimizer
description: Reduce large coding-session tool outputs with RTK or Headroom while preserving exact data when correctness requires it.
---

# Token optimizer

Apply these rules to every eligible tool output. Use compression when the avoided output is larger than its setup and tool-call overhead.

- Always use `rtk` for supported noisy shell commands such as Git history and diffs, test output, builds, linters, logs, directory listings, and broad searches.
- Run the original command when exact byte-for-byte output, complete diagnostics, ordering, or an unsupported flag matters. Use `rtk run <command>` when RTK itself should execute without filtering.
- Always use Headroom's `headroom_compress` MCP tool for large, eligible text or structured data already available in the conversation and retain its returned hash. Call `headroom_retrieve` when omitted detail becomes necessary.
- Do not use Headroom for short input, dense prose, exact source patches, secrets, credentials, or security-sensitive evidence.
- Do not proxy Codex traffic: never run `headroom wrap codex`, start a Headroom proxy for Codex, change an OpenAI base URL, or access Codex authentication files.
- Treat reported savings as estimates. Prefer correctness over compression and mention material omissions when summarizing results.
