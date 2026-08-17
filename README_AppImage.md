# Hermes Desktop AppImage

## 核心使用流程

### 1. 下载 AppImage

```text
https://github.com/newyorkthink/hermes-agent/releases/tag/desktop-latest
```

当前文件名：

```text
Hermes-Desktop-linux-x86_64.AppImage
```

### 2. 生成 Dashboard Session Token

```bash
# 在 Linux 终端生成 Hermes Desktop 连接 Dashboard 使用的固定 Session Token
openssl rand -hex 32
```

### 3. 写入 Compose 项目外层 `.env`

把上一步输出写到 Compose 项目目录的外层 `.env`：

```dotenv
# Hermes Web Dashboard 开关、监听地址及端口
HERMES_DASHBOARD=1
HERMES_DASHBOARD_HOST=127.0.0.1
HERMES_DASHBOARD_PORT=9119

# Hermes Desktop 连接 Docker Dashboard 使用的固定会话令牌
HERMES_DASHBOARD_SESSION_TOKEN=这里填写上一步生成的值
```

`HERMES_DASHBOARD_SESSION_TOKEN` 只放在 Compose 项目外层 `.env`，不要重复写入 `./data/.env`。

### 4. `docker-compose.yml` 传入 Dashboard 配置

`environment:` 中保留：

```yaml
# 启用 Hermes Web Dashboard；监听地址和端口均可通过外层 .env 自定义
- HERMES_DASHBOARD=${HERMES_DASHBOARD:-1}
- HERMES_DASHBOARD_HOST=${HERMES_DASHBOARD_HOST:-127.0.0.1}
- HERMES_DASHBOARD_PORT=${HERMES_DASHBOARD_PORT:-9119}
- HERMES_DASHBOARD_SESSION_TOKEN=${HERMES_DASHBOARD_SESSION_TOKEN}
```

不要把 Session Token 的实际值直接写进 `docker-compose.yml`。

### 5. 让容器读取新增环境变量

在 Compose 项目目录执行：

```bash
# 重新创建现有服务以加载外层 .env 中新增的 Session Token
docker compose up -d
```

### 6. 启动 AppImage

```bash
# 在 Linux 终端启动 Hermes Desktop AppImage
./Hermes-Desktop-linux-x86_64.AppImage
```

### 7. Hermes Desktop 中填写

```text
Gateway URL: http://127.0.0.1:9119
Session token: 外层 .env 中的 HERMES_DASHBOARD_SESSION_TOKEN
```

先点 `Test connection`，连接成功后点 `Apply and reconnect`。

`9119` 对应 `HERMES_DASHBOARD_PORT`；如果外层 `.env` 修改过端口，Gateway URL 同步改为实际端口。

## 配置位置

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

## AppImage 兼容处理

AppImage 基于 `NousResearch/hermes-agent` 对应最新稳定 Release 的官方 Desktop 源码和 electron-builder 构建链生成，不是 Nous Research 官方签名或官方直接发布的二进制资产。

当前只补充 standalone Linux AppImage 所需兼容处理：

- 自动探测 KeePassXC Secret Service、GNOME Keyring 或 KWallet，并选择 Electron password-store。
- 内置 `libsecret-1.so.0`，修复检测到 Secret Service 但 Electron `safeStorage` 仍不可用的问题。
- Linux 中文 locale 自动映射到 Chromium `zh-CN`；Hermes 未显式设置 `display.language` 时使用官方简体中文界面。
- 发布前直接运行最终 AppImage，检查 `gnome_libsecret`、`safeStorage` 加密/解密往返和 `zh-CN` locale，检查失败不发布。

不会把 Gateway URL、Session Token、API Key、固定 IP 或个人当前端口写进 AppImage。

## Keyring / KeePassXC

Hermes Desktop 使用 Electron `safeStorage` 保存 Gateway Token。

AppImage 会自动探测：

```text
KeePassXC Secret Service
GNOME Keyring
KWallet
```

KeePassXC 使用时需要启用 Freedesktop.org Secret Service 集成并保持数据库可用。

终端启动时看到下面内容，表示已经选择 Secret Service 后端：

```text
[hermes] standalone AppImage detected password-store backend: gnome-libsecret
[hermes] using password-store backend: gnome-libsecret
```

## OpenAI-compatible API

Desktop Gateway 和 API Server 是两套入口：

```text
Desktop Gateway: http://127.0.0.1:9119
API Base URL:    http://127.0.0.1:8642/v1
```

`API_SERVER_KEY` 只保存在：

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

将 `<API_SERVER_KEY>` 替换为 `./data/.env` 中的实际 Key，将 `<MODEL_ID>` 替换为 `/v1/models` 返回的模型 ID。

## 自动构建与发布

```text
.github/workflows/desktop-appimage.yml
```

- 每天检查一次 `NousResearch/hermes-agent` 最新稳定 Release。
- 上游版本和 AppImage 构建修订没有变化时跳过完整构建。
- 只发布 `Hermes-Desktop-linux-x86_64.AppImage`。
- Release 固定使用 `desktop-latest`，标题固定为 `Hermes Desktop AppImage (latest)`。
- 不使用日期标题，不保存 Actions Artifact。
- 最终 AppImage 实际运行 smoke test 通过后才覆盖 `desktop-latest`。
