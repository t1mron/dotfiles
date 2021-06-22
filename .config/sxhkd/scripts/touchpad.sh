#!/usr/bin/sh

# toggle synaptic touchpad on/off

device="SYNA30AC:00 06CB:CDEB Touchpad"
state=$(xinput list-props "$device" | grep "Device Enabled" | grep -o "[01]$")

if [ $state == '1' ];then
  xinput --disable "$device"
else
  xinput --enable "$device"
fi
