#!/usr/bin/env bash
# open-niri-config.sh
# Rofi/wofi picker to edit individual niri config modules.
# Place this anywhere on your PATH, e.g. ~/.local/bin/open-niri-config.sh

CONFIG_DIR="$HOME/.config/niri"

# ── Module map: display label → filename ─────────────────────────────────────
declare -A CONFIG_MAP=(
    ["󰒓 Main (config.kdl)"]="config.kdl"
    ["󰌿 Input"]="input.kdl"
    ["󰍹 Monitors"]="outputs.kdl"
    ["󰔎 Layout"]="layout.kdl"
    ["󰖲 Window Rules"]="rules.kdl"
    ["󰌌 Keybinds"]="binds.kdl"
    ["󰄉 Autostart"]="autostart.kdl"
)

# ── Ordered list of keys ──────────────────────────────────────────────────────
CONFIG_ORDER=(
    "󰒓 Main (config.kdl)"
    "󰌿 Input"
    "󰍹 Monitors"
    "󰔎 Layout"
    "󰖲 Window Rules"
    "󰌌 Keybinds"
    "󰄉 Autostart"
)

# ── Build menu in declared order ──────────────────────────────────────────────
options=$(printf '%s\n' "${CONFIG_ORDER[@]}")

# ── Prompt with rofi or wofi ──────────────────────────────────────────────────
if command -v rofi >/dev/null 2>&1; then
    choice=$(echo -e "$options" | rofi \
        -dmenu \
        -i \
        -p "󱂬 Niri Config" \
        -font "JetBrainsMono Nerd Font 10" \
        -sort \
        -disable-history)
elif command -v wofi >/dev/null 2>&1; then
    choice=$(echo -e "$options" | wofi --dmenu -i -p "Niri Config")
else
    echo "No rofi or wofi found." >&2
    exit 1
fi

# ── Bail if nothing was selected ─────────────────────────────────────────────
[ -z "$choice" ] && exit 0

file="${CONFIG_MAP[$choice]}"
[ -z "$file" ] && exit 1

full_path="$CONFIG_DIR/$file"

# ── Open in terminal editor, then reload niri config ─────────────────────────
${TERMINAL:-kitty} nvim "$full_path"
niri msg action reload-config
