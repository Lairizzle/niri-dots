#!/usr/bin/env bash
# wallpaper-switcher.sh — pick & apply wallpapers with rofi + image preview
# Dependencies: rofi, awww, find, imagemagick (recommended)
# Usage: ./wallpaper-switcher.sh [wallpaper_directory]

WALLPAPER_DIR="${1:-$HOME/.config/wallpapers/}"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/wallpaper-switcher"
PREVIEW_SIZE="800x450"
EXTENSIONS="jpg|jpeg|png|gif|webp|bmp"
AWWW_OUTPUT="dp-1"

# ─── Environment ──────────────────────────────────────────────────────────────
export WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-1}"
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
export DISPLAY="${DISPLAY:-:0}"

# ─── Validate wallpaper directory ─────────────────────────────────────────────
if [[ ! -d "$WALLPAPER_DIR" ]]; then
  notify-send -u critical "wallpaper-switcher" \
    "Directory not found: $WALLPAPER_DIR" 2>/dev/null
  echo "Error: wallpaper directory not found: $WALLPAPER_DIR" >&2
  exit 1
fi

# ─── Validate dependencies ────────────────────────────────────────────────────
if ! command -v awww &>/dev/null; then
  notify-send -u critical "wallpaper-switcher" \
    "'awww' not found in PATH." 2>/dev/null
  echo "Error: awww not found." >&2
  exit 1
fi

for cmd in rofi find; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "Error: '$cmd' is required but not installed." >&2
    exit 1
  fi
done

HAS_CONVERT=false
command -v convert &>/dev/null && HAS_CONVERT=true

# ─── Thumbnail cache ──────────────────────────────────────────────────────────
mkdir -p "$CACHE_DIR"

generate_thumbnail() {
  local src="$1"
  local hash
  hash=$(printf '%s' "$src" | sha256sum | cut -d' ' -f1)
  local thumb="$CACHE_DIR/${hash}.png"
  if [[ ! -f "$thumb" ]] && $HAS_CONVERT; then
    convert "$src" \
      -thumbnail "${PREVIEW_SIZE}^" \
      -gravity Center \
      -extent "$PREVIEW_SIZE" \
      "$thumb" 2>/dev/null
  fi
  echo "$thumb"
}

# ─── Collect wallpapers ───────────────────────────────────────────────────────
mapfile -d '' WALLPAPERS < <(
  find "$WALLPAPER_DIR" -type f -regextype posix-extended \
    -iregex ".*\.(${EXTENSIONS})" -print0 | sort -z
)

if [[ ${#WALLPAPERS[@]} -eq 0 ]]; then
  notify-send "wallpaper-switcher" "No wallpapers found in $WALLPAPER_DIR"
  echo "No wallpapers found in $WALLPAPER_DIR" >&2
  exit 1
fi

# ─── Build rofi entries ───────────────────────────────────────────────────────
build_rofi_entries() {
  for wall in "${WALLPAPERS[@]}"; do
    local name thumb
    name=$(basename "$wall")
    thumb=$(generate_thumbnail "$wall")
    if [[ -f "$thumb" ]]; then
      printf '%s\0icon\x1f%s\n' "$name" "$thumb"
    else
      printf '%s\0icon\x1f%s\n' "$name" "$wall"
    fi
  done
}

# ─── Run rofi ─────────────────────────────────────────────────────────────────
CHOSEN=$(
  build_rofi_entries | rofi \
    -dmenu \
    -i \
    -p "󰸉 Wallpaper" \
    -show-icons \
    -theme-str 'window { width: 500px; height: 700px; } listview { columns: 1; lines: 2; } element { orientation: vertical; } element-icon { size: 250px; } element-text { horizontal-align: 0.5; }'
)

[[ -z "$CHOSEN" ]] && exit 0

# ─── Resolve full path ────────────────────────────────────────────────────────
SELECTED=""
for wall in "${WALLPAPERS[@]}"; do
  if [[ "$(basename "$wall")" == "$CHOSEN" ]]; then
    SELECTED="$wall"
    break
  fi
done

if [[ -z "$SELECTED" ]]; then
  echo "Error: could not resolve path for '$CHOSEN'" >&2
  exit 1
fi

# ─── Apply wallpaper ──────────────────────────────────────────────────────────
awww query &>/dev/null || { awww-daemon --namespace "$AWWW_OUTPUT" & sleep 0.5; }

awww img "$SELECTED" --namespace "$AWWW_OUTPUT" \
  --transition-type wipe \
  --transition-duration 1

STATUS=$?
if [[ $STATUS -eq 0 ]]; then
  notify-send "Wallpaper set" "$(basename "$SELECTED")" -i "$SELECTED" 2>/dev/null
  echo "Wallpaper set: $SELECTED"
else
  notify-send -u critical "wallpaper-switcher" \
    "Failed to set wallpaper (exit $STATUS)" 2>/dev/null
  echo "Error: awww exited with status $STATUS" >&2
  exit $STATUS
fi
