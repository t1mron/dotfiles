#!/bin/sh

. $HOME/.config/sway/scripts/back_and_forth.sh

if [ "$(pgrep -fc "$1")" -eq 2 ]; then
  if [ ! "$(pgrep -fc "$2")" -eq 2 ]; then
    back_and_forth "$2"
  fi
else
  back_and_forth "$1"
fi
