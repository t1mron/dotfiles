#!/bin/sh

cpu_icon=""
cpu="$(top -bn1 | awk '/Cpu/ {print $2 + $4}' | cut -d. -f1)"

if [ "$cpu" -eq "100" ]; then
  cpu="99"
fi
