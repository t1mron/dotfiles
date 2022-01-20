#!/bin/sh

COUNT="$(xbps-install -Mun 2> /dev/null | wc -l)"

if [ "$COUNT" -gt 0 ]; then
  printf " %b\n" "$COUNT"
fi
