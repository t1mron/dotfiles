#!/bin/sh

bat="$(cat /sys/class/power_supply/BAT0/capacity)"
bat_status="$(cat /sys/class/power_supply/BAT0/status)"

if [ "$bat" -ge 80 ] && [ "$bat" -lt 100 ]; then
  bat_icon=""
elif [ "$bat" -ge 60 ] && [ "$bat" -lt 80 ]; then
  bat_icon=""
elif [ "$bat" -ge 40 ] && [ "$bat" -lt 60 ]; then
  bat_icon=""
elif [ "$bat" -ge 20 ] && [ "$bat" -lt 40 ]; then
  bat_icon=""
elif [ "$bat" -ge 0 ] && [ "$bat" -lt 20 ]; then
  bat_icon=""
else
  bat="99"
  bat_icon=""
fi

if [ "$bat_status" = "Discharging" ]; then
  bat_icon="<span foreground='red'>$bat_icon</span>"
fi
