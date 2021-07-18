#!/bin/bash

#########
# BASIC #
#########

PANEL=$HOME/.config/lemonbar
PANEL_FIFO=/tmp/panel-fifo
PANEL_HEIGHT=18
PANEL_FONT="fixed"
PANEL_FONT_ICON="-wuncon-siji-medium-r-normal--10-100-75-75-c-80-iso10646-1"
PANEL_WM_NAME=bspwm_panel

. $PANEL/panel_colors.sh


###########
# STARTUP #
###########

trap 'trap - TERM; kill 0' INT TERM QUIT EXIT

[ -e "$PANEL_FIFO" ] && rm "$PANEL_FIFO"
mkfifo "$PANEL_FIFO"


###########
# MODULES #
###########

###---WM---###
bspc subscribe report > "$PANEL_FIFO" &


while :; do
  ###---BATTERY---###
  #STATUS=$(cat /sys/class/power_supply/BAT0/status)
  STATUS=$(acpi | grep Discharging | wc -l)
  CAP=$(cat /sys/class/power_supply/BAT0/capacity)

  case $CAP in  
    9*)
      ICON="\ue24b"
      ;;
    8*)
      ICON="\ue24a"
      ;;
    7*)
      ICON="\ue249"
      ;;
    6*)
      ICON="\ue248"
      ;;
    5*)
      ICON="\ue247"
      ;;
    4*)
      ICON="\ue246"
      ;;
    3*)
      ICON="\ue245"
      ;;
    2*)
      ICON="\ue244"
      ;;
    1*)
      ICON="\ue243"
      ;;
    *)
      ICON="\ue242"
      ;;
  esac

  if [ $STATUS -eq 1 ]; then 
    ICON="%{F#999999}$ICON%{F-}"
  fi
  
  ###---CPU---###
  CPU=$(top -bn1 | grep Cpu | awk '{print $2 + $4}')
  
  ###---MEMORY---###
  MEM=$(free -h | grep Mem | awk '{print $3}')

  ###---TEMPERATURE---###
  TEMP=$(sensors | grep -oP 'Core 1.*?\+\K[0-9.]+')

  ###---FILESYSTEM---###
  FS=$(df -h /dev/sda1 | tail -n 1 | awk '{print $4}')

  ###---KEYBOARD---###
  KBD=$(xset -q | grep LED | awk '{ print $10 }'| grep -o '1') 
  
  case $KBD in  
  1*)
    KBD="ru"
    ;;
  *)
    KBD="us"
    ;;
  esac

  ###--OUTPUT---###
  printf "BAT%b %2d%%\nCPU%b %3d%%\nMEM%b %s\nTEMP%b %2d°C\nFS%b %s\nKBD%b %s\n" \
    "$ICON"  "$CAP" \
    "\ue026" "$CPU"  \
    "\ue021" "$MEM"   \
    "\ue0cf" "$TEMP"   \
    "\ue1e0" "$FS"      \
    "\ue26f" "$KBD"

  sleep 1 
done > $PANEL_FIFO &



#while :; do
#
#  sleep 1 
#done > $PANEL_FIFO &




# Brightness
#while :; do
#    echo "BRI$(xbacklight -get | cut -d'.' -f1)%" > $fifo
#    sleep 0.5
#done &

# Volume
#while :; do
#    current=$(pactl list sinks | awk '/\tVolume/ {print $5}')
#    current_n=$(cut -d'%' -f1 <<< $current)
#
#    if [[ "$(pactl list sinks | awk '/Mute:/ {print $2}')" == "yes" ]]; then
#        icon="\ufa80"
#    elif [ $current_n -gt 50 ]; then
#        icon="\ufa7d"
#    elif [ $current_n -gt 25 ]; then
#        icon="\ufa7f"
#    else
#        icon="\ufa7e"
#    fi

#    echo "VOL${icon} ${current}" > $fifo
#
#    sleep 0.5
#done &



while :; do
  ###---DATE---###
  DATE=$(date +'%H:%M')

  printf "DATE%b %s\n" \
    "\ue016" "$DATE"

  sleep 60 
done > $PANEL_FIFO &







$PANEL/panel_bar.sh < "$PANEL_FIFO" | lemonbar \
  -a 32 \
  -u 2 \
  -n $PANEL_WM_NAME \
  -g x$PANEL_HEIGHT \
  -f $PANEL_FONT \
  -f $PANEL_FONT_ICON \
  -F $COLOR_DEFAULT_FG \
  -B $COLOR_DEFAULT_BG | sh &

wid=$(xdo id -m -a "$PANEL_WM_NAME")
xdo above -t "$(xdo id -N Bspwm -n root | sort | head -n 1)" "$wid"

wait
