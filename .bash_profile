export MOZ_ENABLE_WAYLAND=1
export XDG_SESSION_TYPE=wayland
export QT_QPA_PLATFORM=wayland

export PATH="$PATH:$HOME/.local/bin"

# start wayland session with dbus support
if [ -z $DISPLAY ] && [ "$(tty)" = "/dev/tty1" ]; then
  exec dbus-run-session sway
fi

# get the aliases and functions
[ -f $HOME/.bashrc ] && . $HOME/.bashrc
