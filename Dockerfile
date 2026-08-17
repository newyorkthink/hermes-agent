FROM nousresearch/hermes-agent:latest

# 记录本次构建使用的上游镜像 digest，供定时任务判断上游是否已经更新。
ARG UPSTREAM_DIGEST=unknown
LABEL org.opencontainers.image.base.name="docker.io/nousresearch/hermes-agent:latest" \
      org.opencontainers.image.base.digest="${UPSTREAM_DIGEST}"

# 派生镜像只增加通用工具和远程桌面组件，不覆盖 Hermes 自带的 Node、npm、Playwright 与 s6-overlay。
USER root

# 先用基础镜像自带的 apt-get 引导安装 aptitude；后续系统软件统一由 aptitude 安装并保留 Debian 推荐依赖。
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends aptitude && \
    aptitude update && \
    DEBIAN_FRONTEND=noninteractive aptitude install -y \
        libreoffice libreoffice-gtk3 pandoc poppler-utils ghostscript \
        xvfb x11vnc novnc websockify xrdp xorgxrdp \
        xserver-xorg-core xserver-xorg xinit xauth x11-utils x11-xserver-utils \
        openbox tint2 konqueror mousepad lxterminal xterm firefox-esr \
        ffmpeg imagemagick sox \
        tesseract-ocr tesseract-ocr-eng tesseract-ocr-chi-sim \
        fonts-noto fonts-noto-cjk fonts-noto-color-emoji fonts-liberation fonts-dejavu \
        fonts-wqy-zenhei fonts-wqy-microhei xfonts-base xfonts-75dpi fontconfig \
        newsboat strace vim tmux lsof rsync tree ncdu zstd \
        psmisc moreutils inotify-tools netcat-openbsd patch less pv time fzf duf \
        dos2unix bsdextrautils gettext-base bc \
        curl wget git zip unzip p7zip-full jq aria2 \
        locales ca-certificates tzdata procps net-tools iputils-ping iproute2 iptables dnsutils socat whois \
        openssl gnupg \
        build-essential pkg-config libssl-dev libffi-dev libxml2-dev libxslt1-dev \
        libjpeg-dev libpng-dev libwebp-dev libmagic-dev file exiftool \
        sqlite3 libsqlite3-dev \
        sudo dbus-x11 at-spi2-core xdotool wmctrl scrot \
        fcitx5 fcitx5-chinese-addons fcitx5-frontend-gtk3 fcitx5-frontend-qt5 fcitx5-frontend-qt6 im-config \
        pulseaudio desktop-file-utils xdg-utils menu lxappearance \
        libgtk2.0-0t64 libayatana-appindicator3-1 adwaita-icon-theme adwaita-icon-theme-legacy breeze-icon-theme lxde-icon-theme \
        xclip libxcb-cursor0 qt5ct qt6ct && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/* /tmp/* /var/tmp/* /root/.cache/* && \
    (ln -sf /usr/share/applications/firefox-esr.desktop /usr/share/applications/firefox.desktop 2>/dev/null || true)

# 配置中文 UTF-8 环境；不创建额外的固定密码用户，RDP 直接使用上游 hermes 用户。
RUN sed -i '/zh_CN.UTF-8/s/^# //g' /etc/locale.gen && \
    locale-gen && \
    fc-cache -f && \
    (adduser xrdp ssl-cert >/dev/null 2>&1 || true)

# xrdp 在容器内以 xrdp 用户运行；sesman 必须把会话 socket 目录交给同组，否则会出现“Error connecting to user session”。
RUN sed -ri 's/^[[:space:]]*#[[:space:]]*SessionSockdirGroup=root[[:space:]]*$/SessionSockdirGroup=xrdp/' /etc/xrdp/sesman.ini && \
    grep -q '^SessionSockdirGroup=xrdp$' /etc/xrdp/sesman.ini && \
    grep -q '^RestrictOutboundClipboard=none$' /etc/xrdp/sesman.ini && \
    grep -q '^RestrictInboundClipboard=none$' /etc/xrdp/sesman.ini && \
    grep -q '^cliprdr=true$' /etc/xrdp/xrdp.ini

ENV GTK_IM_MODULE=fcitx \
    QT_IM_MODULE=fcitx \
    XMODIFIERS=@im=fcitx \
    LANG=zh_CN.UTF-8 \
    LANGUAGE=zh_CN:zh \
    LC_ALL=zh_CN.UTF-8

# 安装 Google Chrome；先解包本地 deb，再由 aptitude 统一补齐并配置依赖。
RUN wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb -O /tmp/chrome.deb && \
    (dpkg -i /tmp/chrome.deb || true) && \
    aptitude update && \
    DEBIAN_FRONTEND=noninteractive aptitude install -f -y && \
    rm -f /tmp/chrome.deb && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/*

# xrdp 使用标准 Xorg 会话；桌面保持 Openbox + tint2，文件管理器使用 Konqueror。
COPY --chmod=0755 docker/xrdp-startwm.sh /etc/xrdp/startwm.sh

# 在 Hermes 自带的 s6-overlay 中增加远程桌面初始化与监督服务。
COPY --chmod=0755 docker/cont-init.d/03-remote-desktop /etc/cont-init.d/03-remote-desktop
COPY docker/s6-rc.d/ /etc/s6-overlay/s6-rc.d/
RUN find /etc/s6-overlay/s6-rc.d -mindepth 2 -maxdepth 2 -name run -exec chmod 0755 {} +

# 仅声明 RDP、VNC、noVNC 的默认端口元数据；实际监听地址和端口由运行时变量及 Docker 网络模式决定。
EXPOSE 3389 5900 6080

# 构建期检查远程桌面、文件管理器、Fcitx5 中文输入链路和关键图标资源是否完整；不启动服务，不改写上游 ENTRYPOINT/CMD。
RUN command -v xrdp >/dev/null && \
    command -v xrdp-sesman >/dev/null && \
    command -v Xvfb >/dev/null && \
    command -v x11vnc >/dev/null && \
    command -v websockify >/dev/null && \
    command -v openbox >/dev/null && \
    command -v tint2 >/dev/null && \
    command -v konqueror >/dev/null && \
    command -v kfmclient >/dev/null && \
    command -v firefox-esr >/dev/null && \
    command -v google-chrome >/dev/null && \
    command -v fcitx5 >/dev/null && \
    command -v fcitx5-diagnose >/dev/null && \
    test -f /usr/lib/x86_64-linux-gnu/gtk-3.0/3.0.0/immodules/im-fcitx5.so && \
    test -f /usr/lib/x86_64-linux-gnu/fcitx5/libpinyin.so && \
    test -f /usr/share/fcitx5/inputmethod/pinyin.conf && \
    test -f /usr/share/icons/hicolor/16x16/apps/fcitx.png && \
    test -f /usr/share/icons/hicolor/16x16/apps/fcitx-pinyin.png && \
    test -f /etc/X11/xrdp/xorg.conf && \
    test -x /etc/xrdp/startwm.sh
