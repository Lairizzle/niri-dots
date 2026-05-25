#!/usr/bin/env bash
# wallpaper-switcher.sh — pick & apply wallpapers with rofi + image preview
# Dependencies: rofi, awww (or swww), find, imagemagick (recommended)
# Usage: ./wallpaper-switcher.sh [wallpaper_directory]

WALLPAPER_DIR="${1:-$HOME/.config/wallpapers/}"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/wallpaper-switcher"
PREVIEW_SIZE="800x450"
EXTENSIONS="jpg|jpeg|png|gif|webp|bmp"

# ─── Validate wallpaper directory ─────────────────────────────────────────────

if [[ ! -d "$WALLPAPER_DIR" ]]; then
  notify-send -u critical "wallpaper-switcher" \
    "Directory not found: $WALLPAPER_DIR" 2>/dev/null
  echo "Error: wallpaper directory not found: $WALLPAPER_DIR" >&2
  exit 1
fi

# ─── Detect wallpaper setter ──────────────────────────────────────────────────

if command -v awww &>/dev/null; then
  SETTER="awww"
elif command -v swww &>/dev/null; then
  SETTER="swww"
else
  notify-send -u critical "wallpaper-switcher" \
    "Neither 'awww' nor 'swww' found in PATH." 2>/dev/null
  echo "Error: awww / swww not found." >&2
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
    -p "Wallpaper" \
    -show-icons \
    -theme-str 'window { width: 500px; height: 700px; } listview { columns: 1; lines: 2; } element { orientation: vertical; } element-icon { size: 250px; } element-text { horizontal-align: 0.5; }' \
    -format 's'
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

case "$SETTER" in
  awww)
    awww img "$SELECTED" --transition-type wipe --transition-duration 1
    ;;
  swww)
    swww query &>/dev/null || swww init
    swww img "$SELECTED" --transition-type wipe --transition-duration 1
    ;;
esac

STATUS=$?

if [[ $STATUS -eq 0 ]]; then
  notify-send "Wallpaper set" "$(basename "$SELECTED")" -i "$SELECTED" 2>/dev/null
  echo "Wallpaper set: $SELECTED"
else
  notify-send -u critical "wallpaper-switcher" \
    "Failed to set wallpaper (exit $STATUS)" 2>/dev/null
  echo "Error: $SETTER exited with status $STATUS" >&2
  exit $STATUS
fi
