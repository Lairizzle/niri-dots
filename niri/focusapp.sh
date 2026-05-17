#!/usr/bin/env bash

app="$1"

niri msg action focus-window --id "$(
  niri msg windows |
  awk -v app="$app" '
  /Window ID/ { id=$3; sub(":", "", id) }
  $0 ~ "App ID: \"" app "\"" { print id; exit }
  '
)"
