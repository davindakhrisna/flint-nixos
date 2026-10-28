#!/usr/bin/env bash
set -euo pipefail

repo_url="https://github.com/davindakhrisna/stealth"
docs_dir="$HOME/.config"
target_dir="$docs_dir/stealth"
bin_dir="$HOME/.local/bin"

mkdir -p "$docs_dir" "$bin_dir"

if [[ ! -d "$target_dir" ]]; then
	git clone "$repo_url" "$target_dir"
fi

cd "$target_dir"

nix develop --command cargo build --release
install -m 755 target/release/stealth "$bin_dir/stealth"

if [[ ! -f "$target_dir/.env" ]] && [[ -f "$target_dir/.env.example" ]]; then
	cp "$target_dir/.env.example" "$target_dir/.env"
fi
