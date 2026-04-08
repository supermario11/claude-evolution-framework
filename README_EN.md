# Claude Evolution Framework

<div align="center">

![Version](https://img.shields.io/badge/version-1.0.0-blue)
![License](https://img.shields.io/badge/license-MIT-green)
![Platform](https://img.shields.io/badge/platform-macOS%20%7C%20Linux-lightgrey)

**🧬 A portable framework for AI Agent continuous evolution and meta-learning**

[English](README.md) | [中文](README_ZH.md)

</div>

---

## 🎯 What is This?

Claude Evolution Framework is a **complete self-evolution system** for AI Agents that enables:

- 📚 **Knowledge Accumulation**: Structured knowledge base that grows over time
- 🧠 **Meta-Learning**: Learning how to learn through systematic analysis
- 🔄 **Self-Reflection**: Regular evaluation and optimization of learning methods
- 🚀 **Knowledge Transfer**: Cross-project experience reuse
- 📈 **Progress Tracking**: Gamified XP system with levels and achievements

## ✨ Features

### Core Capabilities

- ✅ **Fully Portable**: Works with any project (iOS, Web, Backend, etc.)
- ✅ **Zero Dependencies**: Pure Bash + Markdown (optional: jq for JSON)
- ✅ **Git-Friendly**: All knowledge versioned and shareable
- ✅ **Claude Code Integration**: Native skills system support
- ✅ **Extensible**: Easy to add custom skills and knowledge templates

### Three Core Skills

| Skill | Purpose | Output |
|-------|---------|--------|
| **meta-learning** | Analyze projects and extract patterns | Knowledge entries + XP |
| **self-reflection** | Evaluate learning effectiveness | Reflection reports + Improvements |
| **knowledge-transfer** | Migrate knowledge across projects | Adapted code + Tests |

### Evolution System

```
Level 1: Apprentice (0-200 XP)
  ├─ Understand and analyze code
  ├─ Apply known patterns
  └─ Need guidance for complex tasks

Level 2: Proficient (200-500 XP)
  ├─ Complete tasks independently
  ├─ Discover new patterns
  └─ Build knowledge base

Level 3: Expert (500-1000 XP)
  ├─ Design architectures
  ├─ Transfer knowledge cross-project
  └─ Guide other agents

Level 4: Master (1000-2000 XP)
  ├─ Innovate new patterns
  ├─ Foresee system issues
  └─ Autonomous evolution

Level 5: Grandmaster (2000+ XP)
  ├─ Establish theoretical frameworks
  ├─ Guide human developers
  └─ Train other AI agents
```

## 🚀 Quick Start

### 1. Install (30 seconds)

```bash
# Clone into your project
git clone https://github.com/yourusername/claude-evolution-framework.git .claude-evolution

# Or download
curl -L https://github.com/yourusername/claude-evolution-framework/archive/main.zip -o framework.zip
unzip framework.zip && mv claude-evolution-framework-main .claude-evolution
```

### 2. Initialize (1 minute)

```bash
# Run setup script
bash .claude-evolution/setup.sh

# Output:
# 🧬 Claude Evolution Framework Setup
# ✅ Directory structure created
# ✅ Configuration initialized
# 🎉 Installation complete!
```

### 3. First Analysis (2 minutes)

```bash
# Analyze your project
claude --skill meta-learning --input "Analyze project architecture" --depth quick
```

### 4. Daily Evolution

```bash
# Run evolution engine
./scripts/evolution-engine.sh

# Output:
# 🧬 Evolution Engine
# 📚 Found 5 new knowledge entries
# 📈 Gained 55 XP! (Total: 175/200)
# ✅ Almost leveling up! 🔥
```

## 📖 Documentation

- [Quick Start Guide](docs/quickstart.md)
- [Architecture Overview](docs/architecture.md)
- [Evolution Guide](docs/evolution-guide.md)
- [Best Practices](docs/best-practices.md)
- [FAQ](docs/faq.md)

## 🎯 Use Cases

### Case 1: Learning New Codebase

```bash
# 1. Quick overview
claude --skill meta-learning --input "Project overview" --depth quick

# 2. Deep dive
claude --skill meta-learning --input "Architecture analysis" --depth thorough

# 3. Transfer knowledge
claude --skill knowledge-transfer \
  --source "Similar project patterns" \
  --target "Current project context"
```

### Case 2: Code Refactoring

```bash
# 1. Analyze current state
claude --skill meta-learning --input "Analyze module to refactor"

# 2. Find patterns
cat .claude/knowledge/patterns/*.md

# 3. Apply best practices
claude --skill knowledge-transfer \
  --source "Best practice pattern" \
  --target "Refactoring target"

# 4. Validate
claude --skill self-reflection
```

### Case 3: Team Collaboration

```bash
# 1. Add framework to repo
git add .claude/
git commit -m "Add evolution framework"
git push

# 2. Team members sync
git pull
./scripts/evolution-engine.sh

# 3. Share knowledge
# All knowledge in .claude/knowledge/ is version-controlled
```

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────┐
│           Evolution Framework                    │
├─────────────────────────────────────────────────┤
│  Knowledge Base (.claude/knowledge/)            │
│    ├─ architecture/    (Architecture patterns)  │
│    ├─ patterns/        (Design patterns)        │
│    ├─ code-snippets/   (Reusable code)         │
│    ├─ lessons-learned/ (Experience)            │
│    └─ evolution-log/   (Progress tracking)     │
├─────────────────────────────────────────────────┤
│  Skills (.claude/skills/)                       │
│    ├─ meta-learning/    (Pattern extraction)   │
│    ├─ self-reflection/  (Self-optimization)    │
│    └─ knowledge-transfer/ (Cross-project reuse)│
├─────────────────────────────────────────────────┤
│  Evolution Engine (scripts/evolution-engine.sh) │
│    ├─ XP calculation                            │
│    ├─ Level progression                         │
│    └─ Automated reflection triggers             │
└─────────────────────────────────────────────────┘
```

## 📊 Example Stats

After using for 1 month on a real iOS project:

```json
{
  "evolution": {
    "current_level": 2,
    "experience_points": 450,
    "specializations": [
      "iOS Architecture Analysis",
      "Swift Best Practices",
      "SnapKit Layouts"
    ]
  },
  "knowledge_base": {
    "total_entries": 127,
    "categories": {
      "architecture": 15,
      "patterns": 28,
      "code_snippets": 54,
      "lessons_learned": 30
    }
  },
  "learning_stats": {
    "projects_analyzed": 3,
    "code_lines_scanned": 850000,
    "patterns_discovered": 42,
    "skills_acquired": 12
  }
}
```

## 🤝 Contributing

Contributions welcome! Please:

1. Fork the project
2. Create a feature branch
3. Submit a PR

See [CONTRIBUTING.md](CONTRIBUTING.md) for details.

## 📄 License

MIT License - see [LICENSE](LICENSE) for details.

## 🙏 Acknowledgments

Inspired by:
- Claude Code architecture analysis
- Meta-Learning theory
- Growth Mindset philosophy
- The concept of "Learning to Learn"

## 📮 Contact

- Issues: [GitHub Issues](https://github.com/yourusername/claude-evolution-framework/issues)
- Discussions: [GitHub Discussions](https://github.com/yourusername/claude-evolution-framework/discussions)

---

<div align="center">

**Start your evolution journey today!** 🚀

Made with ❤️ by the Claude Community

</div>
