#!/bin/bash

# Firefox addon - add-url-to-window-title (set full path url in settings)

URL=$(xdotool getwindowfocus getwindowname | grep -o -E 'https?://[^"]+' | awk '{print $1}')

if [[ $URL == *"https://www.youtube.com/watch?v="* ]]; then
  mpv "$URL" &
fi
