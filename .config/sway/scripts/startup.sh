#!/bin/sh

start(){
  if [ "$(pgrep -fc "$1")" -eq 0 ]; then
    $1 &
  else
    pkill -f "$1"
    $1 &
  fi
}

if [ ! "$(pgrep -fc "electron")" -eq 0 ]; then
  pkill -f "electron"
fi

start pipewire
start pipewire-pulse
start udiskie
start "foot --server"
start "playerctld daemon"

start iwgtk
start pavucontrol
start blueman-applet
start blueman-manager
start "footclient -a f00t-terminal -T f00t-scratchpad"

pactl set-sink-mute @DEFAULT_SINK@ 1 &
pactl set-source-mute @DEFAULT_SOURCE@ 1 &
