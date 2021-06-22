#! /bin/sh

case "$1" in
  hide) polybar-msg cmd hide | bspc config top_padding 0 ;;
  show) polybar-msg cmd show | bspc config top_padding 22 ;;
esac
