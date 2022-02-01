#!/bin/bash

if [[ $(pgrep -fc "$1") -eq 1 ]]; then
  swaymsg -q exec "$2"
else
  if [[ $1 == "f00t-scratchpad" ]]; then
    swaymsg -q scratchpad show
  else
    swaymsg -q "[app_id=$1] focus"
  fi
fi
