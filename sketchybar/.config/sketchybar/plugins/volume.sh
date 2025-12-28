#!/bin/sh

if [ "$SENDER" = "volume_change" ]; then
  VOLUME="$INFO"
  COUNTER_FILE="/tmp/volume_${NAME}_counter"
  
  case "$VOLUME" in
    [6-9][0-9]|100) ICON="󰕾"
    ;;
    [3-5][0-9]) ICON="󰖀"
    ;;
    [1-9]|[1-2][1-9]) ICON="󰕿"
    ;;
    *) ICON="󰝟"
  esac

  case "$VOLUME" in
    100) WIDTH=40
    ;;
    [1-9][0-9]) WIDTH=35
    ;;
    *) WIDTH=30
  esac

  if [ -f "$COUNTER_FILE" ]; then
    COUNTER=$(($(cat "$COUNTER_FILE") + 1))
  else
    COUNTER=1
  fi
  echo "$COUNTER" > "$COUNTER_FILE"
  
  MY_EVENT_ID="$COUNTER"

  sketchybar --set "$NAME" icon="$ICON" \
             --set "$NAME" label="$VOLUME%" \
             --animate sin 10 --set "$NAME" label.width="$WIDTH"

  (
    sleep 2
    CURRENT_COUNTER=$(cat "$COUNTER_FILE" 2>/dev/null || echo "0")
    if [ "$CURRENT_COUNTER" = "$MY_EVENT_ID" ]; then
      sketchybar --animate sin 10 --set "$NAME" label.width=0
    fi
  ) &
fi