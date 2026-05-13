#!/usr/bin/env bash

if pgrep -x wiremix >/dev/null; then
    pkill -x wiremix
    exit 0
fi

kitty --class wiremix -e wiremix &

sleep 0.2

# ensure we target correct window
niri msg action focus-window

# size FIRST (prevents layout jump)
niri msg action set-window-width 600
niri msg action set-window-height 400

# give layout time to settle
sleep 0.05

