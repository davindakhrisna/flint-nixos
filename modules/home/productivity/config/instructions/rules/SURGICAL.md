# SURGICAL — Retrieval & Navigation Protocol

## 1. 150-Line Read Hard Cap (Enforced by `agent-pre-guard`)

- Unbounded reads on files over 150 lines are blocked by `agent-pre-guard`.
- Never read a file from line 1 to EOF unless you have verified its line count is 150 lines or fewer.

## 2. Discovery Hierarchy (Locate Before Reading)

Always narrow down exact file paths and symbol line numbers before reading source text:

1. **Graph & LSP MCPs (`codebase-memory`, `serena`)**: Query symbol definitions, call hierarchies, and LSP references first.
2. **Structural AST Search (`ast-grep` / `sg`, `semgrep`)**: Match syntax trees and perform multi-site structural rewrites deterministically.
3. **Fast Lexical Search (`rg`, `fd`, `universal-ctags`)**: Locate exact line numbers, filenames, or symbol outlines (`ctags -x`).
4. **Repo Skeletons (`repomix --compress`)**: Inspect high-level signatures when mapping unfamiliar modules.

## 3. Targeted Slice Reads

- Once target symbols are located, read only the relevant window by passing explicit `offset` and `limit` parameters (keep slices under 80 lines).
