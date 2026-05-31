#!/usr/bin/env bash

if pgrep -x wiremix >/dev/null; then
    pkill -x wiremix
    exit 0
fi

kitty --class wiremix -e wiremix &

sleep 0.2

# ensure we target correct window
niri msg action focus-window

