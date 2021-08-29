#!/bin/sh

#########
# BASIC #
#########

PANEL="$HOME"/.config/lemonbar
PANEL_FIFO=/tmp/panel-fifo
PANEL_HEIGHT=18
PANEL_FONT="fixed"
PANEL_FONT_ICON="Wuncon Siji"
PANEL_WM_NAME="bspwm_panel"
PANEL_MONITOR="LVDS1"
. "$PANEL"/panel_colors.sh


###########
# CLEANUP #
###########

trap 'trap - TERM; kill 0' INT TERM QUIT EXIT

[[ -e "$PANEL_FIFO" ]] && rm "$PANEL_FIFO"
mkfifo "$PANEL_FIFO"


###########
# MODULES #
###########

###---WM---###
bspc subscribe report > "$PANEL_FIFO" &

while :; do
  ###---BATTERY---###
  BAT=$(cat /sys/class/power_supply/BAT0/capacity)
  #BAT_STATUS=$(cat /sys/class/power_supply/BAT0/status) it's better for optimization but my battery has broken (status unknown)
  BAT_STATUS=$(acpi | grep -c Discharging)

  case "$BAT" in  
    100)
      BAT=99 
      BAT_ICON="\356\211\213" ;;
    9[0-9])
      BAT_ICON="\356\211\213" ;;
    8[0-9])
      BAT_ICON="\356\211\212" ;;
    7[0-9])
      BAT_ICON="\356\211\211" ;;
    6[0-9])
      BAT_ICON="\356\211\210" ;;
    5[0-9])
      BAT_ICON="\356\211\207" ;;
    4[0-9])
      BAT_ICON="\356\211\206" ;;
    3[0-9])
      BAT_ICON="\356\211\205" ;;
    2[0-9])
      BAT_ICON="\356\211\204" ;;
    1[0-9])
      BAT_ICON="\356\211\203" ;;
    *)
      BAT_ICON="\356\211\202" ;;
  esac

  case "$BAT_STATUS" in
    1)
      BAT_ICON="%{F#999999}$BAT_ICON%{F-}" ;;
  esac 

  ###---CPU---###
  CPU=$(top -bn1 | awk '/Cpu/ {print $2 + $4}' | cut -d. -f1)

  case "$CPU" in 
    100)
      CPU="99" ;;
  esac

  ###---MEMORY---###
  MEM=$(free -h | awk '/Mem/ {print $3}')

  ###---TEMPERATURE---###
  TEMP=$(sensors | grep -oP 'Core 1.*?\+\K[0-9]+')

  ###---FILESYSTEM---###
  FS=$(df -h /dev/mapper/matrix-rootvol | awk '/[0-9]%/ {print $(NF-2)}')

  ###---WiFi---###

  # In devuan you can't use wifi-tools without the root access :( Check sudoers rules
  # Set "" or "sudo/doas"
  # Requirements: iwd(iwctl),iw and siji bitmap font for non-xft lemonbar

  WIFI_DEVICE="wlan0"
  WIFI_STATE=$(iwctl device "$WIFI_DEVICE" show | awk '/Powered/ {print $4}')
  WIFI_SSID="" # don't touch this variable

  WIFI_ICON_ON="\356\210\232"
  WIFI_ICON_OFF="%{F#999999}$WIFI_ICON_ON%{F-}" # grey foreground

  WIFI_ICON_RAMP_1="$WIFI_ICON_ON" # 100% signal
  WIFI_ICON_RAMP_2="\356\210\231" # 50-100% signal
  WIFI_ICON_RAMP_3="\356\210\230" # 0-50% signal

  case "$WIFI_STATE" in
    on)
      WIFI_STATE=$(iwctl station "$WIFI_DEVICE" show | awk '/State/ {print $2}') 

      case "$WIFI_STATE" in 
        connected)
          WIFI_SSID=$(iw dev "$WIFI_DEVICE" link | awk '/SSID/ {print $2}')
          WIFI_SIGNAL=$(iw dev "$WIFI_DEVICE" link | grep -oP 'signal:.*?\K[0-9]+')

          if [[ "$WIFI_SIGNAL" -le 50 ]]; then
            WIFI_ICON=" $WIFI_ICON_RAMP_1" 
          elif [[ "$WIFI_SIGNAL" -ge 51 ]] && [[ "$WIFI_SIGNAL" -le 75 ]]; then
            WIFI_ICON=" $WIFI_ICON_RAMP_2"
          else 
            WIFI_ICON=" $WIFI_ICON_RAMP_3"
          fi ;; 
        *)
          WIFI_ICON="$WIFI_ICON_ON" ;;
      esac ;; 
    *)
      WIFI_ICON="$WIFI_ICON_OFF" ;; 
  esac 
  
  ###---BLUETOOTH---###
  case "$(bluetoothctl show | grep "Powered: yes" | wc -c)" in
    0)
      BLUETOOTH_ICON="%{F#cccccc}\356\200\213%{F-}" ;;
    *)
      case "$(echo info | bluetoothctl | grep 'Device' | wc -c)" in
        0)
          BLUETOOTH_ICON="\356\200\213" ;;
        *)
          BLUETOOTH_ICON="%{F#2193ff}\356\200\213%{F-}" ;;
      esac ;;
  esac 

  ###---HEADPHONE---###
  HEAD=$(amixer sget Master | awk -F"[][]" '/Front Left:/ {print $2}') # replace Mono, most pc\laptops don't use mono
  HEAD_STATUS=$(amixer sget Master | awk -F"[][]" '/Front Left:/ {print $4}')
  HEAD_ICON="\356\201\215"

  case "$HEAD" in 
    100%)
      HEAD="99%" ;;
  esac

  case "$HEAD_STATUS" in
    off)
      HEAD_ICON="%{F#cccccc}$HEAD_ICON%{F-}" ;; 
  esac

  ###---MICROPHONE---###
  MIC=$(amixer sget Capture | awk -F"[][]" '/Front Left:/ {print $4}')
  MIC_ICON="\356\201\214"

  case "$MIC" in
    off)
      MIC_ICON="%{F#cccccc}$MIC_ICON%{F-}" ;;
  esac

  ###---BACKLIGHT---###
  LGHT=$(cat /sys/class/backlight/acpi_video0/actual_brightness) # level output (min - 0,max -15)

  ###---KEYBOARD---###
  KBD=$(xset -q | awk '/LED/ {print $10}') 
  
  case "$KBD" in  
    00001000)
      KBD="ru" ;;
    *)
      KBD="us" ;;
  esac

  ###--OUTPUT---###
  printf "BAT%b%2d%%\nCPU%b%2d%%\nMEM%b%s\nTEMP%b%2d°C\nFS%b%s\nWIFI%s%b\nBLTH%b\nHEAD%b%3s\nMIC%b\nLGHT%b%2d\nKBD%b%s\n" \
    "$BAT_ICON"    "$BAT"  \
    "\356\200\246" "$CPU"   \
    "\356\200\241" "$MEM"    \
    "\356\203\217" "$TEMP"    \
    "\356\207\240" "$FS"       \
    "$WIFI_SSID"   "$WIFI_ICON" \
    "$BLUETOOTH_ICON"            \
    "$HEAD_ICON"   "$HEAD"        \
    "$MIC_ICON"                    \
    "\356\210\264" "$LGHT"          \
    "\356\211\257" "$KBD"     
    
  sleep 1 
done > "$PANEL_FIFO" &

while :; do
  ###---DATE---###
  DATE=$(date +'%H:%M')

  ###--OUTPUT---###
  printf "DATE%b%s\n" \
    "\356\200\226" "$DATE"

  sleep 60 
done > "$PANEL_FIFO" &


###########
# STARTUP #
###########

"$PANEL"/panel_bar.sh < "$PANEL_FIFO" | lemonbar \
  -a 32 \
  -u 2 \
  -n "$PANEL_WM_NAME" \
  -g x"$PANEL_HEIGHT" \
  -f "$PANEL_FONT" \
  -f "$PANEL_FONT_ICON" \
  -F "$COLOR_DEFAULT_FG" \
  -B "$COLOR_DEFAULT_BG" \
  "$PANEL_MONITOR" | sh &

WID=$(xdo id -m -a "$PANEL_WM_NAME")
xdo above -t "$(xdo id -N Bspwm -n root | sort | head -n 1)" "$WID"

wait
