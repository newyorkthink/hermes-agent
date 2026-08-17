#!/bin/sh
set -eu

unset DBUS_SESSION_BUS_ADDRESS
unset SESSION_MANAGER

export HOME=/opt/data
export LANG=zh_CN.UTF-8
export LANGUAGE=zh_CN:zh
export LC_ALL=zh_CN.UTF-8
export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
export XMODIFIERS=@im=fcitx
export XDG_CURRENT_DESKTOP=OPENBOX
export XDG_SESSION_DESKTOP=openbox
export DESKTOP_SESSION=openbox

# 窗口管理器使用 Openbox，面板使用 tint2，桌面层使用 xfdesktop，文件管理器使用 Konqueror。
# 先初始化中文用户目录、迁移未修改的默认 Openbox 菜单并初始化 GTK 图标主题，再启动桌面组件；不覆盖用户自定义菜单和主题设置。
exec dbus-run-session -- sh -c '
    command -v xdg-user-dirs-update >/dev/null 2>&1 && xdg-user-dirs-update >/dev/null 2>&1 || true

    # 仅迁移未修改的 Debian 默认 Openbox 菜单；用户自定义菜单保持原样。
    user_openbox_menu="$HOME/.config/openbox/menu.xml"
    stock_openbox_menu="/usr/local/share/hermes/openbox-menu.debian.xml"
    if [ -f "$user_openbox_menu" ] && [ -f "$stock_openbox_menu" ] && cmp -s "$user_openbox_menu" "$stock_openbox_menu"; then
        cp /etc/xdg/openbox/menu.xml "$user_openbox_menu"
    fi

    gtk_settings="$HOME/.config/gtk-3.0/settings.ini"
    mkdir -p "$HOME/.config/gtk-3.0"
    if [ ! -s "$gtk_settings" ]; then
        printf "%s\n" "[Settings]" "gtk-icon-theme-name=Adwaita" > "$gtk_settings"
    elif ! grep -q "^[[:space:]]*gtk-icon-theme-name[[:space:]]*=" "$gtk_settings"; then
        if grep -q "^\[Settings\][[:space:]]*$" "$gtk_settings"; then
            sed -i "/^\[Settings\][[:space:]]*$/a gtk-icon-theme-name=Adwaita" "$gtk_settings"
        else
            printf "%s\n" "" "[Settings]" "gtk-icon-theme-name=Adwaita" >> "$gtk_settings"
        fi
    fi

    fcitx5 -d >/dev/null 2>&1 || true

    openbox &
    wm_pid=$!

    i=0
    while ! wmctrl -m >/dev/null 2>&1; do
        i=$((i + 1))
        [ "$i" -ge 50 ] && break
        sleep 0.1
    done

    xfdesktop &
    tint2 &

    wait "$wm_pid"
'
