from pathlib import Path
import sys

credentials_file = Path(sys.argv[1]) if len(sys.argv) == 3 else Path("/var/lib/secrets/qbittorrent-webui")
config_file = Path(sys.argv[2]) if len(sys.argv) == 3 else Path("/var/lib/qBittorrent/qBittorrent/config/qBittorrent.conf")
if not credentials_file.is_file() or not config_file.is_file():
    raise SystemExit(0)

credentials = dict(
    line.split("=", 1)
    for line in credentials_file.read_text().splitlines()
    if "=" in line
)
updates = {
    key: credentials[key]
    for key in (r"WebUI\Username", r"WebUI\Password_PBKDF2")
    if credentials.get(key)
}
if len(updates) != 2:
    raise SystemExit(0)

lines = config_file.read_text().splitlines(keepends=True)
output = []
in_preferences = False
found_preferences = False
seen = set()

for line in lines:
    if line.strip().startswith("[") and line.strip().endswith("]"):
        if in_preferences:
            if output and not output[-1].endswith("\n"):
                output[-1] += "\n"
            output.extend(f"{key}={value}\n" for key, value in updates.items() if key not in seen)
        in_preferences = line.strip() == "[Preferences]"
        found_preferences |= in_preferences
        seen.clear()
    if in_preferences and "=" in line:
        key = line.split("=", 1)[0]
        if key in updates:
            output.append(f"{key}={updates[key]}\n")
            seen.add(key)
            continue
    output.append(line)

if not found_preferences:
    if output and not output[-1].endswith("\n"):
        output[-1] += "\n"
    output.append("\n[Preferences]\n")
if in_preferences or not found_preferences:
    if output and not output[-1].endswith("\n"):
        output[-1] += "\n"
    output.extend(f"{key}={value}\n" for key, value in updates.items() if key not in seen)

config_file.write_text("".join(output))
