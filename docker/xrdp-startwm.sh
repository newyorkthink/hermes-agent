#!/bin/sh
set -eu

unset DBUS_SESSION_BUS_ADDRESS
unset SESSION_MANAGER

export HOME="${HOME:-/opt/data}"
export XDG_CURRENT_DESKTOP=OPENBOX
export XDG_SESSION_DESKTOP=openbox
export DESKTOP_SESSION=openbox

exec dbus-run-session -- sh -c '
    fcitx5 -d >/dev/null 2>&1 || true
    pcmanfm --desktop >/dev/null 2>&1 &
    xfce4-panel >/dev/null 2>&1 &
    exec openbox-session
'
