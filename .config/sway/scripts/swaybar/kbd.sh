#!/bin/sh

kbd_icon=""
kbd="$(swaymsg -t get_inputs | jq '.[1].xkb_active_layout_name' | tr -d '"')"

if [ "$kbd" = "Russian" ]; then
  kbd="ru"
else
  kbd="en"
fi

