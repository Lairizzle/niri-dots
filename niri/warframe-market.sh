#!/usr/bin/env bash
# warframe-market.sh — structure-agnostic version
#
# Instead of guessing the exact nesting of the v2 API response (which has
# changed before and may change again), this script recursively searches
# the JSON for objects that "look like" an item (has a "slug" key) or an
# order (has a "platinum" key). That means it keeps working even if
# warframe.market reshapes their response envelope.
#
# Debug: run with --dump-raw to print the raw API responses and exit,
# so you can inspect the actual shape yourself if something breaks.

set -euo pipefail

BROWSER_CMD="${BROWSER:-xdg-open}"
API_V2_ITEMS="https://api.warframe.market/v2/items"
API_V2_ORDERS="https://api.warframe.market/v2/orders/item"
API_V1_ORDERS="https://api.warframe.market/v1/items"   # /$slug/orders

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/wf-market"
CACHE_FILE="$CACHE_DIR/items.json"
CACHE_TTL=86400

DUMP_RAW=0
[[ "${1:-}" == "--dump-raw" ]] && DUMP_RAW=1

mkdir -p "$CACHE_DIR"

have() { command -v "$1" >/dev/null 2>&1; }

need() {
    have "$1" || { echo "ERROR: required tool '$1' not found" >&2; exit 1; }
}
need curl
need jq

prompt() {
    if have rofi; then
        rofi -dmenu -i -p "Warframe Market"
    elif have wofi; then
        wofi --dmenu -i -p "Warframe Market"
    else
        echo "ERROR: no rofi/wofi found" >&2
        exit 1
    fi
}

# Show a message to the user. Prefers a rofi/wofi popup (since stdout is
# usually invisible when launched from a rofi keybind), falls back to
# notify-send, then plain echo if neither is available.
show_result() {
    local msg="$1"
    if have rofi; then
        rofi -e "$msg"
    elif have notify-send; then
        notify-send "Warframe Market" "$msg"
    elif have wofi; then
        # wofi has no message-box mode; fake one with a single dmenu entry
        printf '%s\n' "$msg" | wofi --dmenu -i -p "Warframe Market" >/dev/null || true
    else
        echo "$msg"
    fi
}

fetch_json() {
    # fetch_json <url> -> prints body, exits nonzero on transport failure
    local url="$1"
    curl -fsSL --retry 3 --retry-delay 1 \
        -H "Accept: application/json" \
        -H "User-Agent: wf-market-cli/2.0" \
        "$url"
}

# -----------------------------
# Fetch + cache the item catalog
# -----------------------------
fetch_items() {
    if [[ -f "$CACHE_FILE" ]]; then
        local now mod
        now=$(date +%s)
        mod=$(stat -c %Y "$CACHE_FILE" 2>/dev/null || stat -f %m "$CACHE_FILE" 2>/dev/null || echo 0)
        if (( now - mod < CACHE_TTL )); then
            # Validate cache actually contains at least one item-like object
            if jq -e '[.. | objects | select(has("slug"))] | length > 0' "$CACHE_FILE" >/dev/null 2>&1; then
                cat "$CACHE_FILE"
                return
            fi
            rm -f "$CACHE_FILE"
        fi
    fi

    local resp
    resp=$(fetch_json "$API_V2_ITEMS") || {
        echo "ERROR: request to $API_V2_ITEMS failed (network/DNS/HTTP error)" >&2
        exit 1
    }

    if ! jq -e '[.. | objects | select(has("slug"))] | length > 0' <<<"$resp" >/dev/null 2>&1; then
        echo "ERROR: got a response but couldn't find any item-like objects in it." >&2
        echo "Run '$0 --dump-raw' to inspect the raw JSON and see what changed." >&2
        exit 1
    fi

    printf '%s' "$resp" | tee "$CACHE_FILE"
}

if (( DUMP_RAW )); then
    echo "=== RAW /v2/items response (first 4000 chars) ==="
    fetch_json "$API_V2_ITEMS" | head -c 4000
    echo
    echo
    echo "=== jq: all objects with a 'slug' key (first match, pretty) ==="
    fetch_json "$API_V2_ITEMS" | jq '[.. | objects | select(has("slug"))][0]'
    exit 0
fi

data="$(fetch_items)"

# -----------------------------
# Extract item name/slug pairs
# Recursively find any object with a "slug" key, then pull a display
# name from whichever field actually holds it.
# -----------------------------
items_json="$(jq -c '[.. | objects | select(has("slug"))]' <<<"$data")"

pairs="$(jq -r '
    .[]
    | . as $it
    | ($it.i18n.en.name? // $it.en.name? // $it.name? // $it.item_name? // empty) as $n
    | select($n != null and $n != "")
    | "\($n)\t\($it.slug)"
' <<<"$items_json")"

if [[ -z "$pairs" ]]; then
    echo "ERROR: found item objects but couldn't extract any names from them." >&2
    echo "Run '$0 --dump-raw' to see the actual field names and adjust the script." >&2
    exit 1
fi

# de-dupe by name (keep first slug seen) in case of repeated entries
mapfile -t pair_lines < <(printf '%s\n' "$pairs" | sort -u -t $'\t' -k1,1)

names_only="$(printf '%s\n' "${pair_lines[@]}" | cut -f1)"

query="$(printf '%s\n' "$names_only" | prompt || true)"
[[ -z "$query" ]] && exit 0

# -----------------------------
# Resolve slug: exact match first, then case-insensitive contains
# -----------------------------
slug=""
for line in "${pair_lines[@]}"; do
    name="${line%%$'\t'*}"
    if [[ "$name" == "$query" ]]; then
        slug="${line##*$'\t'}"
        break
    fi
done

if [[ -z "$slug" ]]; then
    q_lower="$(tr '[:upper:]' '[:lower:]' <<<"$query")"
    for line in "${pair_lines[@]}"; do
        name="${line%%$'\t'*}"
        name_lower="$(tr '[:upper:]' '[:lower:]' <<<"$name")"
        if [[ "$name_lower" == *"$q_lower"* ]]; then
            slug="${line##*$'\t'}"
            break
        fi
    done
fi

if [[ -z "$slug" ]]; then
    echo "ERROR: no slug resolved for '$query'" >&2
    exit 1
fi

# -----------------------------
# Fetch orders — try v2 first, fall back to v1
# Recursively find order-like objects (anything with a "platinum" key),
# then read type/status from whichever field name is actually present.
# -----------------------------
orders_resp=""
if orders_resp="$(fetch_json "$API_V2_ORDERS/$slug" 2>/dev/null)"; then
    :
elif orders_resp="$(fetch_json "$API_V1_ORDERS/$slug/orders" 2>/dev/null)"; then
    :
else
    echo "ERROR: failed to fetch orders for slug '$slug' (tried v2 and v1)" >&2
    exit 1
fi

cheapest_sell="$(jq -r '
    [.. | objects | select(has("platinum"))]
    | map(select(
        ((.order_type? // .type? // "") == "sell")
        and
        ((.user.status? // .status? // "") == "ingame")
      ))
    | sort_by(.platinum)
    | .[0].platinum // "unknown"
' <<<"$orders_resp")"

note=""
if [[ "$cheapest_sell" == "unknown" || -z "$cheapest_sell" ]]; then
    note=$'\n(no \'ingame\' sell order found — maybe nobody\'s online right now)'
fi

result_msg="$query
Slug: $slug
Cheapest sell: ${cheapest_sell}p${note}"

# Always log to stderr too, in case you run this from a terminal
echo "--------------------------------" >&2
echo "$result_msg" >&2
echo "--------------------------------" >&2

show_result "$result_msg"

# Ask whether to open the browser, rather than always doing it
open_choice=""
if have rofi; then
    open_choice="$(printf 'No\nYes' | rofi -dmenu -i -p "Open in browser?")"
elif have wofi; then
    open_choice="$(printf 'No\nYes' | wofi --dmenu -i -p "Open in browser?")"
fi

if [[ "$open_choice" == "Yes" ]]; then
    "$BROWSER_CMD" "https://warframe.market/items/$slug" 2>/dev/null || true
fi
