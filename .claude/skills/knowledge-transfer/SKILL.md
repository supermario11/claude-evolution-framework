# Knowledge Transfer Skill：跨项目知识迁移

## 目标
将从一个项目学到的知识迁移并应用到另一个项目

## 输入参数
- `--source <concept>`: 源知识（如"Claude Code Streaming"）
- `--target <context>`: 目标场景（如"iOS Network Layer"）
- `--type <transfer_type>`: 迁移类型（direct/adapted/inspired）

## 迁移类型

### 1. Direct Transfer（直接迁移）
源概念可以直接应用，无需修改

**示例**: 设计模式、算法
```
Claude Code: Singleton Pattern
    ↓ (直接迁移)
iOS Project: Singleton Pattern
```

### 2. Adapted Transfer（适配迁移）
需要根据语言/平台特性调整

**示例**: 语言特性、API 设计
```
Claude Code: AsyncGenerator<Message> (TypeScript)
    ↓ (适配为)
iOS Project: AsyncStream<Message> (Swift)
```

### 3. Inspired Transfer（启发式迁移）
借鉴思想，重新设计实现

**示例**: 架构理念、系统设计
```
Claude Code: QueryEngine 查询引擎
    ↓ (启发设计)
iOS Project: RVRequestManager 请求管理器
```

## 工作流程

### 阶段 1: 源知识分析 (Source Analysis)

```markdown
## 源知识：Claude Code Streaming Architecture

### 核心概念
使用 AsyncGenerator 实现流式输出

### 关键代码
\`\`\`typescript
async *submitMessage(prompt: string) {
  for await (const message of query()) {
    yield message
  }
}
\`\`\`

### 核心价值
- 实时响应
- 内存高效
- 用户体验好

### 技术依赖
- TypeScript AsyncGenerator
- for await...of 循环
```

### 阶段 2: 目标场景映射 (Target Mapping)

```markdown
## 目标场景：iOS Network Layer

### 当前实现
使用 completion handlers 或 Combine

\`\`\`swift
func fetchData(completion: @escaping (Result<Data, Error>) -> Void) {
    // 网络请求
    completion(.success(data))
}
\`\`\`

### 痛点
- 无法实时反馈进度
- 大文件下载卡顿
- 用户体验差

### 映射关系
| Claude Code | iOS 对应 | 可行性 |
|------------|----------|--------|
| AsyncGenerator | AsyncStream | ✅ 直接适用 |
| yield | AsyncStream.Continuation.yield | ✅ 直接适用 |
| for await | for await in | ✅ 直接适用 |
```

### 阶段 3: 适配转换 (Adaptation)

```swift
// 迁移后的代码
class RVNetworkManager {
    func fetchDataStream(from url: URL) -> AsyncStream<Data> {
        AsyncStream { continuation in
            Task {
                do {
                    let (bytes, response) = try await URLSession.shared.bytes(from: url)

                    for try await byte in bytes {
                        // 实时产出数据
                        continuation.yield(byte)
                    }

                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}

// 使用
for await data in networkManager.fetchDataStream(from: url) {
    // 实时处理数据
    updateProgress(data)
}
```

### 阶段 4: 差异分析 (Difference Analysis)

```markdown
## 差异点

### 语法差异
- TypeScript: `async *function()` → Swift: `AsyncStream`
- TypeScript: `yield` → Swift: `continuation.yield()`

### 语义差异
- TypeScript 自动处理取消 → Swift 需要手动处理 Task 取消
- TypeScript Generator 是惰性的 → Swift AsyncStream 立即执行

### 最佳实践差异
- TypeScript: 偏好 Generator
- Swift: 偏好 AsyncStream 或 Combine
```

### 阶段 5: 验证测试 (Validation)

```swift
// 单元测试
func testStreamingFetch() async throws {
    let manager = RVNetworkManager()
    var receivedData: [Data] = []

    for await data in manager.fetchDataStream(from: testURL) {
        receivedData.append(data)
    }

    XCTAssertFalse(receivedData.isEmpty)
    XCTAssertEqual(receivedData.count, expectedCount)
}

// 性能测试
func testStreamingPerformance() async throws {
    measure {
        // 对比传统方式和流式方式
    }
}
```

### 阶段 6: 文档化 (Documentation)

```bash
# 存储到知识库
cat > .claude/knowledge/patterns/streaming-ios.md <<EOF
# 流式架构在 iOS 中的应用

## 源知识
Claude Code 的 AsyncGenerator 流式架构

## 迁移方案
使用 Swift AsyncStream 实现

## 代码示例
[...]

## 应用效果
- 响应速度提升 60%
- 内存使用降低 35%
- 用户体验显著改善

## 参考资源
- 源代码: Claude Code QueryEngine.ts
- Apple 文档: AsyncStream
- 相关模式: Reactive Streams
EOF
```

## 迁移策略

### 策略矩阵

| 源类型 | 目标平台 | 推荐策略 | 难度 |
|--------|---------|---------|------|
| 设计模式 | 任意 | Direct | ⭐☆☆☆☆ |
| 架构模式 | 同类型 | Adapted | ⭐⭐⭐☆☆ |
| 语言特性 | 不同语言 | Adapted | ⭐⭐⭐⭐☆ |
| 系统设计 | 不同领域 | Inspired | ⭐⭐⭐⭐⭐ |

### 成功标准

| 标准 | 说明 | 权重 |
|------|------|------|
| **正确性** | 功能完全实现 | 40% |
| **性能** | 不低于原实现 | 30% |
| **可维护性** | 代码清晰易懂 | 20% |
| **适配度** | 符合目标平台最佳实践 | 10% |

## 输出

- **迁移代码**: 完整的实现代码
- **测试用例**: 验证迁移正确性
- **知识文档**: `.claude/knowledge/patterns/xxx-migrated.md`
- **经验值**: +50 XP（成功迁移）

## 示例场景

### 场景 1: 工具系统迁移
```bash
claude --skill knowledge-transfer \
  --source "Claude Code Tool System" \
  --target "Riva-iOS Agent Tools" \
  --type adapted
```

### 场景 2: 状态机迁移
```bash
claude --skill knowledge-transfer \
  --source "Query Pipeline State Machine" \
  --target "PR Creation Flow" \
  --type inspired
```

### 场景 3: 压缩策略迁移
```bash
claude --skill knowledge-transfer \
  --source "Multi-layer Compression" \
  --target "iOS Memory Management" \
  --type adapted
```

## 迁移清单

### 迁移前
- [ ] 充分理解源知识
- [ ] 分析目标场景需求
- [ ] 评估技术可行性
- [ ] 准备测试环境

### 迁移中
- [ ] 实现核心功能
- [ ] 编写单元测试
- [ ] 性能对比测试
- [ ] 代码审查

### 迁移后
- [ ] 文档化过程和结果
- [ ] 记录经验教训
- [ ] 更新知识库
- [ ] 分享给团队

## 进化追踪

每次成功迁移会：
- 增加 `learning_stats.skills_acquired`
- 获得 +50 XP
- 记录到 `evolution-log`
- 扩展 `specializations`

## 失败处理

如果迁移失败：
1. 分析失败原因
2. 调整迁移策略
3. 记录到 `lessons-learned`
4. 规划下次改进
