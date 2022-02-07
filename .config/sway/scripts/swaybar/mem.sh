#!/bin/sh

mem_icon=""
mem="$(free -h | awk '/Mem/ {print $3}')"
