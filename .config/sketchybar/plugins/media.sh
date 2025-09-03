#!/bin/bash

case "$SENDER" in
  "media_change")
    if [[ -n "$INFO" ]]; then
        TITLE=$(echo "$INFO" | jq -r '.title // empty' 2>/dev/null)
        ARTIST=$(echo "$INFO" | jq -r '.artist // empty' 2>/dev/null)
        STATE=$(echo "$INFO" | jq -r '.state // empty' 2>/dev/null)
        
        if [[ "$STATE" == "playing" && -n "$TITLE" ]]; then
            DISPLAY_TEXT="$TITLE"
            [[ -n "$ARTIST" ]] && DISPLAY_TEXT="$TITLE - $ARTIST"
            
            sketchybar --set "$NAME" \
                       drawing=on \
                       label="♪ $DISPLAY_TEXT" \
                       label.width=280 \
                       label.max_chars=40 \
                       scroll_texts=on
        else
            sketchybar --set "$NAME" drawing=off
        fi
    else
        sketchybar --set "$NAME" drawing=off
    fi
    ;;
  "mouse.entered")
    sketchybar --set "$NAME" scroll_texts=off
    ;;
  "mouse.exited")
    sketchybar --set "$NAME" scroll_texts=on
    ;;
esac