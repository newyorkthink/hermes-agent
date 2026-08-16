# Hermes Agent Custom Image

基于 `nousresearch/hermes-agent:latest` 的公开增强镜像，只增加通用工具、桌面环境和远程访问组件，不修改 Hermes 上游的 ENTRYPOINT、CMD、s6-overlay、Node/npm 或 Playwright 运行架构。

## 主要内容

- 办公与文档：LibreOffice、Pandoc、Poppler、Ghostscript、python3-uno、python-docx、openpyxl
- 图像与媒体：FFmpeg、ImageMagick、SoX、Tesseract OCR
- 开发与诊断：Git、Vim、tmux、strace、常用 Python 库、构建工具
- 桌面：Openbox、XFCE Panel、PCManFM、Fcitx5、中文字体
- RDP：`xrdp + xorgxrdp`
- VNC：`Xvfb + x11vnc`
- Web VNC：`noVNC + websockify`
- 浏览器：Google Chrome

不包含 RealVNC Server，不保存 RealVNC `.deb`，也不在仓库中保存任何固定远程桌面密码、Token、私钥、IP 或其他私有配置。

## 镜像

GitHub Actions 只发布一个标签：

```text
ghcr.io/newyorkthink/hermes-agent:latest
```

不创建日期标签、提交 SHA 标签或 GitHub Release。

## RDP

RDP 使用 Hermes 上游自带的 `hermes` 用户，通过运行时环境变量设置密码：

```text
RDP_PASSWORD
```

默认端口：

```text
3389
```

未设置 `RDP_PASSWORD` 时不会在镜像中预置密码，`hermes` 用户保持原有密码状态。

RDP 使用 xorgxrdp 创建独立 Xorg 会话，桌面为 Openbox + XFCE Panel + PCManFM。

## VNC / noVNC

VNC 密码通过运行时环境变量设置：

```text
VNC_PASSWORD
```

未设置 `VNC_PASSWORD` 时，x11vnc 与 noVNC 不提供可连接的桌面会话，不会退回无密码模式。

默认端口：

```text
VNC:   5900
noVNC: 6080
```

VNC 桌面运行在独立的 Xvfb `:0` 会话中；它与 xrdp 创建的 Xorg RDP 会话不是同一个桌面。

可选分辨率：

```text
VNC_GEOMETRY=1920x1080
```

可通过下面两个变量关闭相应远程服务：

```text
RDP_ENABLE=0
VNC_ENABLE=0
```

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
