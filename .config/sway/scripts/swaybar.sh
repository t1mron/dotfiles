#!/bin/sh

dir="$HOME/.config/sway/scripts/swaybar"

. "$dir/head.sh"
. "$dir/mic.sh"
#. "$dir/temp.sh"
. "$dir/mem.sh"
. "$dir/cpu.sh"
. "$dir/fs.sh"
. "$dir/lght.sh"
. "$dir/time.sh"
. "$dir/kbd.sh"
. "$dir/bat.sh"

printf "%b %3d%% | %b | %b %s | %b %2d%% | %b %s | %b %2d | %b %s | %b %s | %b %2d%%" \
  "$head_icon" "$head" \
  "$mic_icon" \
  "$mem_icon" "$mem" \
  "$cpu_icon" "$cpu" \
  "$fs_icon" "$fs" \
  "$lght_icon" "$lght" \
  "$time_icon" "$time" \
  "$kbd_icon" "$kbd" \
  "$bat_icon" "$bat"
