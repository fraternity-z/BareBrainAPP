# BareBrainAPP

BareBrainAPP 是面向 BareBrain 的 Flutter 局域网聊天客户端。当前版本通过 BareBrain 固件自带的本地 WebSocket 网关通信，并等待完整回复后再展示，所以聊天路径是非流式的。

## 协议

BareBrain 的局域网网关地址：

```text
ws://<BareBrain device IP>:18789/
```

发送消息：

```json
{"type":"message","content":"hello","chat_id":"barebrain_app"}
```

接收回复：

```json
{"type":"response","content":"Hi!","chat_id":"barebrain_app"}
```

本项目不会修改 `E:\code\BareBrain`。

## 结构

```text
lib/src/app/                         App 外壳和默认配置
lib/src/core/                        共享错误类型
lib/src/features/chat/chat_feature_module.dart 聊天功能依赖装配入口
lib/src/features/chat/domain/        聊天实体、仓库接口和用例
lib/src/features/chat/data/          BareBrain WebSocket 协议适配
lib/src/features/chat/presentation/  控制器和 Flutter UI
test/features/chat/                  单元测试
```

## 当前功能

- 局域网 WebSocket 非流式聊天。
- 默认端口 `18789`，可在界面里修改设备 IP、端口、客户端 ID 和超时秒数。
- 连接设置支持直接粘贴 `ws://<设备IP>:18789/`，保存时会归一化为主机名、端口和安全连接标记。
- 连接设置支持测试 BareBrain WebSocket 握手，不发送聊天内容，方便局域网首连排错。
- 发送后会等待 BareBrain 返回匹配 `chat_id` 的完整 `response`。
- 默认会话沿用客户端 ID 作为 `chat_id`，新建会话会派生稳定的短 `chat_id`，避免 BareBrain 设备侧会话历史串在一起。
- 聊天页会显示等待 BareBrain 回复的状态，以及离线、超时、输入错误等失败提示。
- 每条消息会显示本地时间，便于回看局域网聊天记录。
- 每条消息支持一键复制，复制后会给出轻量提示。
- 发送失败后可以重试最后一条用户消息，重试时复用原消息，不在本地历史里重复追加提问。
- 输入框草稿会按会话保存，切换会话后再回来不会丢失未发送内容。
- 传输层通过 `TextSocketConnection` 抽象隔离，后续可以替换成 HTTP、本地模拟器或其他通道。
- `ChatFeatureModule` 集中装配聊天模块依赖，App 外壳不直接依赖 WebSocket、仓库和持久化实现。
- 会话快照通过 `ChatSessionStore` 抽象隔离，当前接入 Key-Value JSON 适配，底层使用 `shared_preferences` 持久化。
- 会话快照 key 会按 `conversationId` 派生，避免后续多会话共用同一条聊天记录。
- 会话目录通过 `ChatConversationCatalogStore` 抽象隔离，当前会维护默认会话摘要，后续可扩展为多会话列表。
- 宽屏侧边栏和窄屏抽屉会显示会话摘要，并支持新建、切换、重命名和删除非当前会话。
- 默认标题的会话会在首条用户消息发送后自动用消息内容命名；手动重命名或创建时指定标题的会话不会被覆盖。
- 显示设置支持颜色模式、主题预设、消息时间/操作、消息文本选择、紧凑间距、消息字体大小、应用/代码字体、聊天气泡样式、触觉反馈、聊天背景遮罩透明度和发送后回到底部延迟，并会通过本地 Key-Value 存储持久化。
- 设置页已接入语音服务、世界书、快捷短语、指令注入、网络代理、数据备份和聊天记录存储配置；这些应用设置会通过本地 Key-Value JSON 持久化。
- 语音服务启用后会在收到助手回复时向配置的 HTTP 服务 POST 回复文本、音色和流式标记；设置页可发起测试请求，语音失败会显示错误但不回滚聊天记录。
- OTA 参数可配置版本检查路径、固件路径、通道、超时和自动检查开关，可从设置页发起版本检查请求；启用自动检查后，应用恢复会话后会自动检查版本并在失败时显示状态提示。
- 快捷短语可在输入栏插入；世界书和指令注入会在发送时生成增强文本，同时本地聊天记录仍保留用户原始输入，重试失败消息时也会重新应用当前规则。
- 网络代理设置会在 BareBrain WebSocket、语音 HTTP 和 OTA 版本检查调用时注入到 IO `HttpClient`，支持本地绕过规则，并可从设置页发起 HTTP 连接测试。
- 数据备份支持复制/导入包含连接参数、显示设置和应用设置的 JSON，便于迁移设置页中的本地配置。

## Flutter 命令

不要在自动化里无确认运行 Flutter 命令。后续如果需要补齐平台目录、拉依赖、测试、分析或启动应用，必须先得到明确同意，并且命令执行层必须设置超时。
