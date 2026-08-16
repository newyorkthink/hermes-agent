FROM nousresearch/hermes-agent:latest

# 记录本次构建使用的上游镜像 digest，供定时任务判断上游是否已经更新。
ARG UPSTREAM_DIGEST=unknown
LABEL org.opencontainers.image.base.name="docker.io/nousresearch/hermes-agent:latest" \
      org.opencontainers.image.base.digest="${UPSTREAM_DIGEST}"

# 派生镜像只增加通用工具和远程桌面组件，不覆盖 Hermes 自带的 Node、npm、Playwright 与 s6-overlay。
USER root

# 安装办公、文档、图像、开发、桌面、RDP/VNC 与中文输入法组件。
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        aptitude \
        libreoffice pandoc poppler-utils ghostscript python3-uno \
        xvfb x11vnc novnc websockify xrdp xorgxrdp \
        xserver-xorg-core xserver-xorg xinit xauth x11-utils x11-xserver-utils \
        openbox tint2 pcmanfm mousepad lxterminal xterm firefox-esr \
        ffmpeg imagemagick sox \
        tesseract-ocr tesseract-ocr-eng tesseract-ocr-chi-sim \
        fonts-noto fonts-noto-cjk fonts-noto-color-emoji fonts-liberation fonts-dejavu \
        fonts-wqy-zenhei fonts-wqy-microhei xfonts-base xfonts-75dpi fontconfig \
        newsboat strace vim tmux \
        curl wget git zip unzip p7zip-full jq aria2 \
        locales ca-certificates tzdata procps net-tools iputils-ping iproute2 iptables dnsutils socat \
        default-jre-headless \
        build-essential libssl-dev libffi-dev libxml2-dev libxslt1-dev \
        libjpeg-dev libpng-dev libwebp-dev libmagic-dev file exiftool \
        sqlite3 libsqlite3-dev \
        python3-pip python3-dev python3-venv \
        python3-requests python3-httpx python3-aiohttp \
        python3-numpy python3-pandas python3-lxml python3-bs4 python3-yaml python3-regex \
        python3-pil python3-psutil python3-dateutil python3-click python3-rich python3-tqdm python3-tk \
        python3-docx python3-openpyxl python3-redis redis-server \
        sudo dbus-x11 xdotool wmctrl scrot \
        fcitx5 fcitx5-chinese-addons fcitx5-frontend-gtk3 fcitx5-frontend-qt5 im-config \
        pulseaudio desktop-file-utils xdg-utils menu lxappearance \
        libgtk2.0-0t64 keepassxc adwaita-icon-theme breeze-icon-theme \
        xclip libxcb-cursor0 qt5ct && \
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

# 安装 Google Chrome；仅下载到构建临时目录，不在仓库保存二进制安装包。
RUN wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb -O /tmp/chrome.deb && \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y /tmp/chrome.deb && \
    rm -f /tmp/chrome.deb && \
    rm -rf /var/lib/apt/lists/*

# xrdp 使用标准 Xorg 会话；桌面保持轻量 Openbox + tint2 + PCManFM。
COPY --chmod=0755 docker/xrdp-startwm.sh /etc/xrdp/startwm.sh

# 在 Hermes 自带的 s6-overlay 中增加远程桌面初始化与监督服务。
COPY --chmod=0755 docker/cont-init.d/03-remote-desktop /etc/cont-init.d/03-remote-desktop
COPY docker/s6-rc.d/ /etc/s6-overlay/s6-rc.d/
RUN find /etc/s6-overlay/s6-rc.d -mindepth 2 -maxdepth 2 -name run -exec chmod 0755 {} +

# RDP、原生 VNC 和浏览器 noVNC 端口；实际是否可访问仍取决于运行容器时是否发布端口。
EXPOSE 3389 5900 6080

# 构建期只检查关键程序是否存在；不启动服务，不改写上游 ENTRYPOINT/CMD。
RUN command -v xrdp >/dev/null && \
    command -v xrdp-sesman >/dev/null && \
    command -v Xvfb >/dev/null && \
    command -v x11vnc >/dev/null && \
    command -v websockify >/dev/null && \
    command -v openbox >/dev/null && \
    command -v tint2 >/dev/null && \
    test -f /etc/X11/xrdp/xorg.conf && \
    test -x /etc/xrdp/startwm.sh
