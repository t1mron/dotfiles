#!/bin/sh

if [ -d /etc/X11/xinit/xinitrc.d ] ; then
    for f in /etc/X11/xinit/xinitrc.d/?*.sh ; do
        [ -x "$f" ] && . "$f"
    done
    unset f
fi

pipewire &
pipewire-pulse &
dbus-launch sxhkd &
# Lock screen before suspend
xss-lock slock &
# Background
feh --bg-fill $HOME/.wallpaper/death_life.jpg &
# Add mouse cursor support 
xsetroot -cursor_name left_ptr &
# Screen color calibration
xcalib -d :1 $HOME/.config/icc/x200.icc
# Disable screen blanking
xset -dpms s off &
# Disable wi-fi
#sudo /sbin/ip link set wlan0 down &
udiskie &
# WM
exec bspwm
