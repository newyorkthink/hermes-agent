# Hermes Desktop AppImage

本文件只记录 Hermes Desktop AppImage 的下载、启动、构建兼容处理，以及连接 Docker Hermes Gateway 所需的 Session Token 配置。Docker 镜像、RDP、VNC、noVNC 和完整远程桌面说明仍以主 `README.md` 为准。

## 下载与启动

Release 固定使用 `desktop-latest`，不在标题或文件名中加入日期：

```text
https://github.com/newyorkthink/hermes-agent/releases/tag/desktop-latest
```

当前发布文件名：

```text
Hermes-Desktop-linux-x86_64.AppImage
```

```bash
# 在 Linux 终端启动 Hermes Desktop AppImage
./Hermes-Desktop-linux-x86_64.AppImage
```

AppImage 基于 `NousResearch/hermes-agent` 对应最新稳定 Release 的官方 Desktop 源码和 electron-builder 构建链生成，不是 Nous Research 官方签名或官方直接发布的二进制资产。

## 当前 AppImage 兼容处理

上游 Desktop 功能保持不变，仅补充 standalone Linux AppImage 运行所需的兼容处理：

- 直接启动 AppImage 时自动探测 KeePassXC Secret Service、GNOME Keyring 或 KWallet，并选择 Electron password-store。
- AppImage 内置 `libsecret-1.so.0`，并为 Electron 主程序加入仅指向内置目录的 RUNPATH，避免宿主机只有 Secret Service 提供者但缺少 `libsecret` 客户端库时 `safeStorage` 不可用。
- Linux 中文 locale 自动映射到 Chromium `zh-CN`；Hermes 没有显式设置 `display.language` 时使用官方简体中文界面。
- 发布前直接运行最终 AppImage，实际检查 `gnome_libsecret`、`safeStorage` 加密/解密往返和 `zh-CN` locale；检查失败则不发布。

这些兼容处理不写入用户 Gateway URL、Token、API Key、固定 IP 或个人当前端口。

## 连接 Docker Hermes Gateway

Hermes Desktop 连接的是 Dashboard/Gateway 端口，不是 OpenAI-compatible API 端口。

默认关系：

```text
Hermes Desktop Gateway: http://127.0.0.1:9119
OpenAI-compatible API:  http://127.0.0.1:8642/v1
```

`9119` 对应 `HERMES_DASHBOARD_PORT`；`8642` 对应 `API_SERVER_PORT`。若外层 `.env` 修改过端口，实际地址以对应变量为准。

### 1. 生成固定 Session Token

```bash
# 在 Linux 终端生成 Hermes Desktop 连接 Dashboard 使用的固定 Session Token
openssl rand -hex 32
```

### 2. 写入 Compose 项目外层 `.env`

把上一步输出写到 Compose 项目目录的外层 `.env`，放在 Dashboard 配置下方：

```dotenv
# Hermes Web Dashboard 开关、监听地址及端口
HERMES_DASHBOARD=1
HERMES_DASHBOARD_HOST=127.0.0.1
HERMES_DASHBOARD_PORT=9119

# Hermes Desktop 连接 Docker Dashboard 使用的固定会话令牌
HERMES_DASHBOARD_SESSION_TOKEN=这里填写上一步生成的值
```

`HERMES_DASHBOARD_SESSION_TOKEN` 只放在 Compose 项目外层 `.env`。

不要把它重复写入：

```text
./data/.env
```

### 3. `docker-compose.yml` 传入 Dashboard 配置

`docker-compose.yml` 的 `environment:` 中保留：

```yaml
# 启用 Hermes Web Dashboard；监听地址和端口均可通过外层 .env 自定义
- HERMES_DASHBOARD=${HERMES_DASHBOARD:-1}
- HERMES_DASHBOARD_HOST=${HERMES_DASHBOARD_HOST:-127.0.0.1}
- HERMES_DASHBOARD_PORT=${HERMES_DASHBOARD_PORT:-9119}
- HERMES_DASHBOARD_SESSION_TOKEN=${HERMES_DASHBOARD_SESSION_TOKEN}
```

不要把 Session Token 的实际值直接写进 `docker-compose.yml`。

### 4. 让现有容器读取新增环境变量

在 Compose 项目目录执行：

```bash
# 重新创建现有服务以加载外层 .env 中新增的 Session Token
docker compose up -d
```

### 5. Hermes Desktop 中填写

同一台宿主机连接 Docker Hermes 时：

```text
Gateway URL: http://127.0.0.1:9119
Session token: 外层 .env 中的 HERMES_DASHBOARD_SESSION_TOKEN
```

先点 `Test connection`；显示连接成功后再点 `Apply and reconnect`。

若 `HERMES_DASHBOARD_HOST=127.0.0.1`，Gateway 只接受本机连接，不对局域网或公网开放。

## Keyring / KeePassXC

Hermes Desktop 使用 Electron `safeStorage` 保存远程 Gateway Token。

AppImage 会自动探测：

```text
KeePassXC Secret Service
GNOME Keyring
KWallet
```

KeePassXC 使用时，需要启用 Freedesktop.org Secret Service 集成并保持数据库可用。AppImage 已内置 `libsecret-1.so.0`，不需要为了这个 AppImage 单独把 `libsecret` 客户端库写死到系统路径。

终端启动时看到类似下面内容，表示已选择 Secret Service 后端：

```text
[hermes] standalone AppImage detected password-store backend: gnome-libsecret
[hermes] using password-store backend: gnome-libsecret
```

## OpenAI-compatible API

API Server 与 Hermes Desktop Gateway 是两套入口：

```text
Desktop Gateway: http://127.0.0.1:9119
API Base URL:    http://127.0.0.1:8642/v1
```

`API_SERVER_KEY` 不放在 Compose 项目外层 `.env`，只保存在 Hermes 持久化目录：

```text
./data/.env
```

生成 API Server Key：

```bash
# 在 Linux 终端生成 API Server Bearer Token
openssl rand -hex 32
```

写入 `./data/.env`：

```dotenv
# Hermes API Server Bearer Token
API_SERVER_KEY=这里填写上一步生成的值
```

Compose 只负责 API Server 的启用状态、监听地址和端口：

```yaml
# Hermes OpenAI-compatible API 服务
- API_SERVER_ENABLED=${API_SERVER_ENABLED:-true}
- API_SERVER_HOST=${API_SERVER_HOST:-127.0.0.1}
- API_SERVER_PORT=${API_SERVER_PORT:-8642}
```

不要在 `docker-compose.yml` 中增加：

```yaml
- API_SERVER_KEY=${API_SERVER_KEY}
```

OpenAI-compatible 客户端填写：

```text
Base URL: http://127.0.0.1:8642/v1
API Key: ./data/.env 中的 API_SERVER_KEY
Model: 通过 GET /v1/models 获取返回的模型 ID
```

```bash
# 在 Linux 终端查询 Hermes API Server 暴露的模型 ID
curl http://127.0.0.1:8642/v1/models \
  -H 'Authorization: Bearer <API_SERVER_KEY>'
```

```bash
# 在 Linux 终端调用 Hermes OpenAI Chat Completions API
curl http://127.0.0.1:8642/v1/chat/completions \
  -H 'Authorization: Bearer <API_SERVER_KEY>' \
  -H 'Content-Type: application/json' \
  -d '{"model":"<MODEL_ID>","messages":[{"role":"user","content":"你好"}],"stream":false}'
```

将 `<API_SERVER_KEY>` 替换为 `./data/.env` 中的实际 Key，将 `<MODEL_ID>` 替换为 `/v1/models` 返回的模型 ID。若修改了 `API_SERVER_PORT`，同时替换 URL 中的端口。

## 配置位置总结

```text
Compose 项目外层 .env
├── HERMES_DASHBOARD
├── HERMES_DASHBOARD_HOST
├── HERMES_DASHBOARD_PORT
└── HERMES_DASHBOARD_SESSION_TOKEN

./data/.env
└── API_SERVER_KEY

docker-compose.yml
├── 传入 Dashboard 开关、地址、端口和 Session Token
└── 传入 API Server 开关、地址和端口；不传 API_SERVER_KEY
```

Session Token 与 API Key 不要重复维护在两个 `.env` 中。

## 自动构建与发布

AppImage workflow：

```text
.github/workflows/desktop-appimage.yml
```

发布规则：

- 每天检查一次 `NousResearch/hermes-agent` 最新稳定 Release。
- 上游版本和 AppImage 构建修订都没有变化时跳过完整构建。
- 仅发布 `Hermes-Desktop-linux-x86_64.AppImage`。
- Release 固定使用 `desktop-latest`，标题固定为 `Hermes Desktop AppImage (latest)`。
- 不使用日期标题，不保存 Actions Artifact。
- AppImage 实际运行 smoke test 通过后才覆盖 `desktop-latest`。
