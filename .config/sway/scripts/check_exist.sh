#!/bin/sh

. $HOME/.config/sway/scripts/back_and_forth.sh

if [ "$(pgrep -fc "$2")" -eq 2 ]; then
  swaymsg -q exec "$1"
else
  back_and_forth "$2"
fi
