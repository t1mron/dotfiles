#!/bin/sh

head_icon=""
head=$(pactl get-sink-volume @DEFAULT_SINK@ | head -n 1 | awk '{print $5}' | sed 's/%//')

if [ "$(pactl list sinks | grep 'Mute: yes' | awk '{print $2}')" ]; then
  head_icon="<span foreground='red'>$head_icon</span>"
fi
