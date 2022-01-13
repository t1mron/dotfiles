#!/bin/sh

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
udiskie -2 &
# WM
exec bspwm
