#!/bin/sh

case "$1" in
  "part")
    grim -g "$(slurp)" -t png - | wl-copy -t image/png ;;
  "focus")
    focused_window=$(swaymsg -t get_tree | jq -r '.. | select(.focused?) | .rect | "\(.x),\(.y) \(.width)x\(.height)"')
    grim -g "$focused_window" -t png - | wl-copy -t image/png ;;
  "full")
    grim -t png - | wl-copy -t image/png ;;
esac
