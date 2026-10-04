#!/usr/bin/env bash
set -euo pipefail

[[ $# == 1 ]] || { echo "Usage: flint-hermes-codex PROJECT_DIR < task" >&2; exit 2; }
project=$(realpath -e -- "$1")
[[ -d "$project" && "$project" == "$FLINT_HERMES_WORKSPACE"/* ]] || {
  echo "Project must be inside the Hermes workspace" >&2; exit 2;
}
unset OPENAI_API_KEY OPENAI_BASE_URL CUSTOM_BASE_URL OPENAI_MODEL
exec /home/kryisnn/.local/bin/codex exec --sandbox workspace-write --cd "$project" --skip-git-repo-check -
