#!/bin/sh

focused_aid="$(swaymsg -t get_tree | jq '.. | select(.type?) | select(.focused==true).app_id' | tr -d '"')"
focused_class="$(swaymsg -t get_tree | jq '.. | select(.type?) | select(.focused==true).window_properties.instance' | tr -d '"')"

back_and_forth() {
  if [ -z "${focused_aid##*"$1"*}" ] || [ -z "${focused_class##*"$1"*}" ]; then
    case "$2" in
      "scratchpad")
        swaymsg -q scratchpad show ;;
      *)
        swaymsg -q workspace back_and_forth ;;
    esac
  else
    check="$(swaymsg "[app_id=$1] focus" | jq '.[] | .success')"
    if [ "$check" = "false" ]; then
      swaymsg "[instance=$1] focus"
    fi
  fi
} 
