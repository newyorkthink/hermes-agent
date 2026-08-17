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

# 保持桌面使用 Openbox + tint2，文件管理器使用 Konqueror。
# 先初始化中文用户目录和 GTK 图标主题，再启动 Openbox；仅在用户未设置图标主题时默认使用 Adwaita，不覆盖现有主题设置。
exec dbus-run-session -- sh -c '
    command -v xdg-user-dirs-update >/dev/null 2>&1 && xdg-user-dirs-update >/dev/null 2>&1 || true

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

    tint2 &

    wait "$wm_pid"
'
