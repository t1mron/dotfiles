#!/bin/sh

if [ -d /etc/X11/xinit/xinitrc.d ] ; then
    for f in /etc/X11/xinit/xinitrc.d/?*.sh ; do
        [ -x "$f" ] && . "$f"
    done
    unset f
fi

# Sound/Mic
pipewire &
pipewire-pulse &
# Hotkey daemon
dbus-launch sxhkd &
# Background
feh --bg-fill $HOME/.config/bspwm/Wallpapers/death_life.jpg &
# Set cursor theme
xsetroot -cursor_name left_ptr &
# Screen color calibration
xcalib $HOME/.config/icc/x200.icc
# Disable screen blanking
xset -dpms s off &
# Disable wi-fi
#doas /sbin/ip link set wlan0 down &
# Auto mount media drive
udiskie &
# Standalone compositor for Xorg
#picom &
# WM
exec bspwm
