#!/bin/sh

temp_icon=""
temp="$(($(cat /sys/devices/platform/coretemp.0/hwmon/hwmon4/temp3_input) / 1000))"
