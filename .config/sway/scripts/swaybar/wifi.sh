#!/bin/sh

# In debina/devuan you can't use wifi-tools without the root access :( Check sudoers rules
# Requirements: iwd(iwctl),iw and siji ttf font

wifi_device="wlan0"
wifi_state="$(iwctl device "$wifi_device" show | awk '/Powered/ {print $4}')"
wifi_ssid="" # don't touch this variable

wifi_icon=""

if [ "$wifi_state" = "on" ]; then
  wifi_state="$(iwctl station "$wifi_device" show | awk '/State/ {print $2}')"
  
  if [ "$wifi_state" = "connected" ]; then
    wifi_ssid="$(iw dev "$wifi_device" link | awk '/SSID/ {print $2}')"
    wifi_signal="$(iw dev "$wifi_device" link | grep -oP 'signal:.*?\K[0-9]+')"

    if [ "$wifi_signal" -le 50 ]; then
      wifi_icon="" # 100% signal
    elif [ "$wifi_signal" -ge 51 ] && [ "$wifi_signal" -le 75 ]; then
      wifi_icon="" # 50-100% signal
    else 
      wifi_icon="" # 0-50% signal
    fi
  fi
else
  wifi_icon="<span foreground='red'>$wifi_icon</span>"
fi
