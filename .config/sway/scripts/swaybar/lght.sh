#!/bin/sh

lght_icon=""
lght="$(brightnessctl info | grep "Current" | awk '{print $4}' | tr -d '()%')"

if [ "$lght" -eq "100" ]; then
  lght="99"
fi
