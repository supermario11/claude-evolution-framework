# 快速开始指南

## 5 分钟上手 Claude Evolution Framework

### 步骤 1: 安装框架（30 秒）

```bash
# 克隆框架
cd /path/to/your-project
git clone https://github.com/yourusername/claude-evolution-framework.git .claude-evolution

# 或者直接下载
curl -L https://github.com/yourusername/claude-evolution-framework/archive/main.zip -o framework.zip
unzip framework.zip
mv claude-evolution-framework-main .claude-evolution
```

### 步骤 2: 初始化（1 分钟）

```bash
# 运行安装脚本
bash .claude-evolution/setup.sh

# 输出示例：
# 🧬 Claude Evolution Framework 安装程序
# =========================================
#
# 目标项目: /path/to/your-project
# 📁 创建目录结构...
# ⚙️  复制配置文件...
# ✅ evolution-config.json 已��建
# ...
# 🎉 安装完成！
```

### 步骤 3: 第一次分析（2 分钟）

```bash
# 分析项目结构
claude --skill meta-learning --input "分析项目架构" --depth quick
```

**你会看到**：
- 自动扫描项目文件
- 识别技术栈和架构模式
- 提取设计模式
- 生成知识条目

### 步骤 4: 查看结果（1 分钟）

```bash
# 查看新增的知识
ls .claude/knowledge/

# 查看分析报告
cat .claude/knowledge/evolution-log/$(date +%Y-%m-%d)-meta-learning.md

# 查看进化状态
cat .claude/evolution-config.json | jq '.evolution'
```

### 步骤 5: 开始进化！

```bash
# 每天运行进化引擎
./scripts/evolution-engine.sh

# 输出示例：
# 🧬 Claude Evolution Framework
# ==============================
#
# Agent ID: my-project-evolution-agent
# 当前等级: Level 1
# 经验值: 60 / 200
#
# 📚 扫描新知识...
#   ✓ 发现 5 个新知识条目
#     - 设计模式: 2
#     - 经验教训: 2
#     - 代码片段: 1
#
# 📈 获得 55 XP! (总计: 60)
```

---

## 完整示例：从零到专家

### Week 1: 建立基础

```bash
# Day 1: 初始化
bash .claude-evolution/setup.sh

# Day 2-3: 分析现有项目
claude --skill meta-learning --input "深度分析架构" --depth thorough

# Day 4-5: 知识迁移
claude --skill knowledge-transfer \
  --source "从其他项目学到的模式" \
  --target "当前项目场景"

# Day 6-7: 首次反思
claude --skill self-reflection
```

**预期结果**：
- 知识库: ~20 条
- 等级: Level 1 (150/200 XP)
- 技能: 3 个

### Week 2: 深化学习

```bash
# 继续分析新模块
claude --skill meta-learning --input "分析网络层实现"
claude --skill meta-learning --input "分析UI组件设计"

# 实践知识迁移
claude --skill knowledge-transfer \
  --source "Claude Code Streaming" \
  --target "iOS Network Layer"

# 每日进化
./scripts/evolution-engine.sh  # 每天执行
```

**预期结果**：
- 知识库: ~50 条
- 等级: Level 2 (50/500 XP)
- 技能: 5 个
- 首次升级 🎉

### Month 1: 成为熟练工

```bash
# 建立专业知识库
- 架构模式: 10+ 条
- 设计模式: 15+ 条
- 代码片段: 30+ 条
- 经验教训: 20+ 条

# 开发自定义 Skill
# 创建 .claude/skills/my-custom-skill/SKILL.md
```

**预期结果**：
- 知识库: ~100 条
- 等级: Level 2 (400/500 XP)
- 技能: 8 个
- 专业领域: 3 个

### Month 3: 达到专家级

**预期结果**：
- 等级: Level 3
- 可以指导团队
- 建立完整的知识体系
- 开发多个自定义工具

---

## 常见使用场景

### 场景 1: 学习新项目

```bash
# 1. 快速了解
claude --skill meta-learning --input "项目概览" --depth quick

# 2. 深入分析
claude --skill meta-learning --input "架构深度分析" --depth thorough

# 3. 知识迁移
claude --skill knowledge-transfer \
  --source "已知的类似项目经验" \
  --target "新项目特定场景"
```

### 场景 2: 代码重构

```bash
# 1. 分析现状
claude --skill meta-learning --input "分析需要重构的模块"

# 2. 寻找模式
# 查看知识库中的最佳实践
cat .claude/knowledge/patterns/*.md

# 3. 应用模式
claude --skill knowledge-transfer \
  --source "最佳实践模式" \
  --target "重构目标"

# 4. 验证效果
claude --skill self-reflection
```

### 场景 3: 团队协作

```bash
# 1. 建立团队知识库
# 将框架添加到项目仓库
git add .claude/
git commit -m "Add evolution framework"
git push

# 2. 团队成员同步
git pull
./scripts/evolution-engine.sh

# 3. 共享知识
# 所有知识条目都在 .claude/knowledge/ 下
# 通过 Git 同步
```

---

## 进阶技巧

### 技巧 1: 自定义经验值规则

编辑 `scripts/evolution-engine.sh`：

```bash
# 自定义 XP 计算
if [ -f "test-passed.flag" ]; then
    XP_GAIN=$((XP_GAIN + 100))  # 测试通过奖励
fi

if [ $CODE_QUALITY_SCORE -gt 90 ]; then
    XP_GAIN=$((XP_GAIN + 50))   # 高质量代码奖励
fi
```

### 技巧 2: 集成到 CI/CD

```yaml
# .github/workflows/evolution.yml
name: Evolution Tracking

on:
  push:
    branches: [main]

jobs:
  track:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run Evolution Engine
        run: ./scripts/evolution-engine.sh
      - name: Commit Updated Stats
        run: |
          git config user.name "Evolution Bot"
          git add .claude/evolution-config.json
          git commit -m "Update evolution stats"
          git push
```

### 技巧 3: 可视化进化过程

```bash
# 安装可视化工具
npm install -g evolution-visualizer

# 生成进化图表
evolution-visualizer .claude/evolution-config.json --output evolution-chart.png
```

---

## 故障排除

### 问题 1: jq 命令未找到

```bash
# macOS
brew install jq

# Ubuntu/Debian
sudo apt-get install jq

# CentOS/RHEL
sudo yum install jq
```

### 问题 2: Skill 未生效

```bash
# 检查 Skill 文件是否存在
ls -la .claude/skills/*/SKILL.md

# 验证 Skill 语法
claude --skill meta-learning --help
```

### 问题 3: 权限问题

```bash
# 给脚本添加执行权限
chmod +x scripts/*.sh
chmod +x .claude-evolution/setup.sh
```

---

## 下一步

- 📖 阅读 [架构说明](architecture.md)
- 🎓 学习 [进化指南](evolution-guide.md)
- 💡 查看 [最佳实践](best-practices.md)
- 🤝 加入社区讨论

---

**开始你的进化之旅！** 🚀

有问题？查看 [FAQ](faq.md) 或提交 [Issue](https://github.com/yourusername/claude-evolution-framework/issues)
