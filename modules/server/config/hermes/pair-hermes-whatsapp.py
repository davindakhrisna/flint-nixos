"""Pair the Nix-managed WhatsApp bridge without rewriting managed configuration."""
import os
import subprocess

from hermes_cli.env_loader import load_hermes_dotenv
from hermes_cli.main_platform_setup import _whatsapp_install_bridge
from hermes_constants import find_node_executable, get_hermes_dir, with_hermes_node_path
from gateway.platforms.whatsapp_common import resolve_whatsapp_bridge_dir

load_hermes_dotenv()
if os.getuid() == 0:
    raise SystemExit("Run as the Hermes account: sudo -u hermes -H flint-hermes-whatsapp-pair")
bridge = resolve_whatsapp_bridge_dir()
if not (bridge / "bridge.js").is_file():
    raise SystemExit("WhatsApp bridge is missing; switch to the updated NixOS configuration first.")
if not _whatsapp_install_bridge(bridge):
    raise SystemExit("WhatsApp bridge dependency installation failed.")
session = get_hermes_dir("platforms/whatsapp/session", "whatsapp/session")
session.mkdir(parents=True, exist_ok=True)
subprocess.run(
    [find_node_executable("node"), str(bridge / "bridge.js"), "--pair-only", "--session", str(session)],
    cwd=bridge,
    env=with_hermes_node_path(),
    check=True,
)
if not (session / "creds.json").is_file():
    raise SystemExit("Pairing did not finish; run the pairing command again.")
print("Paired. Set WHATSAPP_ENABLED=true in scripts/server/.secrets.env, then run scripts/server/provision-secrets.sh --hermes-only.")
