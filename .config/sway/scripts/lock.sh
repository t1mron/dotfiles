#!/bin/sh

pactl set-sink-mute @DEFAULT_SINK@ 1
pactl set-source-mute @DEFAULT_SOURCE@ 1
swaymsg "output * dpms off"
swaylock
swaymsg "output * dpms on"
