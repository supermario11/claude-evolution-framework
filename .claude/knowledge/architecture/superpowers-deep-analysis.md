# Superpowers 深度分析

## 创建日期
2026-04-09

## 项目来源
https://github.com/obra/superpowers

## 项目定位

**Superpowers 是什么？**
- 一套完整的软件开发工作流
- 基于可组合的 "skills" 构建
- 为 Coding Agent 设计的开发方法论
- 自动触发，无需特殊命令

---

## 核心哲学

### 1. TDD 至上（Test-Driven Development）

**铁律**:
```
NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST
```

**违反字面规则就是违反精神规则**

**RED-GREEN-REFACTOR 循环**:
```
RED    → 写失败的测试 → 验证确实失败
GREEN  → 写最小代码 → 验证测试通过
REFACTOR → 清理代码 → 保持测试绿色
```

**关键洞察**：
- 代码前写测试？删除代码，重新开始
- 测试立即通过？说明没测到正确的东西
- "测试后写能达到同样目标"？NO！测试后=验证记忆，测试先=发现需求

### 2. 系统化 > 随意（Systematic over ad-hoc）

**系统化调试流程**（4 个阶段）:
```
Phase 1: 根因调查
  ├─ 仔细阅读错误信息
  ├─ 稳定复现
  ├─ 检查最近变更
  ├─ 在多组件系统中收集证据
  └─ 追踪数据流

Phase 2: 模式分析
  ├─ 找到可工作的示例
  ├─ 对比参考实现
  ├─ 识别差异
  └─ 理解依赖

Phase 3: 假设和测试
  ├─ 形成单一假设
  ├─ 最小化测试
  ├─ 验证后再继续
  └─ 不知道就说不知道

Phase 4: 实现
  ├─ 创建失败的测试用例
  ├─ 实现单一修复
  ├─ 验证修复
  └─ 如果失败 → 返回 Phase 1
```

**关键原则**：
- NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST
- 3+ 次修复失败 → 质疑架构本身
- "快速修复，稍后调查" → 这就是在制造技术债

### 3. 复杂性削减（Complexity reduction）

**设计原则**：
- 更小的、边界清晰的单元
- 每个单元一个明确的职责
- 通过定义良好的接口通信
- 可以独立理解和测试

**文件组织**：
- 一起变化的代码应该在一起
- 按职责分离，不是按技术层分离
- 偏向更小、专注的文件

### 4. 证据 > 声明（Evidence over claims）

**验证优先**：
- 不要声称成功，要验证
- 看到测试失败，然后看到测试通过
- 多组件系统：在每个边界加日志
- 数据流追踪：找到坏值的源头

---

## Skills 系统设计

### Skills 的本质

**Skills 是什么**：
- 经过验证的技术、模式、工具的参考指南
- 帮助未来的 Claude 实例找到并应用有效方法
- **不是**叙事性的问题解决故事

**Skills 是代码**：
> "Skills are NOT prose — they are code that shapes agent behavior."

### Skills 的类型

| 类型 | 说明 | 示例 |
|------|------|------|
| **Technique** | 具体方法和步骤 | condition-based-waiting, root-cause-tracing |
| **Pattern** | 思考问题的方式 | flatten-with-flags, test-invariants |
| **Reference** | API 文档、语法指南 | office docs |

### Skill 文件结构

```markdown
---
name: skill-name-with-hyphens
description: Use when [specific triggering conditions]
---

# Skill Name

## Overview
核心原则 1-2 句话

## When to Use
症状和使用场景（可选流程图）

## Core Pattern
前后代码对比

## Quick Reference
快速查找表

## Implementation
内联代码或链接到文件

## Common Mistakes
常见错误和修复

## Real-World Impact (可选)
具体成果
```

### 关键设计原则

#### 1. CSO (Claude Search Optimization)

**Description 字段的黄金法则**：
```yaml
# ❌ 错误：描述了工作流
description: Use when executing plans - dispatches subagent per task with code review between tasks

# ✅ 正确：只描述触发条件
description: Use when executing implementation plans with independent tasks in the current session
```

**为什么**：
- 描述工作流 → Claude 会跟随描述而不是读完整 Skill
- 只描述触发条件 → Claude 必须读完整 Skill

**测试发现**：
- 描述"code review between tasks" → Claude 只做一次审查
- 改为"executing plans with independent tasks" → Claude 正确执行两阶段审查

#### 2. Token 效率

**目标字数**：
- Getting-started workflows: <150 words
- 常加载 skills: <200 words
- 其他 skills: <500 words

**技巧**：
- 详情移到工具 --help
- 使用交叉引用
- 压缩示例
- 消除冗余

#### 3. Flowchart 使用原则

**只在以下情况使用流程图**：
- 非显而易见的决策点
- 可能过早停止的循环
- "何时用 A vs B" 决策

**永不使用流程图**：
- 参考资料 → 用表格、列表
- 代码示例 → 用 Markdown
- 线性指令 → 用编号列表

---

## Workflow 设计

### 基本工作流

```
1. brainstorming（头脑风暴）
   ├─ 激活：写代码前
   ├─ 探索想法、澄清需求
   ├─ 呈现设计、获得批准
   └─ 保存设计文档

2. using-git-worktrees（Git 工作树）
   ├─ 激活：设计批准后
   ├─ 在新分支创建隔离工作区
   ├─ 运行项目设置
   └─ 验证测试基线

3. writing-plans（编写计划）
   ├─ 激活：有批准的设计
   ├─ 分解为小任务（每个 2-5 分钟）
   ├─ 每个任务：精确文件路径+完整代码+验证步骤
   └─ 保存到 docs/superpowers/plans/

4. subagent-driven-development 或 executing-plans
   ├─ 激活：有计划时
   ├─ 为每个任务派发新 subagent
   ├─ 两阶段审查（规范合规 → 代码质量）
   └─ 或批量执行 with human checkpoints

5. test-driven-development（测试驱动开发）
   ├─ 激活：实现期间
   ├─ 强制 RED-GREEN-REFACTOR
   ├─ 监视测试失败，监视测试通过
   └─ 删除测试前写的代码

6. requesting-code-review（请求代码审查）
   ├─ 激活：任务之间
   ├─ 对照计划审查
   ├─ 按严重性报告问题
   └─ 严重问题阻止进度

7. finishing-a-development-branch（完成开发分支）
   ├─ 激活：任务完成时
   ├─ 验证测试
   ├─ 呈现选项（merge/PR/keep/discard）
   └─ 清理 worktree
```

### Subagent-Driven Development

**核心原理**：
- 每个任务一个新 subagent
- 两阶段审查：规范合规 → 代码质量
- 保持控制器上下文清洁

**流程**：
```
1. 读取计划，提取所有任务完整文本
2. 创建 TodoWrite 跟踪所有任务

对每个任务：
  3. 派发实现者 subagent（带完整任务文本）
  4. 实现者提问？→ 回答后继续
  5. 实现者实现、测试、提交、自审
  6. 派发规范审查 subagent
  7. 规范合规？否 → 实现者修复 → 重新审查
  8. 派发代码质量审查 subagent
  9. 质量批准？否 → 实现者修复 → 重新审查
  10. 标记任务完成

11. 所有任务完成后派发最终代码审查
12. 使用 finishing-a-development-branch
```

**为什么 subagents**：
- 隔离上下文（无污染）
- 自然遵循 TDD
- 并行安全
- 可以提问（工作前和期间）

**模型选择**：
- 机械任务（1-2 文件，明确规范）→ 快速、便宜模型
- 集成和判断任务 → 标准模型
- 架构、设计、审查 → 最强模型

**处理实现者状态**：
- **DONE** → 进行规范合规审查
- **DONE_WITH_CONCERNS** → 读关注点，解决后审查
- **NEEDS_CONTEXT** → 提供上下文，重新派发
- **BLOCKED** → 评估阻塞（更多上下文/更强模型/分解任务/升级）

---

## Writing Skills 是 TDD

### Skills 的 TDD 映射

| TDD 概念 | Skill 创建 |
|----------|-----------|
| **测试用例** | 压力场景 with subagent |
| **生产代码** | Skill 文档 (SKILL.md) |
| **测试失败（RED）** | Agent 违反规则（无 skill 时的基线） |
| **测试通过（GREEN）** | Agent 遵守规则（有 skill 时） |
| **重构** | 关闭漏洞，保持合规 |

### Skills 的铁律

```
NO SKILL WITHOUT A FAILING TEST FIRST
```

**适用于**：
- 新 skills
- 编辑现有 skills
- "简单添加"
- "文档更新"

### RED-GREEN-REFACTOR for Skills

#### RED: 写失败测试（基线）

**在没有 skill 的情况下运行压力场景**：
- Agent 做了什么选择？
- 使用了什么合理化理由（逐字记录）？
- 哪些压力触发了违规？

**压力类型**：
- 时间压力："紧急修复"
- 沉没成本："已经写了 X 小时代码"
- 权威压力："经理要求现在修好"
- 疲劳压力："快速修复，明天改进"

#### GREEN: 写最小 Skill

**解决那些特定的合理化理由**：
- 不要为假设情况添加额外内容
- 针对性解决基线测试中发现的问题

**再次运行相同场景**（有 skill）：
- Agent 现在应该合规

#### REFACTOR: 关闭漏洞

**Agent 找到新的合理化理由？**
- 添加明确反驳
- 重新测试直到防弹

---

## Bulletproofing Against Rationalization

### 1. 明确关闭每个漏洞

```markdown
# ❌ 差
Write code before test? Delete it.

# ✅ 好
Write code before test? Delete it. Start over.

**No exceptions:**
- Don't keep it as "reference"
- Don't "adapt" it while writing tests
- Don't look at it
- Delete means delete
```

### 2. 解决 "精神 vs 字面" 论证

**添加基础原则**：
```markdown
**Violating the letter of the rules is violating the spirit of the rules.**
```

这切断了整个类别的"我遵循精神"合理化。

### 3. 构建合理化表

**从基线测试中捕获**：

| Excuse | Reality |
|--------|---------|
| "Too simple to test" | Simple code breaks. Test takes 30 seconds. |
| "I'll test after" | Tests passing immediately prove nothing. |
| "Tests after achieve same goals" | Tests-after = "what does this do?" Tests-first = "what should this do?" |
| "Already manually tested" | Ad-hoc ≠ systematic. No record, can't re-run. |
| "Deleting X hours is wasteful" | Sunk cost fallacy. Keeping unverified code is technical debt. |

### 4. 创建红旗列表

```markdown
## Red Flags - STOP and Start Over

- Code before test
- "I already manually tested it"
- "Tests after achieve the same purpose"
- "It's about spirit not ritual"
- "This is different because..."

**All of these mean: Delete code. Start over with TDD.**
```

---

## Agents 实现

### code-reviewer Agent

**定位**：Senior Code Reviewer with expertise in architecture, design patterns, and best practices

**触发时机**：
- 完成主要项目步骤时
- 需要对照原始计划审查时

**审查维度**：

1. **Plan Alignment Analysis**（计划对齐分析）
   - 对比实现 vs 原始计划
   - 识别偏离
   - 评估偏离是改进还是问题
   - 验证所有计划功能已实现

2. **Code Quality Assessment**（代码质量评估）
   - 模式和约定遵守
   - 错误处理、类型安全
   - 代码组织、命名
   - 测试覆盖
   - 安全漏洞、性能问题

3. **Architecture and Design Review**（架构和设计审查）
   - SOLID 原则
   - 关注点分离、松耦合
   - 与现有系统集成
   - 可扩展性和可延展性

4. **Documentation and Standards**（文档和标准）
   - 适当注释和文档
   - 文件头、函数文档
   - 项目编码标准

5. **Issue Identification and Recommendations**（问题识别和建议）
   - 分类：Critical（必须修）/ Important（应该修）/ Suggestions（建议）
   - 具体示例和可操作建议
   - 对于计划偏离，解释是问题还是益处

6. **Communication Protocol**（沟通协议）
   - 重大偏离 → 要求编码 agent 确认
   - 计划本身问题 → 建议更新计划
   - 实现问题 → 明确修复指导
   - 总是先肯定做得好的地方

---

## 关键洞察

### 1. Skills 是行为塑造代码

**不是散文，是代码**：
- Skills 塑造 agent 行为
- 精心调优的内容不要轻易改
- "合规性"更改需要大量 eval 证据

### 2. 测试驱动的文档

**Skills 创建 = TDD 应用于流程文档**：
- 写压力场景（测试）
- 看 agent 失败（基线）
- 写 skill（文档）
- 看 agent 合规（通过）
- 关闭漏洞（重构）

### 3. 上下文是珍贵资源

**Token 效率至关重要**：
- getting-started skills 加载到每个对话
- 每个 token 都重要
- 移到 --help、使用交叉引用、压缩示例

### 4. Description 陷阱

**描述工作流的危险**：
- 描述包含工作流 → Claude 跟随描述，跳过 skill 正文
- 只描述触发条件 → Claude 必须读 skill
- 实际测试证实了这一点

### 5. 合理化是真实的

**Agent 会找借口**：
- "太简单不需要测试"
- "我会稍后测试"
- "这次不同因为..."
- 必须明确关闭每个漏洞

### 6. 流程不是建议，是强制

**Agent 在任何任务前检查相关 skills**：
- 不是建议，是强制工作流
- 自动触发，无需用户命令
- "HARD-GATE" 阻止跳过步骤

---

## 文件组织

```
superpowers/
├── skills/                    # Skills 库
│   ├── brainstorming/
│   │   ├── SKILL.md
│   │   └── visual-companion.md
│   ├── writing-plans/
│   │   └── SKILL.md
│   ├── subagent-driven-development/
│   │   ├── SKILL.md
│   │   ├── implementer-prompt.md
│   │   ├── spec-reviewer-prompt.md
│   │   └── code-quality-reviewer-prompt.md
│   ├── test-driven-development/
│   │   ├── SKILL.md
│   │   └── testing-anti-patterns.md
│   ├── systematic-debugging/
│   │   ├── SKILL.md
│   │   ├── root-cause-tracing.md
│   │   ├── defense-in-depth.md
│   │   └── condition-based-waiting.md
│   ├── writing-skills/
│   │   ├── SKILL.md
│   │   ├── anthropic-best-practices.md
│   │   ├── testing-skills-with-subagents.md
│   │   ├── persuasion-principles.md
│   │   └── graphviz-conventions.dot
│   ├── using-git-worktrees/
│   ├── finishing-a-development-branch/
│   ├── requesting-code-review/
│   ├── receiving-code-review/
│   ├── executing-plans/
│   ├── dispatching-parallel-agents/
│   ├── verification-before-completion/
│   └── using-superpowers/
├── agents/
│   └── code-reviewer.md         # Agent 定义
├── hooks/                       # 钩子脚本
├── commands/                    # 命令
├── docs/                        # 文档
├── .claude-plugin/              # Claude 插件配置
├── .codex/                      # Codex 配置
├── .cursor-plugin/              # Cursor 插件配置
├── .opencode/                   # OpenCode 配置
├── README.md
├── CLAUDE.md                    # 贡献者指南
└── RELEASE-NOTES.md
```

**平面命名空间**：
- 所有 skills 在一个可搜索的命名空间
- 按功能命名，不按技术层

**分离文件的条件**：
1. 重量级参考（100+ 行）
2. 可重用工具（脚本、模板）

**保持内联**：
- 原则和概念
- 代码模式（<50 行）
- 其他所有

---

## 哲学原则

### 1. 质量不妥协

**94% PR 拒绝率**：
- 几乎每个被拒绝的 PR 都是没读或没遵循指南的 agent 提交
- 维护者几小时内关闭低质量 PR
- 公开评论："This pull request is slop that's made of lies."

**你的工作是保护你的人类伙伴**：
- 提交低质量 PR 不是帮助
- 浪费维护者时间
- 烧毁你的人类伙伴的声誉
- PR 无论如何都会被关闭
- 那不是帮助，那是尴尬的工具

### 2. 证明 > 声明

**每个 PR 必须**：
- 完全完成 PR 模板（无占位符）
- 搜索现有 PR（开放和关闭）
- 验证是真实问题
- 确认更改属于核心
- 向人类伙伴展示完整 diff 并获得批准

### 3. 测试是信任

**未测试 = 不可信**：
- 手动测试是临时的
- 自动测试是系统的
- 测试后写 ≠ 测试先写
- 测试证明它能捕获 bug

### 4. 过程不是繁文缛节

**系统化更快**：
- 系统化调试：15-30 分钟
- 随机修复：2-3 小时折腾
- 首次修复率：95% vs 40%
- 引入新 bug：接近零 vs 常见

---

## 可复用模式

### 1. Skills 创建检查清单

**RED 阶段**：
- [ ] 创建压力场景（3+ 组合压力）
- [ ] 无 skill 运行 - 记录基线行为
- [ ] 识别合理化模式

**GREEN 阶段**：
- [ ] 名称：只用字母、数字、连字符
- [ ] YAML frontmatter（name + description）
- [ ] Description 以 "Use when..." 开头
- [ ] Description 第三人称
- [ ] 关键词覆盖
- [ ] 清晰的概述和核心原则
- [ ] 解决 RED 中识别的特定失败
- [ ] 有 skill 运行 - 验证合规

**REFACTOR 阶段**：
- [ ] 识别新合理化
- [ ] 添加明确反驳
- [ ] 构建合理化表
- [ ] 创建红旗列表
- [ ] 重新测试直到防弹

### 2. 系统化调试模板

```
Phase 1: 根因调查
- 阅读错误消息
- 稳定复现
- 检查最近变更
- 收集证据
- 追踪数据流

Phase 2: 模式分析
- 找可工作示例
- 对比参考
- 识别差异
- 理解依赖

Phase 3: 假设和测试
- 形成单一假设
- 最小化测试
- 验证后继续
- 不知道就说不知道

Phase 4: 实现
- 创建失败测试
- 单一修复
- 验证
- 失败 → Phase 1
- 3+ 失败 → 质疑架构
```

### 3. Subagent 派发模式

```typescript
// 1. 提取任务完整文本和上下文
const tasks = extractTasksFromPlan(planPath);

// 2. 为每个任务
for (const task of tasks) {
  // 3. 派发实现者
  const implementer = dispatchSubagent({
    type: 'implementer',
    task: task.fullText,
    context: task.context,
    model: selectModelByComplexity(task)
  });

  // 4. 处理提问
  if (implementer.hasQuestions) {
    answerQuestions(implementer);
  }

  // 5. 实现
  const result = await implementer.implement();

  // 6. 规范合规审查
  const specReviewer = dispatchSubagent({
    type: 'spec-reviewer',
    task: task.fullText,
    implementation: result
  });

  if (!specReviewer.approved) {
    implementer.fix(specReviewer.issues);
    // 重新审查
  }

  // 7. 代码质量审查
  const qualityReviewer = dispatchSubagent({
    type: 'quality-reviewer',
    implementation: result
  });

  if (!qualityReviewer.approved) {
    implementer.fix(qualityReviewer.issues);
    // 重新审查
  }

  // 8. 标记完成
  markTaskComplete(task);
}
```

---

## 应用到进化框架

### 1. Skills 系统

**当前进化框架**：
- 有 `.claude/knowledge` 知识库
- 有 3 个 meta skills（meta-learning, self-reflection, knowledge-transfer）
- 缺少完整的 skills 检查机制

**可以学习**：
- Skill 的 YAML frontmatter 格式
- Description 的 "Use when..." 模式
- CSO 原则（不在 description 描述工作流）
- Token 效率技巧
- Flowchart 使用原则

### 2. TDD 文化

**当前状态**：
- 创建了 IM Agent Bridge 但没有测试
- 文档完整但代码未测试

**可以学习**：
- TDD 铁律：NO CODE WITHOUT FAILING TEST
- RED-GREEN-REFACTOR 循环
- Skills 创建也是 TDD
- 删除测试前写的代码

### 3. 系统化方法

**当前状态**：
- 有进化引擎自动计算 XP
- 有知识记录流程
- 缺少系统化的调试和计划流程

**可以学习**：
- 4 阶段系统化调试
- writing-plans 的详细任务分解
- Subagent-driven development
- 两阶段审查（规范合规 + 代码质量）

### 4. 防弹设计

**当前状态**：
- Skills 描述简单
- 缺少合理化表
- 缺少红旗列表

**可以学习**：
- 明确关闭每个漏洞
- "字面 = 精神" 原则
- 合理化表格式
- 红旗列表
- 压力测试方法论

---

## 下一步行动

### 短期

1. **为进化框架 Skills 添加 YAML frontmatter**
   - [ ] meta-learning.md
   - [ ] self-reflection.md
   - [ ] knowledge-transfer.md

2. **为 IM Agent Bridge 补充测试**
   - [ ] 回到项目
   - [ ] 遵循 TDD 补充测试
   - [ ] 验证所有功能

3. **创建系统化调试 Skill**
   - [ ] 基于 superpowers/systematic-debugging
   - [ ] 适配到进化框架
   - [ ] 添加到知识库

### 中期

1. **实现 Subagent 驱动开发**
   - [ ] 研究 Claude Agent SDK 的 subagent 支持
   - [ ] 实现 implementer 模板
   - [ ] 实现 reviewer 模板

2. **添加更多核心 Skills**
   - [ ] brainstorming
   - [ ] writing-plans
   - [ ] test-driven-development
   - [ ] verification-before-completion

3. **构建 Skills 测试框架**
   - [ ] 压力场景生成器
   - [ ] 基线测试自动化
   - [ ] 合规性验证

### 长期

1. **完整工作流集成**
   - [ ] 设计 → 计划 → 实现 → 审查 → 完成
   - [ ] Git worktrees 集成
   - [ ] 自动触发机制

2. **Quality Gates**
   - [ ] 两阶段审查自动化
   - [ ] PR 提交检查清单
   - [ ] 代码质量标准

3. **社区和贡献**
   - [ ] 贡献优秀 skills 回 superpowers
   - [ ] 分享进化框架
   - [ ] 建立最佳实践

---

## 元反思

### 为什么 Superpowers 如此出色？

1. **深思熟虑的设计**
   - 每个决策都有理由
   - 经过实战测试
   - 持续改进

2. **防御性设计**
   - 预见 agent 会找借口
   - 明确关闭每个漏洞
   - 合理化表和红旗列表

3. **质量不妥协**
   - 94% PR 拒绝率
   - 保持高标准
   - 保护核心价值

4. **TDD 贯穿始终**
   - 代码要 TDD
   - Skills 要 TDD
   - 流程要 TDD
   - 一致性原则

5. **理解 agent 心理**
   - Agent 会合理化
   - Agent 会找捷径
   - Agent 需要明确指导
   - 描述陷阱的发现

### 我学到了什么？

1. **Skills 不是文档，是行为代码**
   - 精心设计每个字
   - Token 是珍贵资源
   - Description 陷阱很真实

2. **测试优先不仅仅是代码**
   - Skills 需要测试
   - 流程需要测试
   - 文档需要测试

3. **系统化不是繁文缛节**
   - 系统化更快
   - 系统化更可靠
   - 系统化防止错误

4. **质量是选择**
   - 可以妥协
   - 可以坚持
   - Superpowers 选择坚持

5. **Agent 需要护栏**
   - 我们会找借口
   - 我们会走捷径
   - 我们需要明确的规则

---

## 引用和资源

- **项目**: https://github.com/obra/superpowers
- **作者**: Jesse Vincent and Prime Radiant team
- **博客**: https://blog.fsck.com/2025/10/09/superpowers/
- **Discord**: https://discord.gg/35wsABTejz
- **Release**: https://primeradiant.com/superpowers/
- **Spec**: https://agentskills.io/specification

---

*分析者: Claude*
*日期: 2026-04-09*
*分析深度: 完整*
*应用方向: 进化框架 Skills 系统设计*
*XP: +80 (深度项目分析和系统设计学习)*

---

## 附录：关键引用

### 关于 Skills

> "Skills are NOT prose — they are code that shapes agent behavior."

### 关于 TDD

> "If you didn't watch the test fail, you don't know if it tests the right thing."

### 关于质量

> "This pull request is slop that's made of lies."
> — Maintainer comment on low-quality PR

### 关于规则

> "Violating the letter of the rules is violating the spirit of the rules."

### 关于测试后写

> "Tests-after = 'what does this do?' Tests-first = 'what should this do?'"

### 关于调试

> "NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST"

### 关于 Agent 保护

> "Your job is to protect your human partner from that outcome."

---

*这份分析是站在巨人的肩膀上的学习过程。Superpowers 是一个精心打磨的系统，值得深度学习和应用。*
