#!/bin/sh

MIC_ICON=""

if pactl list sources | grep -q 'Mute: yes'; then
  MIC_ICON="%{F#cccccc}$MIC_ICON%{F-}"
fi

printf "%b\n" $MIC_ICON
