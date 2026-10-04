"""Check the deployed stack; inference is opt-in because it uses model quota."""
import argparse
import base64
import json
import subprocess
import urllib.request

import yaml

from dotenv import dotenv_values
from hermes_constants import get_hermes_home

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--inference", action="store_true", help="Send one short request to each combo")
args = parser.parse_args()
home = get_hermes_home()
env = dotenv_values(home / ".env")
failed = []


def check(name, action):
    try:
        action()
        print(f"PASS: {name}")
    except Exception as exc:
        failed.append(name)
        # Never print request headers, response bodies, or exception credentials.
        print(f"FAIL: {name} ({type(exc).__name__})")


def request(url, headers=None, data=None):
    req = urllib.request.Request(url, headers=headers or {}, data=data)
    with urllib.request.urlopen(req, timeout=90 if data else 15) as response:
        return response.read()


for unit in ("9router", "hermes-agent", "hermes-backend", "hermes-desktop", "searx"):
    check(f"{unit} active", lambda unit=unit: subprocess.run(
        ["systemctl", "is-active", "--quiet", unit], check=True
    ))

check("9Router WebUI", lambda: request("http://127.0.0.1:20128/dashboard"))
check("SearXNG configuration", lambda: json.loads(request("http://127.0.0.1:9121/config")))
login = f"{env.get('HERMES_DASHBOARD_BASIC_AUTH_USERNAME', '')}:{env.get('HERMES_DASHBOARD_BASIC_AUTH_PASSWORD', '')}"
check("Hermes dashboard", lambda: request("http://127.0.0.1:9120/", {
    "Authorization": "Basic " + base64.b64encode(login.encode()).decode()
}))
headers = {"Authorization": "Bearer " + (env.get("OPENAI_API_KEY") or ""), "Content-Type": "application/json"}


def models():
    available = {model["id"] for model in json.loads(request(
        "http://127.0.0.1:20128/v1/models", headers
    ))["data"]}
    if not {"Casual", "Agentic"} <= available:
        raise ValueError("Required combos missing")


check("authenticated Casual and Agentic model discovery", models)
if args.inference:
    for model in ("Casual", "Agentic"):
        def inference(model=model):
            payload = {"model": model, "messages": [{"role": "user", "content": "Reply only OK."}], "max_tokens": 128, "stream": False}
            result = json.loads(request("http://127.0.0.1:20128/v1/chat/completions", headers, json.dumps(payload).encode()))
            if not result.get("choices") or not result["choices"][0].get("message", {}).get("content"):
                raise ValueError("No model response")
        check(f"{model} inference", inference)
else:
    print("SKIP: inference; run with --inference to use model quota")

if env.get("WHATSAPP_ENABLED", "false").lower() != "true":
    print("PENDING: WhatsApp QR pairing and enabling; no end-to-end message check performed")
else:
    def whatsapp_connection():
        config = yaml.safe_load((home / "config.yaml").read_text())
        whatsapp = config.get("platforms", {}).get("whatsapp", {})
        port = whatsapp.get("extra", {}).get("bridge_port", whatsapp.get("bridge_port", 3000))
        health = json.loads(request(f"http://127.0.0.1:{port}/health"))
        if health.get("status") != "connected":
            raise ValueError("WhatsApp bridge is disconnected")
    check("WhatsApp bridge connected", whatsapp_connection)
    print("PENDING: verify an allowed WhatsApp sender receives a reply and an unlisted sender is rejected")
raise SystemExit(bool(failed))
