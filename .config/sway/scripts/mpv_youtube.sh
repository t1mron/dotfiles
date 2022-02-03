#!/bin/sh

# Firefox addon - add-url-to-window-title (set full path url in addon settings)

URL="$(swaymsg -t get_tree | grep -o -E 'https?:[^"]+' | awk '{print $1}' | sed 's/\\//g')"

if [ -z "${URL##*"https://www.youtube.com/watch?v="*}" ]; then
  swaymsg exec mpv "$URL"
fi
