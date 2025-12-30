#!/bin/bash

WORKSPACE_NAME="$NAME"
FOCUSED_WORKSPACE=$(aerospace list-workspaces --focused)

CACHE_DIR="$HOME/.cache/sketchybar/app_icons"
mkdir -p "$CACHE_DIR"

APP_IDS=$(aerospace list-windows-on-workspace "$WORKSPACE_NAME" --no-empty-lines | jq -r '.[] | .app-id' | sort -u)

ICONS_STRING=""
if [ -n "$APP_IDS" ]; then
    while read -r app_id; do
        icon_cache_path="$CACHE_DIR/${app_id}.png"

        if [ ! -f "$icon_cache_path" ]; then
            app_path=$(mdfind "kMDItemCFBundleIdentifier == '$app_id'" | head -n 1)

            if [ -n "$app_path" ]; then
                icon_name=$(defaults read "$app_path/Contents/Info.plist" CFBundleIconFile)
                [[ "$icon_name" != *".icns" ]] && icon_name="$icon_name.icns"
                
                icon_path="$app_path/Contents/Resources/$icon_name"

                if [ -f "$icon_path" ]; then
                    sips -s format png "$icon_path" --out "$icon_cache_path" >/dev/null 2>&1
                fi
            fi
        fi
        
        if [ -f "$icon_cache_path" ]; then
            ICONS_STRING+="--add item space.$WORKSPACE_NAME.icon.$app_id left "
            ICONS_STRING+="--set space.$WORKSPACE_NAME.icon.$app_id associated_space=$WORKSPACE_NAME "
            ICONS_STRING+="background.image='$icon_cache_path' "
            ICONS_STRING+="background.image.scale=0.7 "
            ICONS_STRING+="background.padding_left=4 "
            ICONS_STRING+="background.padding_right=4 "
            ICONS_STRING+="label.drawing=off "
        fi
    done <<< "$APP_IDS"
fi

CURRENT_ICONS=$(sketchybar --query items | jq -r ".[] | select(.key | startswith(\"space.$WORKSPACE_NAME.icon.\")) | .key")
if [ -n "$CURRENT_ICONS" ]; then
    while read -r current_icon; do
        app_id_of_icon=$(echo "$current_icon" | sed "s/space.$WORKSPACE_NAME.icon.//")
        if ! echo "$APP_IDS" | grep -q "^$app_id_of_icon$"; then
            sketchybar --remove "$current_icon"
        fi
    done <<< "$CURRENT_ICONS"
fi

if [ "$WORKSPACE_NAME" = "$FOCUSED_WORKSPACE" ]; then
    sketchybar --set "$NAME" background.drawing=on icon.highlight=true
else
    sketchybar --set "$NAME" background.drawing=off icon.highlight=false
fi

[ -n "$ICONS_STRING" ] && sketchybar $ICONS_STRING