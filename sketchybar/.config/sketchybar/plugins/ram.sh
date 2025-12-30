#!/usr/bin/env bash

VMSTAT=$(vm_stat)
PAGE_SIZE=$(sysctl -n hw.pagesize)
TOTAL_BYTES=$(sysctl -n hw.memsize)

pages() {
  echo "$VMSTAT" |
    awk -v k="$1" '$0 ~ k {gsub(/\./, "", $(NF)); print $(NF)}'
}
FREE=$(pages "Pages free:")
INACTIVE=$(pages "Pages inactive:")
PURGEABLE=$(pages "Pages purgeable:")

AVAILABLE_PAGES=$((FREE + INACTIVE + PURGEABLE))
AVAILABLE_BYTES=$((AVAILABLE_PAGES * PAGE_SIZE))

USED_BYTES=$((TOTAL_BYTES - AVAILABLE_BYTES))

TOTAL_GB=$(awk "BEGIN {printf \"%.0f\", $TOTAL_BYTES/1024/1024/1024}")
USED_GB=$(awk   "BEGIN {printf \"%.1f\", $USED_BYTES/1024/1024/1024}")
PERCENT=$(awk   "BEGIN {printf \"%.0f\", $USED_BYTES*100/$TOTAL_BYTES}")

# Gestion des événements
case "$SENDER" in
  "mouse.entered" | "mouse.clicked")
    # Animation d'expansion au survol
    sketchybar --animate sin 30 \
               --set "$NAME" label="${USED_GB}/${TOTAL_GB}GB (${PERCENT}%)" \
    ;;
  "mouse.exited" | "mouse.exited.global")
    sketchybar --animate sin 20 \
               --set "$NAME" label="${PERCENT}%" \
    ;;
  *)
    sketchybar --set "$NAME" label="${PERCENT}%"
    ;;
esac