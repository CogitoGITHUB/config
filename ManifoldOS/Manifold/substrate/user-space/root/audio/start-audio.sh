#!/bin/sh
# Start audio daemons in user session
# Add this to your shell profile (~/.bashrc, ~/.zshrc, or nushell config)
# Or run manually: ~/.config/guix/Operating-System/core-system/user-space/root/audio/start-audio.sh

if ! pgrep -x wireplumber > /dev/null; then
  # Start dbus session if not running
  if [ ! -S "$XDG_RUNTIME_DIR/bus" ]; then
    dbus-daemon --nofork --session --address=unix:path=$XDG_RUNTIME_DIR/bus &
    sleep 1
  fi
  # Start pipewire
  pipewire &
  sleep 2
  # Start wireplumber (needs dbus session)
  DBUS_SESSION_BUS_ADDRESS=unix:path=$XDG_RUNTIME_DIR/bus wireplumber &
fi
