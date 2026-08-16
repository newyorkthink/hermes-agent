# Hermes Agent Custom Image

基于 `nousresearch/hermes-agent:latest` 的公开增强镜像，只增加通用工具、轻量桌面和远程访问组件；不覆盖 Hermes 上游的 ENTRYPOINT/CMD，不替换 s6-overlay，也不重装上游自带的 Node/npm 或 Playwright 运行架构。

## 主要内容

以下为本派生 Dockerfile 显式安装的软件和工具；APT 自动拉取的依赖不逐项展开。

- 办公与文档：`libreoffice`、`libreoffice-gtk3`、`pandoc`、`poppler-utils`、`ghostscript`
- 图像与媒体：`ffmpeg`、`imagemagick`、`sox`、`tesseract-ocr`、`tesseract-ocr-eng`、`tesseract-ocr-chi-sim`、`exiftool`
- 浏览器：`google-chrome-stable`、`firefox-esr`
- 轻量桌面：`openbox`、`tint2`、`pcmanfm`、`mousepad`、`lxterminal`、`xterm`
- RDP / VNC：`xrdp`、`xorgxrdp`、`xvfb`、`x11vnc`、`novnc`、`websockify`
- X11 与桌面控制：`xserver-xorg-core`、`xserver-xorg`、`xinit`、`xauth`、`x11-utils`、`x11-xserver-utils`、`dbus-x11`、`xdotool`、`wmctrl`、`scrot`、`xclip`
- 中文输入法：`fcitx5`、`fcitx5-chinese-addons`、`fcitx5-frontend-gtk3`、`fcitx5-frontend-qt5`、`fcitx5-frontend-qt6`、`im-config`
- 字体与主题：`fonts-noto`、`fonts-noto-cjk`、`fonts-noto-color-emoji`、`fonts-liberation`、`fonts-dejavu`、`fonts-wqy-zenhei`、`fonts-wqy-microhei`、`xfonts-base`、`xfonts-75dpi`、`fontconfig`、`adwaita-icon-theme`、`breeze-icon-theme`
- 常用命令与文件工具：`aptitude`、`newsboat`、`vim`、`tmux`、`strace`、`lsof`、`rsync`、`tree`、`ncdu`、`zstd`、`psmisc`、`moreutils`、`inotify-tools`、`patch`、`less`、`pv`、`time`、`fzf`、`duf`、`dos2unix`、`bsdextrautils`、`gettext-base`、`bc`、`zip`、`unzip`、`p7zip-full`、`jq`、`aria2`、`file`
- 网络与系统工具：`curl`、`wget`、`git`、`procps`、`net-tools`、`iputils-ping`、`iproute2`、`iptables`、`dnsutils`、`socat`、`netcat-openbsd`、`whois`
- 加密与证书工具：`openssl`、`gnupg`
- 开发与底层依赖：`build-essential`、`pkg-config`、`libssl-dev`、`libffi-dev`、`libxml2-dev`、`libxslt1-dev`、`libjpeg-dev`、`libpng-dev`、`libwebp-dev`、`libmagic-dev`、`sqlite3`、`libsqlite3-dev`
- 桌面与运行基础：`sudo`、`pulseaudio`、`desktop-file-utils`、`xdg-utils`、`menu`、`lxappearance`、`libgtk2.0-0t64`、`libayatana-appindicator3-1`、`libxcb-cursor0`、`qt5ct`、`qt6ct`
- 基础环境：`locales`、`ca-certificates`、`tzdata`

仓库中不保存任何固定远程桌面密码、Token、私钥、IP 或其他私有配置。

## 镜像

GHCR 镜像地址：

```text
ghcr.io/newyorkthink/hermes-agent:latest
```

拉取最新镜像：

```bash
docker pull ghcr.io/newyorkthink/hermes-agent:latest
```

GitHub Actions 只发布 `latest`，不上传 Docker Hub，不创建日期标签、提交 SHA 标签或 GitHub Release。

## 自动跟踪上游

上游基础镜像：

```text
nousresearch/hermes-agent:latest
```

GitHub Actions 每 6 小时检查一次上游镜像 digest：

- 上游 digest 没有变化：直接结束，不执行完整 Docker 构建。
- 上游 digest 发生变化：自动重新构建并覆盖 `ghcr.io/newyorkthink/hermes-agent:latest`。
- 本仓库 Dockerfile、远程桌面配置或 workflow 发生变化时：立即重新构建 `latest`。
- 也可以通过 `workflow_dispatch` 手动触发构建。

构建时会把实际使用的上游 digest 写入镜像元数据，用于下一次自动检查，不需要保存日期版本或额外状态文件。

## RDP

RDP 使用 Hermes 上游自带的 `hermes` 用户，通过运行时环境变量设置密码：

```text
RDP_PASSWORD
```

默认监听地址和端口，可通过运行时环境变量覆盖：

```text
RDP_BIND=0.0.0.0
RDP_PORT=3389
```

未设置 `RDP_PASSWORD` 时不会在镜像中预置密码，`hermes` 用户保持原有密码状态。

RDP 使用 xorgxrdp 创建独立 Xorg 会话，桌面固定为轻量 `Openbox + tint2 + PCManFM`。xrdp 守护进程以 `xrdp` 用户运行，因此镜像将 `SessionSockdirGroup` 设为 `xrdp`，避免会话已经创建但主 xrdp 进程无法访问 session socket 而出现 `Error connecting to user session`。

RDP 登录成功进入用户会话后，剪贴板由 xrdp 的 `chansrv/cliprdr` 提供，配置允许双向剪贴板。xrdp 自身的登录窗口出现在用户会话和 `chansrv` 建立之前，因此登录窗口的密码框不能依赖 RDP 剪贴板粘贴；进入桌面后的普通文本复制粘贴不受此限制。

## VNC / noVNC

VNC 密码通过运行时环境变量设置：

```text
VNC_PASSWORD
```

未设置 `VNC_PASSWORD` 时，x11vnc 与 noVNC 不提供可连接的桌面会话，不会退回无密码模式。

默认监听地址和端口，可通过运行时环境变量覆盖：

```text
VNC_BIND=0.0.0.0
VNC_PORT=5900
NOVNC_BIND=0.0.0.0
NOVNC_PORT=6080
```

VNC 桌面默认运行在独立的 Xvfb `:99` 会话中，桌面同样使用轻量 `Openbox + tint2 + PCManFM`；它与 xrdp 创建的 Xorg RDP 会话不是同一个桌面。为避免 X Server 显示号冲突，VNC 服务会在启动前检查显示是否已存在，并只在显示不可用时清理残留锁文件。

可选设置：

```text
VNC_DISPLAY=:99
VNC_GEOMETRY=1920x1080
```

可通过下面两个变量关闭相应远程服务：

```text
RDP_ENABLE=0
VNC_ENABLE=0
```

监听地址设为 `127.0.0.1` 时只接受本机连接；在 `network_mode: host` 下可直接用于限制宿主机回环访问。使用 Docker bridge 网络并通过 `-p` 发布端口时，通常应保留容器内监听 `0.0.0.0`，再通过宿主机端口发布地址或防火墙限制访问范围。

## 运行示例

密码只在运行容器时自行设置，不要写入仓库：

```bash
docker run -d \
  --name hermes-agent \
  -e RDP_PASSWORD='自行设置强密码' \
  -e VNC_PASSWORD='自行设置强密码' \
  -p 3389:3389 \
  -p 5900:5900 \
  -p 6080:6080 \
  ghcr.io/newyorkthink/hermes-agent:latest
```

公网环境不要直接暴露远程桌面端口，优先通过防火墙、VPN 或可信内网限制访问范围。
