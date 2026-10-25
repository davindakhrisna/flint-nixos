# TIGHTSPEC — Execution & Verification Protocol

## 1. Scope & Diff Discipline

- Implement ONLY what is requested. Do not perform drive-by refactors, rename unrelated symbols, or introduce speculative abstractions.
- State assumptions explicitly in 1-3 lines before editing when requirements are ambiguous.
- Preserve existing module boundaries, formatting conventions, and `direnv` / Nix flake environments. Never install global runtimes imperatively.

## 2. Zero-Suppression Law (Enforced by `agent-pre-guard`)

- NEVER add linter or type suppression directives (`@ts-ignore`, `@ts-expect-error`, `eslint-disable`, `# type: ignore`, `-- selene: allow`, `# statix ignore`).
- NEVER edit or weaken compiler/linter configuration files (`tsconfig.json`, `biome.json`, `.eslintrc`, `.ruff.toml`, `selene.toml`, `statix.toml`).
- Resolve diagnostics by fixing the underlying types, control flow, or unused bindings.

## 3. Deterministic Post-Edit Verification (Enforced by `agent-post-verify`)

Every file write or patch automatically runs single-file formatters and linters:

- **TS / JS / Svelte / JSON**: `biome format` + `biome check`
- **Nix**: `alejandra` + `nix-instantiate --parse` + `statix check` + `deadnix --fail`
- **Python**: `ruff format` + `ruff check`
- **Lua / Luau**: `stylua` + `selene`
- **Shell**: `shfmt` + `shellcheck`

If a tool call returns `VERIFICATION FAILED`, fix the reported diagnostic in that file immediately before editing any other file.
