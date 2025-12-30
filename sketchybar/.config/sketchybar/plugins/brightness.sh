#!/bin/bash

# Get brightness using osascript
BRIGHTNESS=$(osascript -e 'tell application "System Events" to get value of slider 1 of group 1 of tab group 1 of window 1 of process "System Settings"' 2>/dev/null)

# If osascript fails, try to get it from system_profiler
if [ -z "$BRIGHTNESS" ] || [ "$BRIGHTNESS" = "missing value" ]; then
  # Try to get brightness from system_profiler
  BRIGHTNESS=$(system_profiler SPDisplaysDataType | grep -A 5 "Built-in" | grep "Brightness" | awk '{print $2}' | sed 's/%//')
fi

# If still no value, default to 50
if [ -z "$BRIGHTNESS" ] || [ "$BRIGHTNESS" = "missing value" ]; then
  BRIGHTNESS=50
fi

sketchybar --set $NAME label="${BRIGHTNESS}%" 