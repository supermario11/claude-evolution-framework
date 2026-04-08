# Meta-Learning Skill：学习如何学习

## 目标
自动分析代码库，提取可复用的架构知识和设计模式

## 输入参数
- `--input <description>`: 学习目标（如"分析项目架构"）
- `--path <directory>`: 项目路径（默认：当前目录）
- `--depth <level>`: 分析深度（quick/medium/thorough，默认：medium）

## 工作流程

### 阶段 1：项目扫描 (Scanning)

```bash
# 1. 统计项目规模
find . -type f | wc -l
du -sh .

# 2. 识别技术栈
# - 检查配置文件（package.json, Podfile, build.gradle等）
# - 分析文件扩展名分布

# 3. 构建文件树
tree -L 3 -I 'node_modules|Pods|build' > /tmp/project-structure.txt
```

### 阶段 2：模式识别 (Pattern Recognition)

扫描并识别以下模式：

#### 架构模式
- [ ] MVC (Model-View-Controller)
- [ ] MVVM (Model-View-ViewModel)
- [ ] VIPER (View-Interactor-Presenter-Entity-Router)
- [ ] Clean Architecture
- [ ] Layered Architecture

#### 设计模式
- [ ] Singleton（单例）
- [ ] Factory（工厂）
- [ ] Builder（建造者）
- [ ] Observer（观察者）
- [ ] Strategy（策略）
- [ ] Dependency Injection（依赖注入）

#### 命名规范
- 类名规范
- 文件组织方式
- 前缀使用

### 阶段 3：知识提取 (Knowledge Extraction)

对于每个发现的模式：

1. **记录定义**
   ```markdown
   ## 模式名称
   简要说明这个模式的用途
   ```

2. **提取代码示例**
   ```swift
   // 实际代码片段
   class SingletonExample {
       static let shared = SingletonExample()
       private init() {}
   }
   ```

3. **标注使用场景**
   - ✅ 适用：全局配置管理
   - ❌ 不适用：需要多实例的场景

4. **评估优缺点**
   - 优点：全局唯一访问点
   - 缺点：难以测试、隐藏依赖

### 阶段 4：知识存储 (Storage)

```bash
# 存储架构知识
cat > .claude/knowledge/architecture/discovered-architecture.md <<EOF
# 项目架构分析

## 架构类型
MVVM

## 目录结构
- Models/
- Views/
- ViewModels/
- Services/

## 特点
- 清晰的职责分离
- 数据绑定机制
...
EOF

# 存储设计模式
cat > .claude/knowledge/patterns/singleton-pattern.md <<EOF
# Singleton 模式

## 定义
...

## 代码示例
...
EOF
```

### 阶段 5：交叉验证 (Cross-Validation)

与已有知识对比：
- **重复**？→ 合并或更新
- **冲突**？→ 标记待确认
- **互补**？→ 建立关联

### 阶段 6：生成报告 (Reporting)

```markdown
# Meta-Learning 报告

## 项目概览
- 名称: XXX
- 规模: XXX files, XXX lines
- 技术栈: Swift, UIKit, SnapKit

## 发现的模式
1. MVVM 架构
2. Dependency Injection
3. Repository Pattern

## 新增知识
- 3 个架构模式
- 5 个设计模式
- 12 个代码片段

## 建议
- 统一命名规范
- 增加单元测试
...
```

## 输出

- **知识库更新**: `.claude/knowledge/` 下新增条目
- **分析报告**: `.claude/knowledge/evolution-log/YYYY-MM-DD-meta-learning.md`
- **经验值**: +50 XP（发现新模式每个 +10 XP）

## 示例用法

```bash
# 快速扫描
claude --skill meta-learning --input "快速了解项目结构" --depth quick

# 深度分析
claude --skill meta-learning --input "全面分析架构和设计模式" --depth thorough

# 指定路径
claude --skill meta-learning --input "分析 iOS 项目" --path ~/Projects/MyApp
```

## 注意事项

- 大型项目建议先运行 quick 模式
- 分析过程会生成临时文件在 `/tmp/`
- 定期清理 evolution-log 避免文件过多

## 进化追踪

每次运行会自动：
- 更新 `learning_stats.patterns_discovered`
- 增加 `experience_points`
- 记录到 `evolution-log`
