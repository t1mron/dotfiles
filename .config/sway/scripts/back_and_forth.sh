#!/bin/sh

focused_aid="$(swaymsg -t get_tree | jq '.. | select(.type?) | select(.focused==true).app_id' | tr -d '"')"

back_and_forth() {
  if [ -z "${focused_aid##*"$1"*}" ]; then
    case "$2" in
      "scratchpad")
        swaymsg -q scratchpad show ;;
      *)
        swaymsg -q workspace back_and_forth ;;
    esac
  else
    swaymsg -q "[app_id=$1] focus"
  fi
} 
