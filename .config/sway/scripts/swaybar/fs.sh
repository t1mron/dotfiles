#!/bin/sh

fs_icon=""
fs=$(df -h /dev/mapper/linux-home | awk '/[0-9]%/ {print $(NF-2)}')
