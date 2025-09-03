#!/usr/bin/env bash

# make sure it's executable with:
# chmod +x ~/.config/sketchybar/plugins/aerospace.sh

# Highlight the focused workspace
if [ "$1" = "$FOCUSED_WORKSPACE" ]; then
  sketchybar --set $NAME background.color=0x66FFFFFF background.border_width=2
else
  sketchybar --set $NAME background.color=0x44FFFFFF background.border_width=0
fi

# Update the window icons for the workspace
apps=$(aerospace list-windows --workspace "$1" | awk -F'|' '{gsub(/^ *| *$/, "", $2); print $2}')
icon_strip=" "
if [ "${apps}" != "" ]; then
  while read -r app
  do
    icon_strip+=" $($CONFIG_DIR/plugins/icon_map_fn.sh "$app")"
  done <<< "${apps}"
  sketchybar --set $NAME drawing=on
else
  icon_strip=""
  sketchybar --set $NAME drawing=off
fi
sketchybar --set $NAME label="$icon_strip"