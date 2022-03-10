#!/bin/sh

. /etc/scripts/back_and_forth.sh

case "$3" in
  "pdf")
    if [ "$(pgrep -fc "$1")" -eq 1 ]; then
      if [ ! "$(pgrep -fc "$2")" -eq 1 ]; then
        back_and_forth "$2"
      fi
    else
      back_and_forth "$1"
    fi ;;
  "scratchpad")
    if [ "$(pgrep -fc "$2")" -eq 1 ]; then
      swaymsg -q exec "$1"
      sleep 0.5
      swaymsg "[app_id=$2] focus"
    else
      back_and_forth "$2" "scratchpad"
    fi ;;
  *)
    if [ "$(pgrep -fc "$2")" -eq 1 ]; then
      swaymsg -q exec "$1"
    else
      back_and_forth "$2"
    fi ;;
esac
