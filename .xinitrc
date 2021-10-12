#!/bin/sh

urxvtd -q -f -o &
exec bspwm
