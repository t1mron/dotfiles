#!/bin/bash

volume=$(awk -F"[][]" '/Front Left:/ { print $2 }' <(amixer sget Capture))

if [[ "$volume" == "0%" ]]; then
  echo "%{F#cccccc}"
else
  echo ""
fi
