#!/bin/sh

focused_aid="$(swaymsg -t get_tree | jq '.. | select(.type?) | select(.focused==true).app_id' | tr -d '"')"

back_and_forth() {
  if [ -z "${focused_aid##*"$1"*}" ]; then
    swaymsg -q workspace back_and_forth
  else
    swaymsg -q "[app_id=$1] focus"
  fi
} 

back_and_forth_scratchpad() {
  if [ -z "${focused_aid##*"$1"*}" ]; then
    swaymsg -q scratchpad show
  else
    swaymsg -q "[app_id=$1] focus"
  fi
}
