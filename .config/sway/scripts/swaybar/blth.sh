#!/bin/sh

blth_icon=""
powered="$(bluetoothctl show | grep "Powered: yes" | wc -c)"

if [ "$powered" = "0" ]; then
  blth_icon="<span foreground='red'>$blth_icon</span>"
else
  device="$(echo info | bluetoothctl | grep 'Device' | wc -c)"
  if [ "$device" != "0" ]; then
    blth_icon="<span foreground='#2193ff'>$blth_icon</span>"
  fi
fi
