# BareBrainAPP

BareBrainAPP 是面向 BareBrain 的 Flutter 局域网聊天客户端。应用默认通过 BareBrain 固件自带的本地 WebSocket 网关通信，也支持连接自建云端 WebSocket Relay。

发送聊天消息时，应用会等待 BareBrain 返回完整回复后再展示；聊天页打开期间也会保持接收通道，用于显示板子主动推送的消息。

项目内的 `server/` 目录提供自建 WebSocket Relay MVP。BareBrain 设备可以直接连接云服务器，BareBrainAPP 再连接同一个 Relay，由 Relay 转发 App 请求和板子主动消息，不需要走飞书/Lark。

本项目不会修改 `E:\code\BareBrain`。

## 目录

- [功能概览](#功能概览)
- [项目结构](#项目结构)
- [连接协议](#连接协议)
- [客户端配置](#客户端配置)
- [BareBrain 板子配置](#barebrain-板子配置)
- [Relay 服务端配置](#relay-服务端配置)
- [数据与备份](#数据与备份)
- [排障建议](#排障建议)
- [开发约束](#开发约束)

## 功能概览

- 局域网 WebSocket 非流式发送，并支持接收板子主动推送消息。
- 云端 Relay 连接模式，可连接自建 `server/bin/relay_server.dart`。
- Relay 可配置推送 Webhook，用于把板子主动消息转给 FCM/APNs/厂商推送、Bark、ntfy 等后台通知服务。
- 连接设置支持直接粘贴 `ws://<设备IP>:18789/`，保存时会归一化为主机名、端口和安全连接标记。
- 连接设置支持切换“直连 / Relay”，Relay 模式会保存服务器地址、设备 ID、App Token 和 App 路径。
- 连接设置支持测试 BareBrain WebSocket 握手，不发送聊天内容。
- 默认会话沿用客户端 ID 作为 `chat_id`，新建会话会派生稳定短 `chat_id`，避免 BareBrain 设备侧会话历史串在一起。
- 宽屏侧边栏和窄屏抽屉会显示会话摘要，并支持新建、切换、重命名和删除非当前会话。
- 默认标题的会话会在首条用户消息发送后自动用消息内容命名；手动重命名或创建时指定标题的会话不会被覆盖。
- 每条消息会显示本地时间，支持一键复制；发送失败后可以重试最后一条用户消息。
- 输入框草稿会按会话保存，切换会话后再回来不会丢失未发送内容。
- 快捷短语、指令注入、网络代理、存储空间、备份与恢复、OTA 参数和显示设置均已接入设置页。
- 聊天框左下角快捷列表支持 BareBrain 板子设置；读写配置走设备 admin HTTP 接口，不会发送给聊天模型。
- 设置页“项目文档”采用分页式阅读，覆盖连接、板子设置、聊天增强、显示交互、网络 OTA、数据备份等内容。

## 项目结构

```text
lib/src/app/                         App 外壳、主题和默认配置
lib/src/core/                        共享错误类型
lib/src/features/chat/chat_feature_module.dart 聊天功能依赖装配入口
lib/src/features/chat/domain/        聊天实体、仓库接口、服务和用例
lib/src/features/chat/data/          WebSocket、HTTP、Key-Value 和协议适配
lib/src/features/chat/presentation/  控制器、页面、设置页和 Flutter UI
server/                              自建云端 Relay 服务端
assets/branding/                     应用图标和品牌素材
```

## 连接协议

BareBrain 局域网网关地址：

```text
ws://<BareBrain device IP>:18789/
```

发送消息：

```json
{"type":"message","content":"hello","chat_id":"barebrain_app"}
```

接收回复或板子主动消息：

```json
{"type":"response","content":"Hi!","chat_id":"barebrain_app"}
```

聊天页会等待匹配 `chat_id` 的完整 `response`。页面保持打开时，也会接收匹配 `chat_id` 的主动 `response`、`message` 或 `event`。

## 客户端配置

### 默认编译配置

默认连接参数定义在 `lib/src/app/app_config.dart`，可通过 Dart `--dart-define` 覆盖：

| 配置 | 默认值 | 说明 |
|------|--------|------|
| `BAREBRAIN_HOST` | `192.168.1.100` | BareBrain 设备默认 IP 或主机名 |
| `BAREBRAIN_PORT` | `18789` | BareBrain WebSocket 端口 |
| `BAREBRAIN_CLIENT_ID` | `barebrain_app` | 默认客户端 ID / `chat_id` 前缀 |

运行时保存后的连接参数会覆盖这些默认值。

### 连接参数

入口：`设置` -> `设备连接` -> `连接参数`。

| 字段 | 适用模式 | 默认值 | 规则与影响 |
|------|----------|--------|------------|
| 连接模式 | 全部 | `局域网直连` | 可选“直连”或“Relay” |
| 设备 IP / Relay 域名或 IP | 全部 | `BAREBRAIN_HOST` | 只填写 IP 或主机名；也可粘贴 `ws://` 或 `wss://` 地址，由应用自动拆分 |
| 端口 | 全部 | 直连 `18789`，Relay 按 WSS 推断 `443` 或 `80` | 必须在 `1` 到 `65535` 之间 |
| 超时秒数 | 全部 | `90` | 聊天响应等待时间，允许 `5` 到 `300` 秒 |
| 客户端 ID / chat_id 前缀 | 全部 | `BAREBRAIN_CLIENT_ID` | 不能为空，最长 31 个字符，只能包含字母、数字、下划线、点和短横线 |
| WSS | 全部 | 关闭 | 开启后使用 `wss://` 加密 WebSocket |
| Relay 设备 ID | Relay | `home` | 不能为空，最长 64 个字符，只能包含字母、数字、下划线、点和短横线 |
| App Token | Relay | 空 | 不能为空，不能包含空白字符，最长 512 个字符 |
| Relay App 路径 | Relay | `/ws/app` | 必须以 `/` 开头，不能包含空白、查询或片段 |

连接测试只验证 WebSocket 握手，不会发送聊天内容。直连失败时，优先确认 App 与 BareBrain 位于同一局域网、设备端口开放、WSS 开关与设备服务一致。Relay 失败时，同时检查设备是否已连接 Relay、设备 ID 和 Token 是否一致。

### 显示设置

入口：`设置` -> `通用设置` -> `显示设置`。

| 配置 | 可选值 / 范围 | 说明 |
|------|---------------|------|
| 颜色模式 | 跟随系统、浅色、深色 | 控制应用明暗模式 |
| 主题预设 | 黑白灰、默认主题、Claude 风格、自然风格、未来科技、柔和渐变、海洋、日落、肉桂板岩、地平线绿、樱桃编码 | 控制设置页、聊天页和消息气泡视觉风格 |
| 消息头像 | 开 / 关 | 是否显示消息头像 |
| 作者名 | 开 / 关 | 是否显示消息作者名称 |
| 消息时间 | 开 / 关 | 是否显示本地消息时间 |
| 消息操作 | 开 / 关 | 是否显示复制等消息操作按钮 |
| 消息文本选择 | 开 / 关 | 是否允许选择消息正文 |
| 紧凑间距 | 开 / 关 | 是否压缩消息之间的垂直间距 |
| 行内公式 / 块级公式 | 开 / 关 | 控制 LaTeX 渲染 |
| 用户 Markdown / 助手 Markdown | 开 / 关 | 控制不同角色消息是否渲染 Markdown |
| 代码块自动折叠 | 开 / 关 | 是否默认折叠代码块 |
| 移动端代码自动换行 | 开 / 关 | 控制窄屏代码块换行 |
| 重新生成前确认 | 开 / 关 | 重新生成前是否弹出确认 |
| 重新生成时删除下方消息 | 开 / 关 | 控制历史分叉处理方式 |
| 消息导航按钮 | 开 / 关 | 是否显示消息跳转按钮 |
| 会话列表日期 | 开 / 关 | 是否在会话列表显示日期 |
| 选择会话后保持抽屉打开 | 开 / 关 | 主要影响窄屏抽屉交互 |
| Enter 发送消息 | 开 / 关 | 控制键盘发送行为 |
| 触觉反馈 | 开 / 关 | 控制按钮等交互反馈 |
| 气泡样式 | 默认、柔和、简洁 | 控制消息背景表现 |
| 应用字体 | 系统默认、屏显黑体、宋体 | 控制应用主字体 |
| 代码字体 | 系统默认、等宽、衬线 | 控制代码块字体 |
| 消息字号 | `90%` 到 `140%` | 默认 `110%` |
| 发送后回到底部延迟 | `0` 到 `60` 秒 | `0` 表示立即滚动 |

显示设置只影响本机 UI 呈现，不会改变已经发送给 BareBrain 的消息内容。

### 快捷短语

入口：`设置` -> `模型与服务` -> `快捷短语`。

快捷短语包含标题、正文和启用状态。启用后可从输入栏快速插入，适合保存高频提问、固定开场和调试提示。关闭某条短语后，配置仍保留，但不会出现在可插入列表中。

### 指令注入

入口：`设置` -> `模型与服务` -> `指令注入`。

指令注入包含全局开关和多条规则。每条规则包含标题、内容、位置和启用状态。

| 位置 | 说明 |
|------|------|
| 系统前置 | 作为更高优先级的前置说明拼接到发送内容 |
| 用户前置 | 拼接到用户消息前 |
| 消息后置 | 拼接到用户消息后 |

指令注入会在发送时生成增强文本，本地聊天记录仍保留用户原始输入。发送失败后重试，会按当前启用规则重新应用注入。

### 网络代理

入口：`设置` -> `模型与服务` -> `网络代理`。

网络代理会应用于 BareBrain WebSocket 和 OTA 版本检查请求。命中绕过规则时，请求会回到直连，适合保留局域网设备访问路径。

| 字段 | 默认值 | 规则与影响 |
|------|--------|------------|
| 启动代理 | 关闭 | 关闭时所有请求直连 |
| 代理类型 | `HTTP` | 当前支持 HTTP 代理 |
| 服务器地址 | `127.0.0.1` | 只填写 IP 或主机名，不填写协议和路径 |
| 端口 | `8080` | 必须在 `1` 到 `65535` 之间 |
| 用户名 / 密码 | 空 | 可选代理认证信息 |
| 代理绕过 | `localhost`, `127.0.0.1`, `10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16`, `::1` | 支持逗号或换行分隔 |
| 测试地址 | `https://example.com` | 必须是 `http` 或 `https` URL |

### OTA 参数

入口：`设置` -> `设备连接` -> `OTA 参数`。

| 字段 | 默认值 | 规则与影响 |
|------|--------|------------|
| 版本检查路径 | `/ota/version` | 必须以 `/` 开头，不能包含空白、查询、片段或完整域名 |
| 固件路径 | `/ota/firmware` | 必须是设备内相对路径 |
| 更新通道 | `stable` | 不能为空，最长 24 个字符，只能包含字母、数字、下划线、点和短横线 |
| 超时秒数 | `120` | 允许 `10` 到 `600` 秒 |
| 自动检查更新 | 关闭 | 启用后应用恢复会话时自动检查版本，失败时显示状态提示 |

### 存储空间

入口：`设置` -> `数据设置` -> `存储空间`。

存储空间页面会读取真实会话目录与快照统计本机占用，当前展示聊天记录、缓存等分类，便于确认会话记录和目录索引占用。

### 备份与恢复

入口：`设置` -> `数据设置` -> `备份与恢复`。

| 配置 | 说明 |
|------|------|
| 聊天记录 | 控制是否自动保存会话 |
| 本地导出 | 导出 JSON 文件，并把同一份 JSON 复制到剪贴板 |
| 本地恢复 | 粘贴备份 JSON 后恢复配置 |
| WebDAV / S3 | 当前为占位入口，未配置服务器时会提示未配置 |

完整备份 JSON 包含：

```json
{
  "version": 1,
  "appSettings": {},
  "connectionSettings": {},
  "displaySettings": {}
}
```

恢复前建议先导出当前配置，便于参数不符合预期时回退。

## BareBrain 板子配置

入口：聊天输入框左下角快捷列表。

板子设置项会通过 BareBrain admin HTTP 接口读取或写入配置，不会发送给聊天模型，也不会把敏感字段写进本地聊天记录。Relay 模式下暂不支持板子设置。

| 动作 | 说明 |
|------|------|
| 板子设置说明 | 展示快捷列表支持的 BareBrain 板子设置项 |
| 查看板子配置 | 读取 BareBrain admin portal 当前配置 |
| 设置 WiFi | 写入 WiFi SSID 和密码 |
| 设置 API Key | 写入主聊天模型使用的 API Key |
| 设置模型 | 写入主聊天模型名称 |
| 设置模型供应商 | 在支持的模型供应商之间切换 |
| 设置 Base URL | 写入主聊天模型请求地址 |
| 设置记忆 API Key | 写入记忆模型服务 API Key |
| 设置记忆模型 | 写入记忆模型名称 |
| 设置记忆供应商 | 写入记忆模型供应商 |
| 设置记忆 Base URL | 写入记忆模型请求地址 |
| 设置代理 / 清除代理 | 配置或清除板子访问模型服务时使用的代理 |
| 设置 Brave Search Key | 写入 Brave Search 服务 Key |
| 设置 Tavily Key | 写入 Tavily 服务 Key |

部分板子配置保存后设备会自动重启，短时间内 WebSocket 断开属于正常现象。

## Relay 服务端配置

`server/` 目录提供 BareBrainAPP 的自建 WebSocket Relay。更详细的协议和部署说明见 `server/README.md`。

默认连接路径：

```text
BareBrain ESP32  --wss/ws-->  relay_server.dart  <--wss/ws--  BareBrainAPP
```

板子连接：

```text
ws://<relay-host>:8080/ws/device?device_id=<id>&token=<device-token>
```

App 连接：

```text
ws://<relay-host>:8080/ws/app?device_id=<id>&token=<app-token>
```

Relay 环境变量：

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `RELAY_HOST` | `0.0.0.0` | Relay 监听地址 |
| `RELAY_PORT` | `8080` | Relay 监听端口 |
| `RELAY_DEVICE_ID` | `home` | 允许连接的设备 ID |
| `RELAY_DEVICE_TOKEN` | `change-device-token` | 板子设备 token |
| `RELAY_APP_TOKEN` | `change-app-token` | App token |
| `PUSH_WEBHOOK_URL` | 空 | 板子主动消息到达时调用的推送 Webhook |
| `PUSH_AUTH_HEADER` | `Authorization` | Webhook 鉴权 header 名 |
| `PUSH_AUTH_VALUE` | 空 | Webhook 鉴权 header 值，留空则不发送 |
| `PUSH_TIMEOUT_MS` | `8000` | 推送 Webhook 超时毫秒数 |

手机退到后台、锁屏或被系统回收后，App 不能依赖 WebSocket 保活。需要后台通知时，应让 Relay 调用 `PUSH_WEBHOOK_URL`，再由该 Webhook 接入 FCM、APNs、华为/小米等厂商推送，或 Bark、ntfy 等自建推送服务。

公网部署建议使用 Caddy 或 Nginx 终止 TLS，对外只开放 HTTPS/WSS：

```text
wss://relay.example.com/ws/app
wss://relay.example.com/ws/device
```

Relay 服务本身可以只监听 `127.0.0.1:8080`，由反向代理转发。不要把 ESP32 的 `18789` 端口映射到公网。

## 数据与备份

本地数据通过 Key-Value JSON 持久化，底层使用 `shared_preferences`。主要数据范围：

- 连接参数：直连/Relay、主机、端口、客户端 ID、超时、WSS、Relay 设备 ID、App Token、Relay 路径、OTA 参数。
- 显示设置：主题、渲染、字体、消息行为和交互偏好。
- 应用设置：快捷短语、指令注入、网络代理、存储策略。
- 会话数据：会话目录、会话快照和草稿。

传输层通过 `TextSocketConnection` 抽象隔离，后续可以替换成 HTTP、本地模拟器或其他通道。会话快照通过 `ChatSessionStore` 抽象隔离；会话目录通过 `ChatConversationCatalogStore` 抽象隔离。

## 排障建议

- 直连失败：确认 BareBrain IP 正确、App 与设备位于同一局域网、端口 `18789` 可访问、WSS 开关与设备服务一致。
- Relay 失败：确认 Relay 服务运行、设备已连上 Relay、App 与设备使用同一个 `device_id`，App Token 与服务端配置一致。
- 聊天超时：适当调高“超时秒数”，同时检查 BareBrain 模型服务、代理和 API Key。
- 板子设置失败：确认当前是直连模式，设备 admin 接口可访问；若刚保存 WiFi 或模型配置，等待设备重启完成后再试。
- 代理后无法访问局域网设备：确认绕过规则包含当前局域网网段，例如 `192.168.0.0/16`。
- OTA 检查失败：确认路径以 `/` 开头，设备端提供对应接口，代理绕过规则不会误伤局域网访问。

## 开发约束

不要在自动化里无确认运行 Flutter 命令。后续如果需要补齐平台目录、拉依赖、测试、分析或启动应用，必须先得到明确同意，并且命令执行层必须设置超时。
