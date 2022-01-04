#!/bin/sh

if [ $( bspc config top_padding ) == 0 ]; then
  polybar-msg cmd show
	bspc config top_padding 18
else
	bspc config top_padding 0
	polybar-msg cmd hide
fi
