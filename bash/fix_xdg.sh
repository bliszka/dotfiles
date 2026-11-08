#!/bin/env bash

# Helper function to bring back XDG when moving back from remote work via ssh to the wayland enviroment.
fix_xdg() {

  if [ -n "${WAYLAND_DISPLAY}" ]; then
    echo 'Display set. Exit'
    return 0
  fi

  XDG_RUNTIME_DIR="/run/user/$(id -u)"
  WAYLAND_DISPLAY="$(find "$XDG_RUNTIME_DIR" -maxdepth 1 -type s -name 'wayland-*' -printf '%f\n' 2>/dev/null | sort | head -1)"

  if [ -n "$TMUX" ]; then
    tmux setenv WAYLAND_DISPLAY "$WAYLAND_DISPLAY"
    tmux setenv XDG_RUNTIME_DIR "$XDG_RUNTIME_DIR"
    tmux setenv DBUS_SESSION_BUS_ADDRESS "unix:path=$XDG_RUNTIME_DIR/bus"
  fi
  export WAYLAND_DISPLAY="$WAYLAND_DISPLAY"
  export XDG_RUNTIME_DIR="$XDG_RUNTIME_DIR"
  export DBUS_SESSION_BUS_ADDRESS="unix:path=$XDG_RUNTIME_DIR/bus"
}
