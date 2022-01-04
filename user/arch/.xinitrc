#!/bin/sh

if [ -d /etc/X11/xinit/xinitrc.d ] ; then
  for f in /etc/X11/xinit/xinitrc.d/?* ; do
    [ -x "$f" ] && . "$f"
  done
  unset f
fi

pgrep -x sxhkd > /dev/null || sxhkd &
# Background
feh --bg-fill $HOME/.wallpaper/death_life.jpg &
# Add mouse cursor support 
xsetroot -cursor_name left_ptr &
# Screen color calibration
xcalib -d :0 $HOME/.config/icc/x200.icc
# Disable screen blanking
xset -dpms s off &
# Disable wi-fi
#sudo /sbin/ip link set wlan0 down &
# Disable eth
#sudo /sbin/ip link set enp1s0 down &
# Disable headphone/mic
pactl set-sink-mute @DEFAULT_SINK@ 1 &
pactl set-source-mute @DEFAULT_SOURCE@ 1 &
udiskie -2 &
flameshot &
# WM
exec bspwm
