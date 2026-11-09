#!/usr/bin/env bash
set -euo pipefail

repo_url="https://github.com/davindakhrisna/xinu-nixos"
docs_dir="$HOME/Documents"
target_dir="$docs_dir/Xinu"

mkdir -p "$docs_dir"

if [[ ! -d "$target_dir" ]]; then
	git clone "$repo_url" "$target_dir"
fi

cd "$target_dir"

nix-shell -I nixpkgs=flake:nixpkgs --run '
set -euo pipefail
if [[ ! -f xinu-vbox/tftpboot/xinu.boot ]]; then
	make -C xinu-vbox/compile
fi
install -d -m 755 /var/tmp/xinu-tftp
install -m 644 xinu-vbox/tftpboot/xinu.boot /var/tmp/xinu-tftp/xinu.boot
if ! virsh -c qemu:///system net-info xinu_net >/dev/null 2>&1; then
	virsh -c qemu:///system net-define xinu_net.xml || true
fi
if ! virsh -c qemu:///system dominfo backend >/dev/null 2>&1; then
	virsh -c qemu:///system define backend.xml || true
fi
virsh -c qemu:///system net-autostart xinu_net --disable >/dev/null 2>&1 || true
virsh -c qemu:///system autostart backend --disable >/dev/null 2>&1 || true
'
