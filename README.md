# Hermes Agent Custom Image

基于 `nousresearch/hermes-agent:latest` 的公开增强镜像，只增加通用工具、轻量桌面和远程访问组件；不覆盖 Hermes 上游的 ENTRYPOINT/CMD，不替换 s6-overlay，也不重装上游自带的 Node/npm 或 Playwright 运行架构。

## 主要内容

以下为本派生 Dockerfile 显式安装的软件和工具；基础镜像先用 `apt-get` 引导安装 `aptitude`，后续系统软件统一由 `aptitude` 安装并保留 Debian 推荐依赖，自动拉取的依赖不逐项展开。

- 办公与文档：`libreoffice`、`libreoffice-gtk3`、`libreoffice-l10n-zh-cn`、`pandoc`、`poppler-utils`、`ghostscript`
- 图像与媒体：`ffmpeg`、`imagemagick`、`sox`、`tesseract-ocr`、`tesseract-ocr-eng`、`tesseract-ocr-chi-sim`、`exiftool`
- 浏览器：`google-chrome-stable`、`firefox-esr`
- 桌面：`openbox`、`tint2`、`xfdesktop4`、`thunar`、`xfce4-helpers`、`xfce4-terminal`、`xfce4-appfinder`、`konqueror`、`lxtask`、`mousepad`、`lxterminal`、`xterm`
- RDP / VNC：`xrdp`、`xorgxrdp`、`xvfb`、`x11vnc`、`novnc`、`websockify`
- X11 与桌面控制：`xserver-xorg-core`、`xserver-xorg`、`xinit`、`xauth`、`x11-utils`、`x11-xserver-utils`、`dbus-x11`、`at-spi2-core`、`xdotool`、`wmctrl`、`scrot`、`xclip`
- 中文输入法：`fcitx5`、`fcitx5-chinese-addons`、`fcitx5-frontend-gtk3`、`fcitx5-frontend-qt5`、`fcitx5-frontend-qt6`、`im-config`
- 字体与图标：`fonts-noto`、`fonts-noto-cjk`、`fonts-noto-color-emoji`、`fonts-liberation`、`fonts-dejavu`、`fonts-wqy-zenhei`、`fonts-wqy-microhei`、`xfonts-base`、`xfonts-75dpi`、`fontconfig`、`adwaita-icon-theme`、`adwaita-icon-theme-legacy`、`breeze-icon-theme`、`lxde-icon-theme`
- 常用命令与文件工具：`aptitude`、`newsboat`、`vim`、`tmux`、`strace`、`lsof`、`rsync`、`tree`、`ncdu`、`zstd`、`psmisc`、`moreutils`、`inotify-tools`、`patch`、`less`、`pv`、`time`、`fzf`、`duf`、`dos2unix`、`bsdextrautils`、`gettext-base`、`bc`、`zip`、`unzip`、`p7zip-full`、`jq`、`aria2`、`file`
- 网络与系统工具：`curl`、`wget`、`git`、`procps`、`net-tools`、`iputils-ping`、`iproute2`、`iptables`、`dnsutils`、`socat`、`netcat-openbsd`、`whois`
- 加密与证书工具：`openssl`、`gnupg`
- 开发与底层依赖：`build-essential`、`pkg-config`、`libssl-dev`、`libffi-dev`、`libxml2-dev`、`libxslt1-dev`、`libjpeg-dev`、`libpng-dev`、`libwebp-dev`、`libmagic-dev`、`sqlite3`、`libsqlite3-dev`
- 桌面运行基础：`sudo`、`pulseaudio`、`desktop-file-utils`、`xdg-utils`、`xdg-user-dirs`、`libglib2.0-bin`、`menu`、`lxappearance`、`libgtk2.0-0t64`、`libayatana-appindicator3-1`、`libxcb-cursor0`、`qt5ct`、`qt6ct`
- 基础环境：`locales`、`ca-certificates`、`tzdata`

仓库中不保存任何固定远程桌面密码、Token、私钥、IP 或其他私有配置。

## 镜像与自动构建

GHCR：

```text
ghcr.io/newyorkthink/hermes-agent:latest
```

拉取：

```bash
docker pull ghcr.io/newyorkthink/hermes-agent:latest
```

GitHub Actions 只发布 `latest`，不上传 Docker Hub，不创建日期标签、提交 SHA 标签、Artifact 或 GitHub Release。

上游基础镜像：

```text
nousresearch/hermes-agent:latest
```

构建规则：

- 每 6 小时检查一次上游镜像 digest；未变化时跳过完整构建，发生变化时重新构建并覆盖 `latest`。
- `main` 分支的 `Dockerfile`、`docker/**`、`.dockerignore`、`.github/workflows/build.yml` 发生变化时自动构建。
- 支持 `workflow_dispatch` 手动触发。
- 构建时把实际使用的上游 digest 写入镜像元数据。
- workflow 使用并发队列，不主动取消正在运行的构建。

## 桌面环境

RDP 与 VNC 使用同一套轻量桌面结构：

```text
Openbox             窗口管理器
tint2               面板 / 任务栏
xfdesktop           桌面背景、桌面文件和特殊桌面图标
Application Finder  应用程序搜索与启动入口
Konqueror           主文件管理入口
Thunar              xfdesktop 的文件管理首选应用和桌面特殊图标打开程序
LXTask              轻量图形任务管理器
```

PCManFM 已移除，不再安装或启动。

Openbox 默认 `Super+E` 仍执行 `kfmclient openProfile filemanagement`，因此快捷键继续打开 Konqueror。Thunar 不替换该入口，只负责 xfdesktop 的“主文件夹 / 文件系统 / 回收站 / 设备”等桌面图标，以及 Xfce 首选文件管理器调用。

桌面右键由 xfdesktop 处理；“Open Terminal Here” 使用 Xfce `TerminalEmulator` 首选应用。首次生成用户配置时默认使用：

```text
FileManager=thunar
TerminalEmulator=xfce4-terminal
```

若 `/opt/data/.config/xfce4/helpers.rc` 已经存在其他终端选择，则不会覆盖；仅会把本镜像此前写入的 `debian-x-terminal-emulator` 默认值迁移为 `xfce4-terminal`。

### 应用程序启动器

镜像安装 `xfce4-appfinder`，用于读取系统和用户的 `.desktop` 文件，按分类显示、搜索并启动已安装的 GUI 程序。

首次进入 RDP 或 VNC 桌面会话时，会按 `xdg-user-dir DESKTOP` 返回的实际桌面目录创建一个“应用程序”启动器，来源为：

```text
/usr/share/applications/xfce4-appfinder.desktop
```

启动器使用可执行权限，并通过 `gio` 尝试写入 Xfce/Thunar 使用的 trusted 元数据。初始化标记保存为：

```text
/opt/data/.config/hermes/appfinder-launcher-v1
```

只初始化一次：已有同名桌面文件不会覆盖；初始化完成后，如果用户主动删除桌面上的启动器，也不会在每次登录时重新生成。

Application Finder 只会列出具有可见 `.desktop` 入口的程序；纯命令行工具、`NoDisplay=true` 或没有 `.desktop` 文件的程序不会因为安装了 Application Finder 就自动出现在列表中。

### 主题和图标

远程桌面会话默认使用：

```text
GTK_THEME=Adwaita:dark
```

Openbox 的系统默认窗口主题使用自带的 `Onyx` 深色主题；已有用户 Openbox 配置不会被覆盖。

深色界面与图标主题分开处理：默认图标主题仍为 `Adwaita`，并保留 `Adwaita Legacy`、`Breeze`、`LXDE` 图标资源。Openbox 自定义菜单优先使用全彩 `AdwaitaLegacy` PNG 图标，不把界面切成深色时顺带改成黑色 symbolic 图标。

若用户已在 `~/.config/gtk-3.0/settings.ini` 指定 `gtk-icon-theme-name`，启动脚本不会覆盖；只有未设置时才初始化：

```ini
[Settings]
gtk-icon-theme-name=Adwaita
```

### 持久化

桌面会话统一使用：

```text
HOME=/opt/data
LANG=zh_CN.UTF-8
LANGUAGE=zh_CN:zh
LC_ALL=zh_CN.UTF-8
```

浏览器、Fcitx5、Openbox、xfdesktop、tint2、Konqueror、Thunar 等用户配置都写入 `/opt/data`。运行容器时应把宿主机持久化目录挂载到 `/opt/data`。

xfdesktop 显示实际桌面目录中存在的文件、目录和启动器，并显示启用的特殊桌面图标；不会自动把所有已安装 GUI 程序复制到桌面。实际桌面目录由 `xdg-user-dir DESKTOP` 决定，中文环境下不应在脚本中写死为 `~/Desktop`。

## RDP

RDP 使用上游已有的 `hermes` 用户。密码只从运行时环境变量读取：

```text
RDP_PASSWORD
```

默认：

```text
RDP_BIND=0.0.0.0
RDP_PORT=3389
```

未设置 `RDP_PASSWORD` 时不会在镜像中预置密码。

RDP 使用 xorgxrdp 创建独立 Xorg 会话。xrdp 守护进程以 `xrdp` 用户运行，镜像将 `SessionSockdirGroup` 设为 `xrdp`，避免用户会话 socket 权限问题。

登录桌面后，剪贴板由 xrdp `chansrv/cliprdr` 提供并允许双向复制粘贴；xrdp 登录窗口本身出现于用户会话建立之前，因此密码框不能依赖 RDP 剪贴板。

### RDP 共享目录

xrdp 目录重定向通过 `chansrv + FUSE` 工作。需要客户端“共享目录”功能时，容器需要：

```yaml
cap_add:
  - SYS_ADMIN

devices:
  - /dev/fuse:/dev/fuse
```

Remmina 等客户端设置共享目录后，RDP 会话中从下面路径访问：

```text
/opt/data/thinclient_drives/
```

其下的共享名称由客户端生成。Konqueror 和 Thunar 都可以直接访问该路径。

## VNC / noVNC

VNC 密码：

```text
VNC_PASSWORD
```

未设置时 x11vnc 与 noVNC 不提供可连接的桌面会话，不回退到无密码模式。

默认：

```text
VNC_BIND=0.0.0.0
VNC_PORT=5900
NOVNC_BIND=0.0.0.0
NOVNC_PORT=6080
VNC_DISPLAY=:99
VNC_GEOMETRY=1920x1080
```

VNC 桌面运行在独立 Xvfb 会话，与 xrdp 创建的 Xorg RDP 会话不是同一个桌面。Xvfb 启动前会检查显示号并只在确认不可用时清理残留锁文件；x11vnc 同时使用 `-no6` 和 `-noipv6`，关闭编译时默认的 IPv6 listener 以及其他 IPv6 socket，避免在 host 网络模式下额外占用默认 VNC 端口。

可以关闭相应远程服务：

```text
RDP_ENABLE=0
VNC_ENABLE=0
```

监听地址设为 `127.0.0.1` 时只接受本机连接。在 `network_mode: host` 下无需额外 `ports:` 映射。

## 运行示例

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

需要 RDP 共享目录时额外增加：

```text
--cap-add=SYS_ADMIN --device=/dev/fuse:/dev/fuse
```

公网环境不要直接暴露远程桌面端口，优先通过防火墙、VPN 或可信内网限制访问范围。

## 常见问题

### 桌面只有主文件夹、文件系统、回收站等图标，没有已安装程序图标

这是 xfdesktop 的正常行为：它显示实际桌面目录中的文件/启动器和启用的特殊图标，不会把 `/usr/share/applications` 中所有 GUI 程序自动复制到桌面。

当前镜像提供 `xfce4-appfinder`，并在首次桌面会话创建一个“应用程序”启动器。打开它后可以按分类浏览或搜索具有 `.desktop` 入口的 GUI 程序。

### `xfce4-appfinder: not found`

说明当前运行的还是未包含 Application Finder 的旧镜像。新镜像构建完成并重新拉取、重新创建容器后，`xfce4-appfinder` 命令和 `/usr/share/applications/xfce4-appfinder.desktop` 应同时存在。

### xfdesktop 左上角“主文件夹 / 文件系统 / 共享设备”点了没反应

这些是 xfdesktop 的特殊桌面图标，需要可用的文件管理器首选应用。当前镜像安装 Thunar 和 `xfce4-helpers`，并在用户没有自定义值时初始化 `FileManager=thunar`。

### 桌面右键“Open Terminal Here”提示找不到 `TerminalEmulator`

当前镜像直接安装 `xfce4-terminal`，并把 Xfce `TerminalEmulator` 默认值设为：

```text
TerminalEmulator=xfce4-terminal
```

如果持久化配置中仍是本镜像此前写入的 `debian-x-terminal-emulator`，启动 RDP / VNC 会话时会自动迁移；其他用户自定义终端不会被覆盖。

### LibreOffice 界面只有英文

当前镜像安装 `libreoffice-l10n-zh-cn`，提供 LibreOffice 简体中文界面资源。桌面会话本身使用 `zh_CN.UTF-8`；已有 LibreOffice 用户配置仍保留，不强制覆盖用户手动选择的界面语言。

### `Super+E` 使用哪个文件管理器

仍然是 Konqueror。Thunar 只作为 xfdesktop/Xfce 桌面集成所需的首选文件管理器，不替换 Openbox 的 `Super+E` 行为。

### 为什么桌面右键不是 Openbox 菜单

xfdesktop 正在管理桌面背景和桌面图标，因此桌面右键由 xfdesktop 处理。Openbox 仍然是窗口管理器，tint2 仍然是面板。

### 深色主题为什么没有把图标也变黑

GTK 深色主题、Openbox 窗口主题和图标主题是分开的。当前配置只把 GTK 与 Openbox 外观设为深色，图标仍使用独立的 Adwaita / AdwaitaLegacy / Breeze / LXDE 资源；Openbox 菜单的固定分类图标使用全彩 AdwaitaLegacy PNG。

### RDP 共享目录存在但文件管理器没有快捷入口

挂载正常不代表会自动加入文件管理器侧栏。共享根目录始终从下面路径访问：

```text
/opt/data/thinclient_drives/
```

### `docker exec` 读取 `/opt/data/thinclient_drives` 提示权限不足

RDP 共享目录是 `hermes` 用户会话中的 FUSE 挂载。应以 RDP 会话内部能否正常进入共享目录并看到宿主机文件作为主要验证方式。

### Fcitx5 能选择拼音，但 GTK 程序不能输入中文

RDP 与 VNC 启动脚本显式设置：

```text
GTK_IM_MODULE=fcitx
QT_IM_MODULE=fcitx
XMODIFIERS=@im=fcitx
```

并启动 `fcitx5`。构建阶段还会检查 GTK3 输入模块、拼音模块、拼音配置和 Fcitx5 图标资源。

## 设计取舍与已处理问题

- 当前不是完整 Xfce 桌面。窗口管理器固定为 Openbox，面板固定为 tint2，只借用 `xfdesktop`、Thunar helper、`xfce4-terminal` 和 `xfce4-appfinder` 完成桌面集成；不引入 `xfce4-panel`，避免和 tint2 重复。
- 不使用 `nwg-drawer`。当前远程桌面是 X11/Openbox，而 `nwg-drawer` 面向 wlroots/Wayland；应用程序启动统一使用 `xfce4-appfinder`。
- PCManFM 已从桌面链路移除。Konqueror 保持主文件管理入口，Thunar 只承担 xfdesktop/Xfce helper 所需职责，避免多个文件管理器同时争用桌面管理角色。
- xfdesktop 接管根窗口后，桌面右键由 xfdesktop 处理，不应再把 Openbox 根菜单当作主要应用入口；Openbox 自定义应用菜单仍保留，Application Finder 作为更直接的图形启动入口。
- `HOME=/opt/data` 是 RDP/VNC 的统一持久化基线。启动脚本只初始化缺失值和迁移本镜像明确写入过的旧默认值，不覆盖已有用户选择。
- GTK 深色主题、Openbox 窗口主题和图标主题分离处理，避免深色界面把应用和菜单图标一起替换成难辨认的黑色 symbolic 图标。
- RDP 与 VNC 使用同一套桌面组件，但不是同一个显示会话：RDP 是 xorgxrdp 创建的 Xorg 会话，VNC 是独立 Xvfb `:99` 会话。
- x11vnc 之前仅使用 `-noipv6` 时仍可能出现额外 IPv6 listener；在 `network_mode: host` 下会直接占用宿主机端口。当前同时使用 `-no6` 和 `-noipv6`，避免默认 5900 与宿主机其他 VNC 服务冲突。
- `xdg-user-dirs` 负责桌面目录本地化，脚本通过 `xdg-user-dir DESKTOP` 获取实际路径，不写死英文 `~/Desktop`。
- 桌面启动器只做一次性初始化。这样既能给首次使用者一个可点击的应用入口，又不会在用户后续主动删除或自定义桌面后反复写回。

## 构建期验证

Dockerfile 在构建阶段检查以下关键链路，任一关键文件或命令缺失都会直接使构建失败：

- xrdp / Xorg / Xvfb / x11vnc / noVNC
- Openbox / tint2 / xfdesktop
- `xfce4-appfinder`、`xdg-user-dirs`、`gio`
- Thunar、Xfce FileManager helper、`xfce4-terminal`
- LibreOffice 简体中文语言包
- Konqueror / `kfmclient`
- LXTask
- Firefox / Chrome
- Fcitx5 GTK3 / 拼音组件和关键图标
- Openbox 深色主题和菜单图标资源

上游 Hermes 的 ENTRYPOINT/CMD 保持不变。
