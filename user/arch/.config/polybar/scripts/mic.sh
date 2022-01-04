#!/bin/sh

MIC_ICON=""

if [[ $(pactl list sources | grep 'Mute: yes') ]]; then
  MIC_ICON="%{F#cccccc}$MIC_ICON%{F-}"
fi

printf "%b" $MIC_ICON
