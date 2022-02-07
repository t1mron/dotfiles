#!/bin/sh

pactl set-sink-mute @DEFAULT_SINK@ 1 &
pactl set-source-mute @DEFAULT_SOURCE@ 1 &
playerctl -a pause || true
swaymsg bar hidden_state hide
swaymsg "output * dpms off"
swaylock
