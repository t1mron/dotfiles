#!/bin/bash

# Terminate already running bar instances
pkill -x polybar

# Wait until the processes have been shut down
while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done

# Start polybar
polybar top &
