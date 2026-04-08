# Self-Reflection Skill：自我反思与优化

## 目标
定期回顾学习效果，发现知识缺口，优化学习方法

## 触发时机
- **手动触发**: `claude --skill self-reflection`
- **每周自动**: 每周日由 evolution-engine.sh 触发
- **任务完成后**: 完成大型任务后主动反思

## 反思维度

### 1. 效果评估 (Effectiveness Evaluation)

#### 模板
```markdown
## 最近完成的任务
- 任务名称: XXX
- 预期目标: XXX
- 实际结果: ✅ 成功 / ❌ 失败 / ⚠️ 部分成功

### 量化指标
- 时间: 预估 Xh, 实际 Xh (偏差: ±X%)
- 质量: 预估 X分, 实际 X分
- 影响: 预估提升 X%, 实际提升 X%

### 定性评价
- 用户满意度: ⭐⭐⭐⭐⭐
- 代码质量: ⭐⭐⭐⭐☆
- 可维护性: ⭐⭐⭐⭐☆
```

### 2. 方法分析 (Methodology Analysis)

#### 有效的方法 ✅
```markdown
## 成功案例
- 并行分析多个模块 → 效率提升 40%
- 使用 Task 工具深度探索 → 发现更多模式
- 先建立代码地图再深入 → 全局视角更清晰
```

#### 无效的方法 ❌
```markdown
## 失败案例
- 一次性读取所有代码 → 超出 context 限制
- 没有分批处理 → 分析不够深入
- 忽略文档 → 误解设计意图
```

#### 改进方向 💡
```markdown
## 优化建议
- 采用增量分析策略
- 先看文档再看代码
- 建立检查清单
```

### 3. 知识缺口分析 (Knowledge Gap Analysis)

#### 发现的盲区
```markdown
## 需要学习的领域
- [ ] Swift 并发编程 (async/await)
  - 原因: 分析异步代码时理解困难
  - 优先级: ⭐⭐⭐⭐⭐
  - 预计时间: 2 天

- [ ] SnapKit 高级用法
  - 原因: 部分布局代码看不懂
  - 优先级: ⭐⭐⭐⭐☆
  - 预计时间: 1 天

- [ ] iOS 性能优化工具
  - 原因: 无法量化性能改进
  - 优先级: ⭐⭐⭐☆☆
  - 预计时间: 3 天
```

#### 学习计划
```markdown
## 本周学习目标
1. 阅读 Swift Concurrency 官方文档
2. 分析 SnapKit 源码核心部分
3. 学习 Instruments 基本使用

## 学习资源
- 文档: https://docs.swift.org/swift-book/
- 教程: XXX
- 实践项目: XXX
```

### 4. 行动计划 (Action Plan)

#### 下次改进
```markdown
## 具体行动项
- [ ] 建立标准分析流程
- [ ] 创建分析模板
- [ ] 限制单次分析代码量 (<10000行)
- [ ] 先用 Glob 找文件，再用 Read 读取
- [ ] 并行分析独立模块
```

#### 工具优化
```markdown
## 需要的工具
- [ ] 代码复杂度分析工具
- [ ] 依赖关系可视化工具
- [ ] 性能基准测试脚本
```

### 5. 成长追踪 (Growth Tracking)

#### 能力提升
```markdown
## 本周成长
- 知识深度: Level 3 → Level 4
- 分析速度: +25%
- 模式识别: 新增 8 个模式

## 里程碑
- 🎉 首次完成 50万行代码分析
- 🎉 首次提取完整架构设计
- 🎉 首次设计进化框架
```

## 工作流程

### 步骤 1: 收集数据
```bash
# 读取最近的活动日志
tail -n 100 .claude/knowledge/evolution-log/*.md

# 统计新增知识
find .claude/knowledge -type f -mtime -7 | wc -l

# 读取当前配置
cat .claude/evolution-config.json
```

### 步骤 2: 分析数据
- 对比预期与实际
- 识别成功模式
- 发现失败原因
- 提取改进机会

### 步骤 3: 生成报告
```bash
# 创建反思报告
cat > .claude/knowledge/evolution-log/$(date +%Y-%m-%d)-reflection.md <<EOF
# 反思报告 $(date +%Y-%m-%d)

[完整的反思内容]
EOF
```

### 步骤 4: 更新配置
```bash
# 更新学习目标
jq '.goals.short_term += ["新目标"]' .claude/evolution-config.json

# 添加专长
jq '.evolution.specializations += ["新专长"]' .claude/evolution-config.json
```

## 输出

- **反思报告**: `.claude/knowledge/evolution-log/YYYY-MM-DD-reflection.md`
- **行动计划**: 更新后的 `evolution-config.json`
- **经验值**: +30 XP（完成反思）

## 示例用法

```bash
# 手动触发反思
claude --skill self-reflection

# 查看最新反思
cat .claude/knowledge/evolution-log/$(date +%Y-%m-%d)-reflection.md

# 检查行动计划
jq '.goals' .claude/evolution-config.json
```

## 反思频率建议

| 频率 | 内容 | 时长 | XP奖励 |
|------|------|------|--------|
| **每日** | 简要回顾今日学习 | 5 分钟 | +5 XP |
| **每周** | 深度分析本周成长 | 30 分钟 | +30 XP |
| **每月** | 知识整合与规划 | 2 小时 | +100 XP |

## 反思质量标准

### 高质量反思 ⭐⭐⭐⭐⭐
- 数据充分（有具体案例和数字）
- 分析深入（有根因分析）
- 行动明确（有具体改进计划）
- 可追踪（有量化指标）

### 低质量反思 ⭐☆☆☆☆
- 泛泛而谈（没有具体例子）
- 流于表面（只描述现象）
- 缺乏行动（没有改进计划）
- 无法验证（没有指标）

## 进化追踪

每次反思会自动：
- 记录到 `evolution-log`
- 增加 `experience_points`
- 更新 `goals` 和 `specializations`
- 触发成长评估
