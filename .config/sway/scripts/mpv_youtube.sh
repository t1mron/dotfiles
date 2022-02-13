#!/bin/sh

URL="$(wl-paste)"

if [ -z "${URL##*"https://www.youtube.com/watch?v="*}" ]; then
  swaymsg exec mpv "$URL"
fi
