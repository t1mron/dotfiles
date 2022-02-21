# recomended enviroment variables for sway based desktop
export MOZ_ENABLE_WAYLAND=1

export XDG_SESSION_TYPE=wayland
export XDG_CURRENT_DESKTOP=sway
export XDG_SESSION_DESKTOP=sway

export QT_QPA_PLATFORM=wayland-egl
export CLUTTER_BACKEND=wayland
export ECORE_EVAS_ENGINE=wayland-egl
export ELM_ENGINE=wayland_egl
export SDL_VIDEODRIVER=wayland
export _JAVA_AWT_WM_NONREPARENTING=1
export NO_AT_BRIDGE=1
export QT_QPA_PLATFORMTHEME=qt5ct

export LUTRIS_SKIP_INIT=1

# start wayland session with dbus support
if [ -z $DISPLAY ] && [ "$(tty)" = "/dev/tty1" ]; then
  exec dbus-run-session sway
fi

# get the aliases and functions
[ -f $HOME/.bashrc ] && . $HOME/.bashrc
