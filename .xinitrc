pipewire &

# urxvt daemon mode
urxvtd -q -f -o &

# WM
exec dbus-launch --exit-with-session bspwm
