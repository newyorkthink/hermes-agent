# Hermes Agent Custom Image

基于 `nousresearch/hermes-agent:latest` 的公开增强镜像，只增加通用工具、轻量桌面和远程访问组件；不覆盖 Hermes 上游的 ENTRYPOINT/CMD，不替换 s6-overlay，也不重装上游自带的 Node/npm 或 Playwright 运行架构。

## 主要内容

以下为本派生 Dockerfile 显式安装的软件和工具；基础镜像先用 `apt-get` 引导安装 `aptitude`，后续系统软件统一由 `aptitude` 安装并保留 Debian 推荐依赖，自动拉取的依赖不逐项展开。

- 办公与文档：`libreoffice`、`libreoffice-gtk3`、`pandoc`、`poppler-utils`、`ghostscript`
- 图像与媒体：`ffmpeg`、`imagemagick`、`sox`、`tesseract-ocr`、`tesseract-ocr-eng`、`tesseract-ocr-chi-sim`、`exiftool`
- 浏览器：`google-chrome-stable`、`firefox-esr`
- 轻量桌面：`openbox`、`tint2`、`pcmanfm`、`mousepad`、`lxterminal`、`xterm`
- RDP / VNC：`xrdp`、`xorgxrdp`、`xvfb`、`x11vnc`、`novnc`、`websockify`
- X11 与桌面控制：`xserver-xorg-core`、`xserver-xorg`、`xinit`、`xauth`、`x11-utils`、`x11-xserver-utils`、`dbus-x11`、`at-spi2-core`、`xdotool`、`wmctrl`、`scrot`、`xclip`
- 中文输入法：`fcitx5`、`fcitx5-chinese-addons`、`fcitx5-frontend-gtk3`、`fcitx5-frontend-qt5`、`fcitx5-frontend-qt6`、`im-config`
- 字体与主题：`fonts-noto`、`fonts-noto-cjk`、`fonts-noto-color-emoji`、`fonts-liberation`、`fonts-dejavu`、`fonts-wqy-zenhei`、`fonts-wqy-microhei`、`xfonts-base`、`xfonts-75dpi`、`fontconfig`、`adwaita-icon-theme`、`breeze-icon-theme`、`lxde-icon-theme`
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

## 桌面环境与持久化

RDP 与 VNC 桌面都固定使用轻量 `Openbox + tint2 + PCManFM`，并统一使用：

```text
HOME=/opt/data
LANG=zh_CN.UTF-8
LANGUAGE=zh_CN:zh
LC_ALL=zh_CN.UTF-8
```

桌面启动脚本不固定 GTK 明暗主题，主题按用户自己的桌面配置生效。若用户尚未在 `~/.config/gtk-3.0/settings.ini` 中设置 `gtk-icon-theme-name`，首次桌面会话会默认写入 `Adwaita` 图标主题；已有图标主题设置不会被覆盖。桌面会话启动时还会执行 `xdg-user-dirs-update` 初始化用户目录，并启动 Fcitx5。浏览器、Fcitx5、Openbox、tint2、PCManFM 等用户配置都会写入 `/opt/data`；运行容器时应把宿主机持久化目录挂载到 `/opt/data`，这样重启、删除并重建容器或更新镜像时仍可保留 Firefox、Chrome 和桌面配置。

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

### RDP 共享目录

xrdp 的目录重定向通过 `chansrv + FUSE` 工作。只有需要使用 RDP 客户端“共享目录”功能时，才需要给容器增加：

```yaml
cap_add:
  - SYS_ADMIN

devices:
  - /dev/fuse:/dev/fuse
```

`SYS_ADMIN` 权限范围较大，不使用 RDP 共享目录时不需要添加。

在 Remmina 等客户端的“共享目录”中填写宿主机需要共享的绝对路径后，进入 RDP 会话可从下面的位置访问：

```text
/opt/data/thinclient_drives/
```

其下会出现由客户端生成的共享名称。PCManFM 不一定自动把 xrdp 的 FUSE 共享目录加入左侧“位置”栏；首次进入对应共享目录后，可通过“书签”将当前目录加入左侧栏，之后直接从左侧访问。

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

x11vnc 显式禁用 IPv6 监听，避免在只希望通过 IPv4 回环地址访问时额外出现 IPv6 监听端口。

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

密码只在运行容器时自行设置，不要写入仓库。下面示例同时把 `/opt/data` 持久化到宿主机当前目录下的 `data`：

```bash
docker run -d \
  --name hermes-agent \
  -e RDP_PASSWORD='自行设置强密码' \
  -e VNC_PASSWORD='自行设置强密码' \
  -v "$(pwd)/data:/opt/data" \
  -p 3389:3389 \
  -p 5900:5900 \
  -p 6080:6080 \
  ghcr.io/newyorkthink/hermes-agent:latest
```

如果需要 RDP 共享目录，再额外增加 `--cap-add=SYS_ADMIN --device=/dev/fuse:/dev/fuse`；普通远程桌面连接不需要这两个权限。

公网环境不要直接暴露远程桌面端口，优先通过防火墙、VPN 或可信内网限制访问范围。

## 常见问题

### RDP 共享目录已经存在，但 PCManFM 左侧没有显示

这是 PCManFM 左侧栏没有自动加入 xrdp FUSE 共享目录，不代表挂载失败。先打开 `/opt/data/thinclient_drives/` 下实际出现的共享目录，再通过“书签”把当前目录加入左侧栏即可。

### `docker exec` 查看 `/opt/data/thinclient_drives` 提示权限不足

RDP 共享目录是 `hermes` 用户会话中的 FUSE 挂载；从容器外通过 `docker exec` 以其他用户直接读取时可能出现权限不足。应以 RDP 会话内能否正常进入共享目录并看到宿主机文件作为主要验证方式。

### Fcitx5 的“Configure”打开配置目录而不是图形配置工具

旧镜像在缺少 Fcitx5 图形配置组件时可能出现这种情况。当前镜像使用 `aptitude` 保留 Debian 推荐依赖，会自动补齐 Fcitx5 推荐的图形配置和桌面集成组件；更新到最新镜像并重建容器即可。

### PCManFM / tint2 部分图标空白或颜色异常

当前镜像安装 `Adwaita`、`Breeze` 和 `LXDE` 图标资源。若 GTK3 用户配置中没有指定图标主题，桌面启动时默认初始化 `gtk-icon-theme-name=Adwaita`，避免 PCManFM 等程序在没有明确图标主题时出现缺图标；该设置不会固定 GTK 明暗主题，也不会覆盖用户已经选择的图标主题。

Fcitx5 托盘右键菜单中的“配置”“重新启动”“退出”等文字项本身由 Fcitx5 上游 X11 托盘菜单实现，未为这些菜单项设置图标，因此没有菜单图标不代表缺包或图标主题损坏。
