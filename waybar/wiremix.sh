#!/usr/bin/env bash
# ~/.config/waybar/scripts/toggle-wiremix.sh

if pgrep -x wiremix > /dev/null; then
    pkill -KILL -x wiremix
else
    kitty --class wiremix -e wiremix &
fi
