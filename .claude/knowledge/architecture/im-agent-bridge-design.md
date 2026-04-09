# IM Agent Bridge 架构设计文档

## 创建日期
2025-04-08

## 项目位置
/Users/xiaoyang/Documents/im-agent-bridge

## 设计哲学

本项目应用了从 **Claude Evolution Framework** 学到的设计原则：

1. **奥卡姆剃刀** - 简单优于复杂
2. **单一职责** - 每个模块只做一件事
3. **开闭原则** - 对扩展开放，对修改关闭
4. **依赖倒置** - 依赖抽象而非具体实现

---

## 核心设计模式

### 1. 适配器模式 (Adapter Pattern)

**问题**: 不同 IM 平台有不同的 API 和消息格式

**解决方案**: 创建统一的 `IMAdapter` 接口，每个平台实现这个接口

```typescript
interface IMAdapter {
  readonly platform: Platform;
  authenticate(): Promise<AuthResult>;
  receiveMessages(): AsyncGenerator<UnifiedMessage>;
  sendMessage(message: UnifiedMessage): Promise<SendResult>;
  // ...
}

// 微信实现
class WeChatAdapter implements IMAdapter { ... }

// 飞书实现
class FeishuAdapter implements IMAdapter { ... }
```

**优点**:
- 新增平台不影响现有代码
- 统一的消息格式
- 可插拔设计

### 2. 策略模式 (Strategy Pattern)

**问题**: 不同的 AI Agent 有不同的处理逻辑

**解决方案**: 定义 `Agent` 接口，支持任意 Agent 实现

```typescript
interface Agent {
  readonly name: string;
  process(message: UnifiedMessage, session: Session): Promise<AgentResponse>;
}

// Claude Code
class ClaudeCodeAgent implements Agent { ... }

// GPT-4 (可扩展)
class GPT4Agent implements Agent { ... }
```

### 3. 路由器模式 (Router Pattern)

**问题**: 需要统一管理多个平台和一个 Agent

**解决方案**: `MessageRouter` 作为中间层

```typescript
class MessageRouter {
  private adapters: Map<Platform, IMAdapter>;
  private agent: Agent;

  // 注册适配器
  registerAdapter(adapter: IMAdapter): void

  // 启动所有平台监听
  async start(): Promise<void>

  // 统一处理消息
  private async handleMessage(message, adapter): Promise<void>
}
```

**职责**:
1. 管理多个 IM 适配器
2. 消息规范化
3. 路由到 Agent
4. 会话状态管理
5. 并发控制

### 4. 状态机模式 (State Machine)

**问题**: 会话有多种状态需要管理

**解决方案**: 明确的状态定义和转换规则

```typescript
type SessionState = 'idle' | 'processing' | 'waiting_permission';

// 状态转换
idle → processing (收到消息)
processing → waiting_permission (请求权限)
waiting_permission → processing (批准)
waiting_permission → idle (拒绝)
processing → idle (完成)
```

### 5. 观察者模式 (Observer Pattern)

**问题**: 需要在特定事件发生时执行回调

**解决方案**: RouterCallbacks 接口

```typescript
interface RouterCallbacks {
  onBeforeProcess?: (message: UnifiedMessage) => Promise<void>;
  onAfterProcess?: (message, response) => Promise<void>;
  onError?: (error, message) => Promise<void>;
}
```

---

## 架构层次

### Layer 1: 平台层 (Platform Layer)

```
┌─────────────────────────────────────────┐
│        Platform Adapters                 │
│  ┌──────────┐  ┌──────────┐             │
│  │ WeChat   │  │ Feishu   │             │
│  │ Adapter  │  │ Adapter  │             │
│  └──────────┘  └──────────┘             │
└─────────────────────────────────────────┘
```

**职责**:
- 平台特定的 API 调用
- 消息接收 (长轮询/WebSocket)
- 消息发送
- 媒体处理
- 认证

**关键实现**:

**微信 (HTTP 长轮询)**:
```typescript
async *receiveMessages() {
  while (running) {
    const resp = await this.getUpdates(syncBuf);  // 35s 超时
    // 处理消息
    // 去重
    // yield UnifiedMessage
  }
}
```

**飞书 (WebSocket)**:
```typescript
async *receiveMessages() {
  // WebSocket 监听 → 消息队列 → yield
  while (running) {
    if (messageQueue.length > 0) {
      yield messageQueue.shift();
    }
    await sleep(100);
  }
}
```

### Layer 2: 路由层 (Router Layer)

```
┌─────────────────────────────────────────┐
│         Message Router                   │
│  - 消息规范化                             │
│  - 会话管理                               │
│  - 并发控制                               │
│  - 错误处理                               │
└─────────────────────────────────────────┘
```

**职责**:
- 注册和管理适配器
- 启动所有平台监听
- 消息路由到 Agent
- 会话生命周期管理
- 并发消息控制 (AbortController)

**核心流程**:
```
1. 收到消息
2. 获取/创建会话
3. 检查并发 (取消旧查询)
4. 更新状态 → processing
5. 调用 Agent
6. 发送响应
7. 更新状态 → idle
8. 错误处理
```

### Layer 3: Agent 层 (Agent Layer)

```
┌─────────────────────────────────────────┐
│           AI Agent                       │
│  ┌──────────────┐                       │
│  │ Claude Code  │                       │
│  │ Agent        │                       │
│  └──────────────┘                       │
└─────────────────────────────────────────┘
```

**职责**:
- 处理消息内容
- 调用 AI 模型
- 生成响应

**Claude Code Agent**:
```typescript
async process(message, session) {
  const result = query({
    prompt: message.text,
    options: {
      cwd: session.workingDirectory,
      model: session.model,
      resume: session.sdkSessionId,
    }
  });

  // 收集响应
  for await (const msg of result) {
    // ...
  }

  return { text, sessionId, success };
}
```

---

## 核心数据流

### 消息接收流

```
IM平台
  ↓
[Adapter.receiveMessages()] ← 长轮询/WebSocket
  ↓
UnifiedMessage (规范化)
  ↓
[Router.handleMessage()]
  ↓
Session 管理
  ↓
[Agent.process()]
  ↓
AgentResponse
  ↓
[Adapter.sendMessage()]
  ↓
IM平台
```

### 并发控制流

```
新消息到达
  ↓
检查 session.state
  ↓
如果 processing:
  ├─ 取消旧 AbortController
  ├─ 重置 state = 'idle'
  └─ 继续处理新消息
  ↓
创建新 AbortController
  ↓
调用 Agent (可中断)
  ↓
完成后清理 AbortController
```

---

## 可扩展性设计

### 1. 添加新平台

只需实现 `IMAdapter` 接口：

```typescript
class DingTalkAdapter implements IMAdapter {
  readonly platform = 'dingtalk';

  async authenticate() { /* 钉钉认证 */ }
  async *receiveMessages() { /* 钉钉消息接收 */ }
  async sendMessage(msg) { /* 钉钉消息发送 */ }
  // ...
}

// 注册
router.registerAdapter(new DingTalkAdapter());
```

### 2. 添加新 Agent

只需实现 `Agent` 接口：

```typescript
class GPT4Agent implements Agent {
  readonly name = 'gpt-4';

  async process(message, session) {
    const response = await openai.chat.completions.create({
      messages: [{ role: 'user', content: message.text }]
    });

    return {
      text: response.choices[0].message.content,
      success: true,
    };
  }
}

// 使用
const router = new MessageRouter(new GPT4Agent());
```

### 3. 添加中间件

通过 Callbacks 扩展功能：

```typescript
const router = new MessageRouter(agent, config, {
  onBeforeProcess: async (message) => {
    // 日志记录
    logger.info('收到消息', message);

    // 敏感词过滤
    if (hasBadWords(message.text)) {
      throw new Error('包含敏感词');
    }
  },

  onAfterProcess: async (message, response) => {
    // 统计
    metrics.recordResponse(response);

    // 审计日志
    audit.log(message, response);
  }
});
```

---

## 最佳实践

### 1. 错误处理

```typescript
// 每个 async 方法都要 try-catch
try {
  await adapter.sendMessage(msg);
} catch (error) {
  console.error('发送失败:', error);
  // 记录错误，但不崩溃
}
```

### 2. 资源清理

```typescript
// 监听退出信号
process.on('SIGINT', () => {
  router.stop();  // 清理所有资源
  process.exit(0);
});
```

### 3. 类型安全

```typescript
// 严格使用 TypeScript 类型
const message: UnifiedMessage = {
  id: '...',
  platform: 'wechat',  // 编译时检查
  // ...
};
```

### 4. 并发控制

```typescript
// 使用 AbortController 取消旧请求
const controller = new AbortController();
activeControllers.set(sessionId, controller);

// 传递给可中断的操作
await agent.process(message, { abortController: controller });

// 清理
activeControllers.delete(sessionId);
```

---

## 性能考虑

### 1. 内存管理

```typescript
// 限制聊天历史长度
if (session.chatHistory.length > 20) {
  session.chatHistory = session.chatHistory.slice(-20);
}

// 限制消息去重 Set 大小
if (recentMsgIds.size > 1000) {
  // 删除最老的一半
}
```

### 2. 异步非阻塞

```typescript
// 消息处理不阻塞接收循环
for await (const message of adapter.receiveMessages()) {
  this.handleMessage(message, adapter).catch(console.error);
  // 不 await，继续接收下一条消息
}
```

### 3. 连接重试

```typescript
// 长轮询/WebSocket 断开后重连
try {
  for await (const msg of adapter.receiveMessages()) {
    // ...
  }
} catch (error) {
  if (running) {
    setTimeout(() => this.listenToPlatform(adapter), 5000);
  }
}
```

---

## 知识应用总结

### 从 wechat-claude-code 学到的

1. **长轮询机制** - 35秒超时，sync buffer 管理
2. **消息去重** - Set + 淘汰策略
3. **会话状态管理** - 状态机 + AbortController
4. **流式响应** - 实时推送中间结果
5. **权限审批** - Promise + 超时处理

### 应用的设计模式

1. **适配器模式** - 统一平台接口
2. **策略模式** - 可替换 Agent
3. **路由器模式** - 消息分发
4. **状态机** - 会话生命周期
5. **观察者模式** - 事件回调

### 应用的哲学原则

1. **奥卡姆剃刀** - 保持简单
2. **SOLID 原则** - 单一职责、开闭原则
3. **DRY** - 不重复自己
4. **KISS** - 保持简单愚蠢

---

## 下一步改进

1. **完整的认证流程** - 扫码登录实现
2. **媒体处理** - 图片、文件上传下载
3. **命令系统** - /clear, /status 等
4. **权限管理** - 工具使用审批
5. **持久化** - 会话数据存储到文件/数据库
6. **日志系统** - 结构化日志
7. **监控指标** - Prometheus metrics
8. **单元测试** - 完整的测试覆盖

---

*设计者: Claude*
*日期: 2025-04-08*
*应用原则: 站在巨人的肩膀上，创造更好的轮子*
*XP: +40 (系统架构设计)*
