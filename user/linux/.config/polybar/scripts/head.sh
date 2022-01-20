#!/bin/sh

HEAD_ICON=""
VOLUME=$(pactl get-sink-volume @DEFAULT_SINK@ | head -n 1 | awk '{print $5}' | sed 's/%//')

if pactl list sinks | grep -q 'Mute: yes'; then
  HEAD_ICON="%{F#cccccc}$HEAD_ICON%{F-}"
fi

printf "%b %3d%%\n" $HEAD_ICON "$VOLUME"
