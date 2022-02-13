#!/bin/sh

start(){
  if [ "$(pgrep -fc "$1")" -eq 0 ]; then
    $1 &
  else
    pkill -f "$1"
    $1 &
  fi
}

start pipewire
start pipewire-pulse
start udiskie
start "foot --server"
start "playerctld daemon"

pactl set-sink-mute @DEFAULT_SINK@ 1 &
pactl set-source-mute @DEFAULT_SOURCE@ 1 &
