#!/bin/sh

case "$(bluetoothctl show | grep "Powered: yes" | wc -c)" in
  0)
    BLUETOOTH_ICON="%{F#cccccc}%{F-}" ;;
  *)
    case "$(echo info | bluetoothctl | grep 'Device' | wc -c)" in
      0)
        BLUETOOTH_ICON="" ;;
      *)
        BLUETOOTH_ICON="%{F#2193ff}%{F-}" ;;
    esac ;;
esac 

printf "%b\n" $BLUETOOTH_ICON
