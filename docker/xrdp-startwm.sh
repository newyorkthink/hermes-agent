#!/bin/sh
set -eu

unset DBUS_SESSION_BUS_ADDRESS
unset SESSION_MANAGER

export HOME="${HOME:-/opt/data}"
export XDG_CURRENT_DESKTOP=OPENBOX
export XDG_SESSION_DESKTOP=openbox
export DESKTOP_SESSION=openbox

# xorgxrdp 会话默认使用软件渲染，避免容器内 /dev/dri 权限导致黑屏或 EGL 警告。
export LIBGL_ALWAYS_SOFTWARE=1
export GALLIUM_DRIVER=llvmpipe
export QT_XCB_FORCE_SOFTWARE_OPENGL=1
export QT_QUICK_BACKEND=software

exec dbus-run-session -- sh -c '
    fcitx5 -d >/dev/null 2>&1 || true
    pcmanfm --desktop >/dev/null 2>&1 &
    tint2 >/dev/null 2>&1 &
    exec openbox
'
