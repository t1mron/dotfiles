#!/bin/bash

if [[ $(pgrep -fc "$1") -eq 1 ]]; then
  if [[ ! $(pgrep -fc "$2") -eq 1 ]]; then
    swaymsg -q "[app_id=$2] focus"
  fi
else
  swaymsg -q "[app_id=$1] focus"
fi
