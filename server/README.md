# BareBrain Relay Server

这是 BareBrainAPP 的自建 WebSocket 中转服务。目标是让 BareBrain ESP32 直接连接云服务器，再由云服务器把 App 请求和板子主动消息转发给用户 App。

## 架构

```text
BareBrain ESP32  --wss/ws-->  relay_server.dart  <--wss/ws--  BareBrainAPP
```

当前 MVP 包含：

- `bin/relay_server.dart`：部署在云服务器上的 Relay，负责连接板子和 App。

## 协议

### 板子设备连接

板子连接：

```text
ws://<relay-host>:8080/ws/device?device_id=<id>&token=<device-token>
```

Relay 收到 App 请求后转发给板子：

```json
{"type":"request","request_id":"...","chat_id":"...","content":"..."}
```

板子返回：

```json
{"type":"response","request_id":"...","chat_id":"...","content":"..."}
```

板子主动发送消息：

```json
{"type":"incoming","chat_id":"barebrain_app","content":"稍后提醒内容"}
```

### App 连接

App 连接：

```text
ws://<relay-host>:8080/ws/app?device_id=<id>&token=<app-token>
```

App 发送：

```json
{"type":"message","request_id":"...","chat_id":"barebrain_app","content":"hello"}
```

App 接收：

```json
{"type":"response","request_id":"...","chat_id":"barebrain_app","content":"Hi!"}
```

App 也会接收 Relay 广播的板子主动消息：

```json
{"type":"response","chat_id":"barebrain_app","content":"稍后提醒内容"}
```

### 后台推送

手机退到后台、锁屏或被系统回收后，App 不能依赖 WebSocket 保活。Relay 收到板子主动消息时，可以额外调用一个推送 Webhook，再由该 Webhook 接入 FCM、APNs、华为/小米等厂商推送，或 Bark、ntfy 这类自建推送服务。

Relay 调用 Webhook：

```json
{
  "type": "incoming_message",
  "device_id": "home",
  "chat_id": "barebrain_app",
  "title": "BareBrain",
  "body": "稍后提醒内容",
  "content": "稍后提醒内容",
  "sent_at": "2026-06-29T12:00:00.000Z"
}
```

`PUSH_WEBHOOK_URL` 留空时不会发后台推送，只保留在线 WebSocket 广播。

## 本地运行

先复制环境文件：

```powershell
Copy-Item .\server\.env.example .\server\.env
```

启动 Relay：

```powershell
Set-Location .\server
dart run .\bin\relay_server.dart
```

默认配置：

- Relay 监听：`0.0.0.0:8080`
- 设备 ID：`home`
- 板子连接地址：`ws://<relay-host>:8080/ws/device?device_id=home&token=<device-token>`
- App 连接地址：`ws://<relay-host>:8080/ws/app?device_id=home&token=<app-token>`

## 环境变量

Relay：

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `RELAY_HOST` | `0.0.0.0` | 监听地址 |
| `RELAY_PORT` | `8080` | 监听端口 |
| `RELAY_DEVICE_ID` | `home` | 允许连接的设备 ID |
| `RELAY_DEVICE_TOKEN` | `change-device-token` | 板子设备 token |
| `RELAY_APP_TOKEN` | `change-app-token` | App token |
| `PUSH_WEBHOOK_URL` | 空 | 板子主动消息到达时调用的推送 Webhook |
| `PUSH_AUTH_HEADER` | `Authorization` | Webhook 鉴权 header 名 |
| `PUSH_AUTH_VALUE` | 空 | Webhook 鉴权 header 值，留空则不发送 |
| `PUSH_TIMEOUT_MS` | `8000` | 推送 Webhook 超时 |

## 部署建议

云服务器上建议用 Caddy 或 Nginx 终止 TLS，对外只开放 HTTPS/WSS：

```text
wss://relay.example.com/ws/app
wss://relay.example.com/ws/device
```

Relay 服务本身可以只监听 `127.0.0.1:8080`，由反向代理转发。不要把 ESP32 的 `18789` 端口映射到公网。
