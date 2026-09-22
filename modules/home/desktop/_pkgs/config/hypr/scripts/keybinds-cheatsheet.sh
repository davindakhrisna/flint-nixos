#!/usr/bin/env bash
# =============================================================================
# Hyprland Keybindings Cheatsheet (Dynamic, Read-Only, Minimalist Rofi Menu)
# =============================================================================

KEYBINDS_FILE="${HOME}/.config/hypr/modules/keybinds.lua"

if [ ! -f "$KEYBINDS_FILE" ]; then
    notify-send "Cheatsheet" "Keybindings file not found: $KEYBINDS_FILE"
    exit 1
fi

# Locate Lua binary across PATH, user profile, system profile, or nix store
LUA_BIN=""
if command -v lua >/dev/null 2>&1; then
    LUA_BIN="$(command -v lua)"
elif [ -x "/etc/profiles/per-user/${USER:-kryisnn}/bin/lua" ]; then
    LUA_BIN="/etc/profiles/per-user/${USER:-kryisnn}/bin/lua"
elif [ -x "/run/current-system/sw/bin/lua" ]; then
    LUA_BIN="/run/current-system/sw/bin/lua"
else
    for candidate in /nix/store/*-lua-*/bin/lua; do
        if [ -x "$candidate" ]; then
            LUA_BIN="$candidate"
            break
        fi
    done
fi

parse_lua() {
    [ -z "$LUA_BIN" ] && return 1
    "$LUA_BIN" - "$KEYBINDS_FILE" << 'LUA_EOF'
local keybinds_file = arg[1]

local function make_mock()
  return setmetatable({}, {
    __index = function(t, k)
      t[k] = make_mock()
      return t[k]
    end,
    __call = function() return function() end end
  })
end

local binds = {}
local hl = {
  bind = function(combo, handler, opts)
    local desc = (opts and (opts.desc or opts.description or opts.name)) or ""
    table.insert(binds, { combo = combo, desc = desc })
  end,
  dsp = make_mock(),
  get_active_window = function() return { floating = false } end,
  dispatch = function() end,
}
_G.hl = hl

local chunk, err = loadfile(keybinds_file)
if not chunk then
  os.exit(1)
end
chunk()

for _, b in ipairs(binds) do
  if b.desc and b.desc ~= "" then
    print(string.format("%-28s %s", b.combo, b.desc))
  else
    print(b.combo)
  end
end
LUA_EOF
}

parse_fallback() {
    local in_loop=0
    while IFS= read -r line || [ -n "$line" ]; do
        if [[ "$line" =~ for[[:space:]]+i[[:space:]]*=[[:space:]]*1,[[:space:]]*10 ]]; then
            in_loop=1
            continue
        fi
        if [ "$in_loop" -eq 1 ] && [[ "$line" =~ ^[[:space:]]*end ]]; then
            in_loop=0
            continue
        fi
        if [ "$in_loop" -eq 1 ] && [[ "$line" =~ hl\.bind ]]; then
            local is_shift=0
            [[ "$line" =~ SHIFT ]] && is_shift=1
            for i in {1..10}; do
                local k=$((i % 10))
                if [ "$is_shift" -eq 1 ]; then
                    printf "%-28s %s\n" "SUPER + SHIFT + $k" "Move to Workspace $k"
                else
                    printf "%-28s %s\n" "SUPER + $k" "Focus Workspace $k"
                fi
            done
            continue
        fi
        if [[ "$line" =~ hl\.bind ]]; then
            local desc=""
            if [[ "$line" =~ desc[[:space:]]*=[[:space:]]*\"([^\"]+)\" ]]; then
                desc="${BASH_REMATCH[1]}"
            fi
            local combo=""
            if [[ "$line" =~ hl\.bind\(([^,]+), ]]; then
                combo="${BASH_REMATCH[1]}"
                combo="${combo//mainMod/SUPER}"
                combo="${combo//\"/}"
                combo="${combo//\'/}"
                combo="${combo// \.\. /}"
                combo="${combo//\.\./}"
                combo="$(echo "$combo" | xargs)"
            fi
            if [ -n "$combo" ]; then
                if [ -n "$desc" ]; then
                    printf "%-28s %s\n" "$combo" "$desc"
                else
                    echo "$combo"
                fi
            fi
        fi
    done < "$KEYBINDS_FILE"
}

BINDS=$(parse_lua 2>/dev/null)
if [ -z "$BINDS" ]; then
    BINDS=$(parse_fallback)
fi

if [ -z "$BINDS" ]; then
    notify-send "Cheatsheet" "No keybindings parsed."
    exit 1
fi

# Display in Rofi (searchable, clean typography, read-only)
echo "$BINDS" | rofi -dmenu -i -p "Keybinds" \
    -theme-str 'window {width: 680px; border-radius: 0px;} listview {lines: 16;}'
