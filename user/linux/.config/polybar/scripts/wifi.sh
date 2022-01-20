#!/bin/sh

# In debian/devuan you can't use wifi-tools without the root access :( Check sudoers rules
# Requirements: iwd(iwctl),iw and siji ttf font

WIFI_DEVICE="wlan0"
WIFI_STATE=$(iwctl device "$WIFI_DEVICE" show | awk '/Powered/ {print $4}')
WIFI_SSID="" # don't touch this variable

WIFI_ICON_ON=""
WIFI_ICON_OFF="%{F#999999}$WIFI_ICON_ON%{F-}" # grey foreground

WIFI_ICON_RAMP_1="$WIFI_ICON_ON" # 100% signal
WIFI_ICON_RAMP_2="" # 50-100% signal
WIFI_ICON_RAMP_3="" # 0-50% signal

case "$WIFI_STATE" in
  on)
    WIFI_STATE=$(iwctl station "$WIFI_DEVICE" show | awk '/State/ {print $2}') 

    case "$WIFI_STATE" in 
      connected)
        WIFI_SSID=$(iw dev "$WIFI_DEVICE" link | awk '/SSID/ {print $2}')
        WIFI_SIGNAL=$(iw dev "$WIFI_DEVICE" link | grep -oP 'signal:.*?\K[0-9]+')

        if [ "$WIFI_SIGNAL" -le 50 ]; then
          WIFI_ICON="$WIFI_ICON_RAMP_1" 
        elif [ "$WIFI_SIGNAL" -ge 51 ] && [ "$WIFI_SIGNAL" -le 75 ]; then
          WIFI_ICON="$WIFI_ICON_RAMP_2"
        else 
          WIFI_ICON="$WIFI_ICON_RAMP_3"
        fi 

        printf "%s %b\n" "$WIFI_SSID" $WIFI_ICON ;;
      *)
        printf "%b\n" $WIFI_ICON_ON ;;
    esac ;; 
  *)
    printf "%b\n" $WIFI_ICON_OFF ;;
esac 
