#!/bin/sh

head_icon=""
head="$(pactl get-sink-volume @DEFAULT_SINK@ | head -n 1 | awk '{print $5}' | sed 's/%//')"

sink="$(pactl list sinks | grep "Sink #" | tail -1)"
mute="$(pactl list sinks | grep -A 10 "$sink" | grep 'Mute:' | awk '{print $2}')"

if [ "$mute" = "yes" ]; then
  head_icon="<span foreground='red'>$head_icon</span>"
fi
