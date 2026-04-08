#!/bin/bash

# Claude Evolution Framework - 一键安装脚本
# Usage: bash setup.sh [project-path]

set -e

PROJECT_PATH="${1:-.}"
FRAMEWORK_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "🧬 Claude Evolution Framework 安装程序"
echo "========================================="
echo ""
echo "目标项目: $PROJECT_PATH"
echo "框架路径: $FRAMEWORK_DIR"
echo ""

# 1. 创建目录结构
echo "📁 创建目录结构..."
mkdir -p "$PROJECT_PATH/.claude/knowledge"/{architecture,patterns,code-snippets,lessons-learned,evolution-log}
mkdir -p "$PROJECT_PATH/.claude/skills"/{meta-learning,self-reflection,knowledge-transfer}
mkdir -p "$PROJECT_PATH/.claude/templates"
mkdir -p "$PROJECT_PATH/scripts"

# 2. 复制配置文件
echo "⚙️  复制配置文件..."
if [ ! -f "$PROJECT_PATH/.claude/evolution-config.json" ]; then
    cp "$FRAMEWORK_DIR/.claude/evolution-config.json" "$PROJECT_PATH/.claude/"
    echo "✅ evolution-config.json 已创建"
else
    echo "⚠️  evolution-config.json 已存在，跳过"
fi

# 3. 复制 Skill 模板
echo "📝 复制 Skill 模板..."
cp -r "$FRAMEWORK_DIR/.claude/skills/"* "$PROJECT_PATH/.claude/skills/"
cp -r "$FRAMEWORK_DIR/.claude/templates/"* "$PROJECT_PATH/.claude/templates/"

# 4. 复制脚本
echo "🔧 复制脚本..."
cp "$FRAMEWORK_DIR/scripts/"* "$PROJECT_PATH/scripts/"
chmod +x "$PROJECT_PATH/scripts/"*.sh

# 5. 初始化配置
echo "🎛️  初始化配置..."
PROJECT_NAME=$(basename "$PROJECT_PATH")
AGENT_ID=$(echo "${PROJECT_NAME}-evolution-agent" | tr '[:upper:]' '[:lower:]')  # 转小写

# 更新 agent_id
if command -v jq &> /dev/null; then
    jq ".agent_id = \"$AGENT_ID\"" "$PROJECT_PATH/.claude/evolution-config.json" > /tmp/config.json
    mv /tmp/config.json "$PROJECT_PATH/.claude/evolution-config.json"
    echo "✅ Agent ID 设置为: $AGENT_ID"
else
    echo "⚠️  未安装 jq，请手动编辑 evolution-config.json"
fi

# 6. 创建初始化知识条目
echo "📚 创建初始化知识..."
cat > "$PROJECT_PATH/.claude/knowledge/lessons-learned/00-framework-initialized.md" <<EOF
# 进化框架初始化

## 日期
$(date +%Y-%m-%d)

## 项目
$PROJECT_NAME

## 初始化内容
- ✅ 目录结构创建完成
- ✅ 配置文件就绪
- ✅ Skills 模板已安装
- ✅ 脚本工具已配置

## 下一步
1. 编辑 .claude/evolution-config.json 设置目标
2. 运行 \`claude --skill meta-learning\` 开始学习
3. 定期执行 \`./scripts/evolution-engine.sh\` 检查进度

## 资源
- 文档: $FRAMEWORK_DIR/docs/
- GitHub: https://github.com/yourusername/claude-evolution-framework
EOF

# 7. 添加 .gitignore
echo "🔒 配置 .gitignore..."
if [ ! -f "$PROJECT_PATH/.gitignore" ]; then
    touch "$PROJECT_PATH/.gitignore"
fi

if ! grep -q ".claude/knowledge/evolution-log/" "$PROJECT_PATH/.gitignore"; then
    cat >> "$PROJECT_PATH/.gitignore" <<EOF

# Claude Evolution Framework
.claude/knowledge/evolution-log/*.md
.claude/tmp/
EOF
    echo "✅ .gitignore 已更新"
fi

# 8. 完成
echo ""
echo "🎉 安装完成！"
echo ""
echo "快速开始:"
echo "  cd $PROJECT_PATH"
echo "  claude --skill meta-learning --input '分析项目结构'"
echo "  ./scripts/evolution-engine.sh"
echo ""
echo "文档:"
echo "  $FRAMEWORK_DIR/docs/quickstart.md"
echo ""
echo "享受你的进化之旅！ 🚀"
