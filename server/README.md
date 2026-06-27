# BareBrain Relay Server

这是 BareBrainAPP 的自建 WebSocket 中转服务。目标是让自己的 App 在外网通过云服务器连接家里的 BareBrain，同时避免把 ESP32 的局域网端口直接暴露到公网。

## 架构

```text
BareBrain ESP32
  ws://<device-ip>:18789/
        ^
        | 局域网
        v
home_bridge.dart  --wss/ws-->  relay_server.dart  <--wss/ws--  BareBrainAPP
```

当前 MVP 包含两部分：

- `bin/relay_server.dart`：部署在云服务器上的 Relay。
- `bin/home_bridge.dart`：跑在家里电脑、NAS 或树莓派上的桥接程序，连接局域网 BareBrain 和云端 Relay。

## 协议

### 设备桥接连接

桥接程序连接：

```text
ws://<relay-host>:8080/ws/device?device_id=<id>&token=<device-token>
```

Relay 收到 App 请求后转发给桥接程序：

```json
{"type":"request","request_id":"...","chat_id":"...","content":"..."}
```

桥接程序返回：

```json
{"type":"response","request_id":"...","chat_id":"...","content":"..."}
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

启动家里桥接程序：

```powershell
Set-Location .\server
dart run .\bin\home_bridge.dart
```

默认配置：

- Relay 监听：`0.0.0.0:8080`
- 设备 ID：`home`
- Relay 地址：`ws://127.0.0.1:8080/ws/device`
- BareBrain 局域网地址：`ws://192.168.1.100:18789/`

## 环境变量

Relay：

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `RELAY_HOST` | `0.0.0.0` | 监听地址 |
| `RELAY_PORT` | `8080` | 监听端口 |
| `RELAY_DEVICE_ID` | `home` | 允许连接的设备 ID |
| `RELAY_DEVICE_TOKEN` | `change-device-token` | 设备桥接 token |
| `RELAY_APP_TOKEN` | `change-app-token` | App token |

桥接程序：

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `BRIDGE_RELAY_URL` | `ws://127.0.0.1:8080/ws/device` | Relay 设备端入口 |
| `BRIDGE_DEVICE_ID` | `home` | 设备 ID |
| `BRIDGE_DEVICE_TOKEN` | `change-device-token` | 设备 token |
| `BRIDGE_BAREBRAIN_URL` | `ws://192.168.1.100:18789/` | BareBrain 本地 WebSocket |
| `BRIDGE_RECONNECT_MS` | `3000` | 断线重连间隔 |
| `BRIDGE_TIMEOUT_MS` | `90000` | 单次 BareBrain 回复超时 |

## 部署建议

云服务器上建议用 Caddy 或 Nginx 终止 TLS，对外只开放 HTTPS/WSS：

```text
wss://relay.example.com/ws/app
wss://relay.example.com/ws/device
```

Relay 服务本身可以只监听 `127.0.0.1:8080`，由反向代理转发。不要把 ESP32 的 `18789` 端口映射到公网。
