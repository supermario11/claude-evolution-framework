# 微信 Claude Code 集成深度分析

## 创建日期
2025-04-08

## 项目来源
GitHub: https://github.com/Wechat-ggGitHub/wechat-claude-code

## 核心架构图

```
┌─────────────────────────────────────────────────┐
│              WeChat User                         │
│         (发送消息/接收回复)                        │
└───────────────────┬─────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────┐
│       WeChat Server (ilinkai.weixin.qq.com)     │
│           - 长轮询接收消息                         │
│           - HTTP API 发送消息                     │
│           - CDN 媒体处理                          │
└───────────────────┬─────────────────────────────┘
                    │ (HTTPS + Bearer Token)
                    ▼
┌─────────────────────────────────────────────────┐
│          Local Node.js Process                   │
│  ┌───────────────────────────────────────────┐  │
│  │        WeChatApi (api.ts)                 │  │
│  │  - getUpdates() - 长轮询                   │  │
│  │  - sendMessage() - 发消息                  │  │
│  │  - getUploadUrl() - 媒体上传               │  │
│  └─────────────┬─────────────────────────────┘  │
│                │                                  │
│  ┌─────────────▼─────────────────────────────┐  │
│  │       Monitor (monitor.ts)                │  │
│  │  - 持续长轮询                               │  │
│  │  - 消息去重 (recentMsgIds Set)             │  │
│  │  - 错误重试 & 指数退避                       │  │
│  │  - Session 过期处理                        │  │
│  └─────────────┬─────────────────────────────┘  │
│                │                                  │
│  ┌─────────────▼─────────────────────────────┐  │
│  │   Message Handler (main.ts)               │  │
│  │  - 提取文本/图片                            │  │
│  │  - 命令路由 (/clear, /status, etc.)        │  │
│  │  - 权限管理 (y/n 审批)                      │  │
│  │  - 并发控制 (AbortController)              │  │
│  │  - 会话状态管理                             │  │
│  └─────────────┬─────────────────────────────┘  │
│                │                                  │
│  ┌─────────────▼─────────────────────────────┐  │
│  │    Claude Provider (provider.ts)          │  │
│  │  - 调用 @anthropic-ai/claude-agent-sdk    │  │
│  │  - 流式响应处理                             │  │
│  │  - 权限回调 (canUseTool)                   │  │
│  │  - Thinking 进度展示                        │  │
│  │  - Session 恢复 (resume)                   │  │
│  └─────────────┬─────────────────────────────┘  │
└────────────────┼──────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────┐
│            Claude Code (本地)                     │
│       - 执行工具 (Bash, Read, Write, etc.)       │
│       - 文件操作                                  │
│       - 代码生成                                  │
└─────────────────────────────────────────────────┘
```

---

## 关键技术点深度剖析

### 1. 长轮询机制 (monitor.ts)

**原理**：
```typescript
// 持续循环调用 getUpdates()
while (!stopped) {
  const resp = await api.getUpdates(syncBuf);  // 35秒超时
  // 处理新消息
  // 保存 sync buffer
  // 错误重试
}
```

**关键细节**：

#### a) Sync Buffer 机制
```typescript
// 每次请求携带上次的 sync buffer
const buf = loadSyncBuf();  // 从文件读取
const resp = await api.getUpdates(buf || undefined);
// 收到新的 buffer
if (resp.get_updates_buf) {
  saveSyncBuf(resp.get_updates_buf);  // 保存到文件
}
```

**作用**：
- 告诉服务器从哪里继续获取消息
- 类似于 offset/cursor 的概念
- 防止消息重复或遗漏

#### b) 消息去重
```typescript
const recentMsgIds = new Set<number>();  // 最近的消息 ID
const MAX_MSG_IDS = 1000;

// 检查是否已处理
if (msg.message_id && recentMsgIds.has(msg.message_id)) {
  continue;  // 跳过
}

// 记录新消息
recentMsgIds.add(msg.message_id);

// 淘汰老消息 ID (保持 Set 大小)
if (recentMsgIds.size > MAX_MSG_IDS) {
  // 删除最老的一半
}
```

**为什么需要**：
- 网络重试可能导致重复消息
- Sync buffer 可能失效
- 服务端可能推送重复

#### c) 错误重试与指数退避
```typescript
let consecutiveFailures = 0;
const BACKOFF_THRESHOLD = 3;
const BACKOFF_SHORT_MS = 3_000;   // 3秒
const BACKOFF_LONG_MS = 30_000;   // 30秒

try {
  // 长轮询
  consecutiveFailures = 0;  // 成功则重置
} catch (err) {
  consecutiveFailures++;
  const backoff = consecutiveFailures >= BACKOFF_THRESHOLD
    ? BACKOFF_LONG_MS
    : BACKOFF_SHORT_MS;
  await sleep(backoff);
}
```

**策略**：
- 前 3 次失败：短退避 (3秒)
- 3 次以上：长退避 (30秒)
- 成功立即重置计数

#### d) Session 过期处理
```typescript
const SESSION_EXPIRED_ERRCODE = -14;
const SESSION_EXPIRED_PAUSE_MS = 60 * 60 * 1000;  // 1小时

if (resp.ret === SESSION_EXPIRED_ERRCODE) {
  logger.warn('Session expired, pausing for 1 hour');
  callbacks.onSessionExpired();  // 通知用户
  await sleep(SESSION_EXPIRED_PAUSE_MS);  // 暂停1小时
  continue;  // 继续监听（等待重新扫码）
}
```

---

### 2. 认证流程 (login.ts)

**完整流程**：

```typescript
// Step 1: 启动二维码登录
const { qrcodeUrl, qrcodeId } = await startQrLogin();

// Step 2: 生成并显示二维码
if (isHeadlessLinux) {
  // 终端显示
  qrcodeTerminal.generate(qrcodeUrl, { small: true });
} else {
  // GUI: 生成 PNG 并打开
  const pngData = await QRCode.toBuffer(qrcodeUrl);
  writeFileSync(QR_PATH, pngData);
  openFile(QR_PATH);  // 用系统默认程序打开
}

// Step 3: 轮询扫码状态
while (true) {
  try {
    await waitForQrScan(qrcodeId);  // 轮询直到成功
    console.log('✅ 绑定成功!');
    break;
  } catch (err) {
    if (err.message?.includes('expired')) {
      console.log('⚠️ 二维码已过期，正在刷新...');
      continue;  // 重新生成二维码
    }
    throw err;
  }
}
```

**关键API**（推测基于代码）：
```
POST /ilink/bot/start_qr_login
Response: {
  qrcode_url: "https://...",
  qrcode_id: "xxx"
}

GET /ilink/bot/check_qr_scan?qrcode_id=xxx
Response: {
  status: "waiting" | "scanned" | "confirmed" | "expired",
  token?: "...",  // confirmed 时返回
  base_url?: "https://..."
}
```

---

### 3. API 层设计 (api.ts)

**核心类**：
```typescript
class WeChatApi {
  private readonly token: string;      // Bot Token
  private readonly baseUrl: string;    // API Base URL
  private readonly uin: string;        // 随机 UIN (用户标识)

  // 统一请求方法
  private async request<T>(
    path: string,
    body: unknown,
    timeoutMs: number = 15_000
  ): Promise<T> {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), timeoutMs);

    const res = await fetch(`${this.baseUrl}/${path}`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${this.token}`,
        'AuthorizationType': 'ilink_bot_token',
        'X-WECHAT-UIN': this.uin,  // 随机生成的 UIN
      },
      body: JSON.stringify(body),
      signal: controller.signal,
    });

    return await res.json();
  }
}
```

**关键头部**：
- `Authorization: Bearer <token>` - 主要认证
- `AuthorizationType: ilink_bot_token` - 认证类型标识
- `X-WECHAT-UIN` - 随机 UIN（base64 编码的 uint32）

**UIN 生成**：
```typescript
function generateUin(): string {
  const buf = new Uint8Array(4);
  crypto.getRandomValues(buf);  // 随机 4 字节
  return Buffer.from(buf).toString('base64');
}
```

**关键 API**：

#### a) getUpdates (长轮询)
```typescript
async getUpdates(buf?: string): Promise<GetUpdatesResp> {
  return this.request<GetUpdatesResp>(
    'ilink/bot/getupdates',
    buf ? { get_updates_buf: buf } : {},
    35_000,  // 35秒超时（服务端长轮询30秒 + 余量）
  );
}
```

**响应格式**：
```typescript
interface GetUpdatesResp {
  ret: number;  // 0=成功, -14=session过期
  retmsg?: string;
  get_updates_buf?: string;  // 新的 sync buffer
  msgs?: WeixinMessage[];
}
```

#### b) sendMessage (发送消息)
```typescript
async sendMessage(req: SendMessageReq): Promise<void> {
  // 重试逻辑（处理限流 ret: -2）
  const MAX_RETRIES = 3;
  let delay = 10_000;

  for (let attempt = 0; attempt <= MAX_RETRIES; attempt++) {
    const res = await this.request('ilink/bot/sendmessage', req);

    if (res.ret === -2) {  // 限流
      if (attempt === MAX_RETRIES) return;
      await sleep(delay);
      delay = Math.min(delay * 2, 60_000);  // 指数退避
      continue;
    }
    return;
  }
}
```

**请求格式**：
```typescript
interface SendMessageReq {
  context_token: string;  // 消息上下文令牌
  to_user_id: string;
  content: Array<{
    type: 'text' | 'image' | ...;
    text?: string;
    // ...
  }>;
}
```

#### c) getUploadUrl (媒体上传)
```typescript
async getUploadUrl(
  fileType: string,
  fileSize: number,
  fileName: string,
): Promise<GetUploadUrlResp> {
  return this.request('ilink/bot/getuploadurl', {
    file_type: fileType,
    file_size: fileSize,
    file_name: fileName,
  });
}
```

---

### 4. Claude SDK 集成 (provider.ts)

**核心函数**：
```typescript
export async function claudeQuery(options: QueryOptions): Promise<QueryResult> {
  const { prompt, cwd, resume, model, images, onText, onThinking } = options;

  // 1. 构建 SDK Options
  const sdkOptions: Options = {
    cwd,
    permissionMode,
    settingSources: ["user", "project"],
    includePartialMessages: !!onText,  // 启用流式
  };

  if (model) sdkOptions.model = model;
  if (resume) sdkOptions.resume = resume;  // 恢复会话

  // 2. 权限回调
  if (onPermissionRequest) {
    sdkOptions.canUseTool = async (toolName, input) => {
      const allowed = await onPermissionRequest(toolName, JSON.stringify(input));
      if (allowed) {
        return { behavior: "allow", updatedInput: input };
      }
      return {
        behavior: "deny",
        message: "Permission denied by user.",
        interrupt: true,
      };
    };
  }

  // 3. 执行查询
  const result = query({ prompt, options: sdkOptions });

  // 4. 流式处理
  for await (const message of result) {
    switch (message.type) {
      case "assistant":
        // 提取工具调用，通知 onThinking
        // 积累文本
        break;

      case "stream_event":
        // 处理 text_delta (onText)
        // 处理 thinking_delta (显示思考过程)
        break;

      case "result":
        // 最终结果或错误
        break;
    }
  }

  return { text, sessionId, error };
}
```

**关键创新点**：

#### a) 流式响应实时推送
```typescript
const SEND_INTERVAL_MS = 36_000;  // 36秒发一次中间结果
let pendingBuffer = '';

onText: async (delta: string) => {
  pendingBuffer += delta;
  await trySend();  // 如果间隔够了就发送
},

async function trySend(force = false): Promise<void> {
  if (!pendingBuffer.trim()) return;
  const now = Date.now();
  if (!force && now - lastSendTime < SEND_INTERVAL_MS) return;

  // 发送到微信
  const chunks = splitMessage(pendingBuffer);
  for (const chunk of chunks) {
    await sender.sendText(fromUserId, contextToken, chunk);
  }

  pendingBuffer = '';
  lastSendTime = now;
}
```

**策略**：
- 积累 delta 到 buffer
- 每 36 秒发送一次
- 最后 force=true 发送剩余内容

#### b) Thinking 进度展示
```typescript
onThinking: async (summary: string) => {
  pendingBuffer += (pendingBuffer ? '\n' : '') + summary;
  await trySend();
}

// 格式化工具调用
function formatToolUse(toolName: string, input: Record<string, unknown>): string {
  const icons = {
    Bash: "🔧", Read: "📖", Write: "✏️", Grep: "🔍",
    WebFetch: "🌐", Task: "🤖",
  };
  const icon = icons[toolName] ?? "⚙️";
  return `${icon} ${toolName}: ${detail}`;
}
```

**效果**：
```
🔧 Bash: npm install
📖 Read: package.json
✏️ Write: src/新功能.ts
```

#### c) 思考过程预览
```typescript
const MAX_THINKING_PREVIEW = 300;
let thinkingBuf = "";
let thinkingCapped = false;

if (deltaType === "thinking_delta" && !thinkingCapped) {
  thinkingBuf += delta.thinking;

  if (thinkingBuf.length >= MAX_THINKING_PREVIEW) {
    thinkingCapped = true;
    await onText("💭 " + thinkingBuf.slice(0, 300).trim() + "…\n");
    thinkingBuf = "";
  }
}
```

**避免刷屏**：只显示前 300 字符的思考过程

#### d) Session 恢复
```typescript
// 第一次查询
const result1 = await claudeQuery({
  prompt: "创建一个 React 组件",
  cwd: "/project"
});
session.sdkSessionId = result1.sessionId;  // 保存

// 第二次查询（继续上下文）
const result2 = await claudeQuery({
  prompt: "添加样式",
  cwd: "/project",
  resume: session.sdkSessionId  // 恢复会话
});
```

**如果 resume 失败**：
```typescript
if (result.error && queryOptions.resume) {
  logger.warn('Resume failed, retrying without resume');
  queryOptions.resume = undefined;  // 不恢复
  session.sdkSessionId = undefined;
  const retryResult = await claudeQuery(queryOptions);
}
```

---

### 5. 并发控制与状态管理

**会话状态机**：
```typescript
type SessionState = 'idle' | 'processing' | 'waiting_permission';

session.state = 'idle';  // 初始状态

// 收到消息 → processing
session.state = 'processing';

// 请求权限 → waiting_permission
session.state = 'waiting_permission';

// 权限批准 → processing
// 权限拒绝 → idle
// 完成查询 → idle
```

**并发消息处理**：
```typescript
const activeControllers = new Map<string, AbortController>();

// 新消息到达时
if (session.state === 'processing') {
  if (!userText.startsWith('/')) {
    // 取消当前查询
    const ctrl = activeControllers.get(accountId);
    if (ctrl) {
      ctrl.abort();  // 取消
      activeControllers.delete(accountId);
    }
    session.state = 'idle';
    // 处理新消息
  }
}

// 开始新查询时
const abortController = new AbortController();
activeControllers.set(accountId, abortController);

const result = await claudeQuery({
  ...,
  abortController,  // 传递给 SDK
});
```

**效果**：
- 用户发新消息 → 取消旧查询 → 处理新消息
- 避免多个查询同时运行
- 响应更及时

**权限审批流程**：
```typescript
// 1. SDK 请求权限
onPermissionRequest: async (toolName, toolInput) => {
  // 设置状态
  session.state = 'waiting_permission';

  // 创建 pending promise
  const permissionPromise = permissionBroker.createPending(
    accountId,
    toolName,
    toolInput,
  );

  // 发送消息到微信
  await sender.sendText(userId, contextToken,
    "🔐 Claude 请求执行工具\n" +
    `工具: ${toolName}\n` +
    `参数: ${toolInput}\n\n` +
    "回复 y 允许，n 拒绝"
  );

  // 等待用户回复
  const allowed = await permissionPromise;  // 阻塞在这里

  // 恢复状态
  session.state = 'processing';

  return allowed;
}

// 2. 用户回复 y/n
if (session.state === 'waiting_permission') {
  if (lower === 'y' || lower === 'yes') {
    permissionBroker.resolvePermission(accountId, true);
    await sender.sendText(userId, contextToken, '✅ 已允许');
  } else if (lower === 'n' || lower === 'no') {
    permissionBroker.resolvePermission(accountId, false);
    await sender.sendText(userId, contextToken, '❌ 已拒绝');
  }
  return;  // 不继续处理
}
```

**PermissionBroker 实现**：
```typescript
interface PendingPermission {
  toolName: string;
  toolInput: string;
  resolve: (allowed: boolean) => void;
  timeout: NodeJS.Timeout;
}

const pendingMap = new Map<string, PendingPermission>();

function createPending(accountId: string, toolName: string, toolInput: string): Promise<boolean> {
  return new Promise((resolve) => {
    const timeout = setTimeout(() => {
      // 超时自动拒绝
      pendingMap.delete(accountId);
      onTimeout();  // 通知用户
      resolve(false);
    }, 60_000);  // 60秒超时

    pendingMap.set(accountId, {
      toolName,
      toolInput,
      resolve,
      timeout,
    });
  });
}

function resolvePermission(accountId: string, allowed: boolean): boolean {
  const pending = pendingMap.get(accountId);
  if (!pending) return false;

  clearTimeout(pending.timeout);
  pendingMap.delete(accountId);
  pending.resolve(allowed);  // 解析 Promise
  return true;
}
```

---

### 6. 消息分片

**长消息处理**：
```typescript
const MAX_MESSAGE_LENGTH = 2048;  // 微信限制

function splitMessage(text: string, maxLen: number = MAX_MESSAGE_LENGTH): string[] {
  if (text.length <= maxLen) return [text];

  const chunks: string[] = [];
  let remaining = text;

  while (remaining.length > 0) {
    if (remaining.length <= maxLen) {
      chunks.push(remaining);
      break;
    }

    // 尝试在换行符处分割
    let splitIdx = remaining.lastIndexOf('\n', maxLen);
    if (splitIdx < maxLen * 0.3) {  // 换行符太靠前
      splitIdx = maxLen;  // 强制在 maxLen 切
    }

    chunks.push(remaining.slice(0, splitIdx));
    remaining = remaining.slice(splitIdx).replace(/^\n+/, '');
  }

  return chunks;
}

// 使用
const chunks = splitMessage(longText);
for (const chunk of chunks) {
  await sender.sendText(userId, contextToken, chunk);
}
```

**策略**：
- 优先在换行符处分割
- 如果换行符太靠前（< 30%），强制切割
- 移除切割点后的多余换行

---

### 7. 命令系统

**命令路由器**：
```typescript
interface CommandContext {
  accountId: string;
  session: Session;
  updateSession: (partial: Partial<Session>) => void;
  clearSession: () => void;
  getChatHistoryText: (limit?: number) => string;
  rejectPendingPermission: () => void;
  text: string;  // 完整命令文本
}

interface CommandResult {
  handled: boolean;
  reply?: string;
  claudePrompt?: string;  // 如果需要调用 Claude
}

function routeCommand(ctx: CommandContext): CommandResult {
  const { text, session, updateSession } = ctx;

  if (text === '/help') {
    return {
      handled: true,
      reply: "可用命令:\n/help - 帮助\n/clear - 清空对话\n/status - 状态",
    };
  }

  if (text === '/clear') {
    ctx.clearSession();
    ctx.rejectPendingPermission();
    return {
      handled: true,
      reply: "✅ 对话已清空",
    };
  }

  if (text === '/status') {
    const history = ctx.getChatHistoryText(5);
    return {
      handled: true,
      reply: `状态: ${session.state}\n工作目录: ${session.workingDirectory}\n` +
             `最近对话:\n${history}`,
    };
  }

  if (text.startsWith('/cd ')) {
    const newDir = text.slice(4).trim();
    updateSession({ workingDirectory: newDir });
    return {
      handled: true,
      reply: `✅ 工作目录已切换到: ${newDir}`,
    };
  }

  if (text.startsWith('/sys ')) {
    const prompt = text.slice(5).trim();
    return {
      handled: true,
      claudePrompt: prompt,  // 转发给 Claude
    };
  }

  return { handled: false };  // 未识别
}
```

---

## 媒体处理

### 下载图片
```typescript
async function downloadImage(imageItem: ImageItem): Promise<string | null> {
  try {
    // 1. 从 CDN URL 下载
    const response = await fetch(imageItem.cdn_url);
    const arrayBuffer = await response.arrayBuffer();
    const buffer = Buffer.from(arrayBuffer);

    // 2. 转换为 base64 data URI
    const mimeType = imageItem.type === 'image' ? 'image/jpeg' : 'image/png';
    const base64 = buffer.toString('base64');
    return `data:${mimeType};base64,${base64}`;
  } catch (err) {
    logger.error('Failed to download image', { err });
    return null;
  }
}
```

### 上传媒体
```typescript
async function uploadMedia(file: Buffer, fileType: string): Promise<string> {
  // 1. 获取上传 URL
  const { upload_url, upload_token } = await api.getUploadUrl(
    fileType,
    file.length,
    'file.png',
  );

  // 2. 上传到 CDN
  const formData = new FormData();
  formData.append('file', file);
  formData.append('upload_token', upload_token);

  const response = await fetch(upload_url, {
    method: 'POST',
    body: formData,
  });

  const { media_id } = await response.json();
  return media_id;
}
```

---

## 关键洞察总结

### 1. 架构设计模式

**分层清晰**：
```
API Layer (api.ts) - HTTP 调用
  ↓
Monitor Layer (monitor.ts) - 消息轮询
  ↓
Handler Layer (main.ts) - 业务逻辑
  ↓
Provider Layer (provider.ts) - Claude 集成
```

**职责单一**：每个模块只做一件事

### 2. 可靠性保障

- **消息去重**: Set 记录已处理 ID
- **错误重试**: 指数退避
- **Session 恢复**: 保存 sync buffer
- **限流处理**: 自动重试
- **超时处理**: AbortController

### 3. 用户体验优化

- **流式响应**: 实时推送中间结果
- **进度展示**: Thinking 和工具调用
- **权限审批**: 交互式 y/n
- **命令系统**: /clear, /status 等
- **并发控制**: 新消息取消旧查询

### 4. 安全性考虑

- **BaseURL 白名单**: 只允许 weixin.qq.com/wechat.com
- **HTTPS 强制**: 拒绝 HTTP
- **Token 认证**: Bearer Token
- **权限控制**: 工具执行需审批

---

## 可扩展点

### 1. 多平台适配

**当前架构易于扩展**：
```typescript
interface IMAdapter {
  receiveMessages(): AsyncGenerator<Message>;
  sendMessage(msg: Message): Promise<void>;
}

class WeChatAdapter implements IMAdapter { ... }
class FeishuAdapter implements IMAdapter { ... }
class DingTalkAdapter implements IMAdapter { ... }
```

### 2. 多 Agent 支持

```typescript
class AgentRouter {
  private agents: Map<string, Agent>;

  registerAgent(name: string, agent: Agent) {
    this.agents.set(name, agent);
  }

  async route(message: Message): Promise<Message> {
    const agentName = extractAgentName(message);  // /agent:gpt4 ...
    const agent = this.agents.get(agentName) ?? this.defaultAgent;
    return await agent.process(message);
  }
}
```

### 3. 插件系统

```typescript
interface Plugin {
  onMessage?(msg: Message): Promise<void>;
  onSend?(msg: Message): Promise<void>;
  commands?: Map<string, CommandHandler>;
}

class PluginManager {
  private plugins: Plugin[] = [];

  use(plugin: Plugin) {
    this.plugins.push(plugin);
  }

  async runHook(hook: string, ...args: any[]) {
    for (const plugin of this.plugins) {
      if (plugin[hook]) {
        await plugin[hook](...args);
      }
    }
  }
}
```

---

## 下一步实践

1. ✅ 深入分析微信协议实现
2. ⏳ 设计通用 IM Agent 架构
3. ⏳ 实现飞书适配器
4. ⏳ 创建可复用 Skill
5. ⏳ 编写完整测试

---

*学习方法应用*:
- **深度处理**: 不只看代码，理解设计决策
- **精细编码**: 关联到已知的设计模式
- **元认知**: 反思架构优缺点
- **知识迁移**: 提取通用原则，可应用到飞书等

*作者: Claude*
*日期: 2025-04-08*
*来源: wechat-claude-code 项目分析*
*XP: +30 (深度代码分析)*
