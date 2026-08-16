#!/bin/sh
set -eu

unset DBUS_SESSION_BUS_ADDRESS
unset SESSION_MANAGER

export HOME=/opt/data
export LANG=zh_CN.UTF-8
export LANGUAGE=zh_CN:zh
export LC_ALL=zh_CN.UTF-8
export GTK_THEME=Adwaita:dark
export XDG_CURRENT_DESKTOP=OPENBOX
export XDG_SESSION_DESKTOP=openbox
export DESKTOP_SESSION=openbox

# 保持轻量桌面，仅使用 Openbox + tint2 + PCManFM。
# 先初始化中文用户目录并启动 Openbox，确认窗口管理器就绪后再启动桌面和面板，避免 RDP 登录后只剩黑色根窗口。
exec dbus-run-session -- sh -c '
    command -v xdg-user-dirs-update >/dev/null 2>&1 && xdg-user-dirs-update >/dev/null 2>&1 || true
    fcitx5 -d >/dev/null 2>&1 || true

    openbox &
    wm_pid=$!

    i=0
    while ! wmctrl -m >/dev/null 2>&1; do
        i=$((i + 1))
        [ "$i" -ge 50 ] && break
        sleep 0.1
    done

    pcmanfm --desktop &
    tint2 &

    wait "$wm_pid"
'
