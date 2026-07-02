#!/usr/bin/env bash
# warframe-wiki-search.sh
# Rofi prompt to search the Warframe Wiki.

BROWSER_CMD="${BROWSER:-xdg-open}"

if command -v rofi >/dev/null 2>&1; then
    query=$(rofi -dmenu -i -p "󰫈 Warframe Wiki" \
        -disable-history)
elif command -v wofi >/dev/null 2>&1; then
    query=$(wofi --dmenu -i -p "Warframe Wiki")
else
    echo "No rofi or wofi found." >&2
    exit 1
fi

[ -z "$query" ] && exit 0

encoded=$(jq -rn --arg q "$query" '$q|@uri' 2>/dev/null)
[ -z "$encoded" ] && encoded=$(printf '%s' "$query" | sed 's/ /+/g')

"$BROWSER_CMD" "https://wiki.warframe.com/w/Special:Search?search=${encoded}"
