#!/bin/sh

mic_icon=""

if [ "$(pactl list sources | grep 'Mute: yes' | awk '{print $2}')" ]; then
  mic_icon="<span foreground='red'>$mic_icon</span>"
fi
