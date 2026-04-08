#!/bin/bash

# Claude Evolution Engine - 持续进化引擎
# 自动追踪学习进度、更新经验值、触发反思

set -e

CLAUDE_DIR="${CLAUDE_DIR:-.claude}"
CONFIG_FILE="$CLAUDE_DIR/evolution-config.json"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🧬 Claude Evolution Engine${NC}"
echo "=============================="
echo ""

# 检查依赖
if ! command -v jq &> /dev/null; then
    echo -e "${RED}❌ 错误: 需要安装 jq${NC}"
    echo "安装: brew install jq"
    exit 1
fi

if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${RED}❌ 错误: 未找到 $CONFIG_FILE${NC}"
    echo "请先运行 setup.sh 初始化框架"
    exit 1
fi

# 读取当前状态
CURRENT_LEVEL=$(jq -r '.evolution.current_level' "$CONFIG_FILE")
CURRENT_XP=$(jq -r '.evolution.experience_points' "$CONFIG_FILE")
THRESHOLD=$(jq -r '.evolution.next_level_threshold' "$CONFIG_FILE")
AGENT_ID=$(jq -r '.agent_id' "$CONFIG_FILE")

echo -e "${GREEN}Agent ID:${NC} $AGENT_ID"
echo -e "${GREEN}当前等级:${NC} Level $CURRENT_LEVEL"
echo -e "${GREEN}经验值:${NC} $CURRENT_XP / $THRESHOLD"
echo ""

# 1. 扫描新知识
echo -e "${YELLOW}📚 扫描新知识...${NC}"
NEW_PATTERNS=$(find "$CLAUDE_DIR/knowledge/patterns" -type f -mtime -1 2>/dev/null | wc -l | tr -d ' ')
NEW_LESSONS=$(find "$CLAUDE_DIR/knowledge/lessons-learned" -type f -mtime -1 2>/dev/null | wc -l | tr -d ' ')
NEW_SNIPPETS=$(find "$CLAUDE_DIR/knowledge/code-snippets" -type f -mtime -1 2>/dev/null | wc -l | tr -d ' ')

TOTAL_NEW=$((NEW_PATTERNS + NEW_LESSONS + NEW_SNIPPETS))

if [ $TOTAL_NEW -gt 0 ]; then
    echo -e "  ${GREEN}✓${NC} 发现 $TOTAL_NEW 个新知识条目"
    echo -e "    - 设计模式: $NEW_PATTERNS"
    echo -e "    - 经验教训: $NEW_LESSONS"
    echo -e "    - 代码片段: $NEW_SNIPPETS"
else
    echo -e "  ${YELLOW}⚠${NC}  未发现新知识（过去24小时）"
fi

# 2. 更新知识库统计
TOTAL_ENTRIES=$(find "$CLAUDE_DIR/knowledge" -type f -name "*.md" | wc -l | tr -d ' ')
jq ".knowledge_base.total_entries = $TOTAL_ENTRIES" "$CONFIG_FILE" > /tmp/config.json
mv /tmp/config.json "$CONFIG_FILE"

# 3. 计算新增经验值
XP_GAIN=0

# 新知识奖励
XP_GAIN=$((XP_GAIN + TOTAL_NEW * 10))

# 每日登录奖励
LAST_RUN=$(jq -r '.evolution.last_run // "1970-01-01"' "$CONFIG_FILE")
TODAY=$(date +%Y-%m-%d)
if [ "$LAST_RUN" != "$TODAY" ]; then
    XP_GAIN=$((XP_GAIN + 5))
    echo -e "  ${GREEN}✓${NC} 每日登录 +5 XP"
fi

# 更新经验值
NEW_XP=$((CURRENT_XP + XP_GAIN))
jq ".evolution.experience_points = $NEW_XP | .evolution.last_run = \"$TODAY\"" "$CONFIG_FILE" > /tmp/config.json
mv /tmp/config.json "$CONFIG_FILE"

if [ $XP_GAIN -gt 0 ]; then
    echo -e "${GREEN}📈 获得 $XP_GAIN XP!${NC} (总计: $NEW_XP)"
else
    echo -e "${YELLOW}暂无经验值增长${NC}"
fi
echo ""

# 4. 检查升级
if [ $NEW_XP -ge $THRESHOLD ]; then
    NEW_LEVEL=$((CURRENT_LEVEL + 1))
    NEW_THRESHOLD=$((THRESHOLD * 2))

    echo -e "${GREEN}🎉 恭喜升级！${NC}"
    echo -e "   Level $CURRENT_LEVEL → Level $NEW_LEVEL"
    echo ""

    jq ".evolution.current_level = $NEW_LEVEL | .evolution.next_level_threshold = $NEW_THRESHOLD" "$CONFIG_FILE" > /tmp/config.json
    mv /tmp/config.json "$CONFIG_FILE"

    # 记录里程碑
    MILESTONE=$(jq -r ".evolution_milestones | length" "$CONFIG_FILE")
    MILESTONE_DATA=$(cat <<EOF
{
  "level": $NEW_LEVEL,
  "name": "Level $NEW_LEVEL",
  "achieved_at": "$TODAY",
  "key_achievements": ["升级到 Level $NEW_LEVEL"]
}
EOF
)
    jq ".evolution_milestones[$MILESTONE] = $MILESTONE_DATA" "$CONFIG_FILE" > /tmp/config.json
    mv /tmp/config.json "$CONFIG_FILE"
fi

# 5. 触发定期反思
DAY_OF_WEEK=$(date +%u)  # 1-7, 7是周日
if [ "$DAY_OF_WEEK" -eq 7 ] && [ "$LAST_RUN" != "$TODAY" ]; then
    echo -e "${BLUE}🤔 触发每周反思...${NC}"
    echo ""

    REFLECTION_FILE="$CLAUDE_DIR/knowledge/evolution-log/$TODAY-weekly-reflection.md"
    cat > "$REFLECTION_FILE" <<EOF
# 每周反思 $(date +%Y-%m-%d)

## 本周统计
- 新增知识: $TOTAL_NEW 条
- 当前等级: Level $CURRENT_LEVEL
- 经验值: $NEW_XP / $THRESHOLD

## 本周成就
- [ ] 待填写

## 遇到的挑战
- [ ] 待填写

## 学到的经验
- [ ] 待填写

## 下周计划
- [ ] 待填写

---
*使用 \`claude --skill self-reflection\` 完成详细反思*
EOF

    echo -e "${GREEN}✓${NC} 已创建反思模板: $REFLECTION_FILE"
    echo -e "  运行: ${BLUE}claude --skill self-reflection${NC}"
    echo ""
fi

# 6. 生成进化报告
echo -e "${YELLOW}📊 生成进化报告...${NC}"
REPORT_FILE="$CLAUDE_DIR/knowledge/evolution-log/$TODAY-evolution-report.md"
cat > "$REPORT_FILE" <<EOF
# 进化报告 $TODAY

## 当前状态
- **Agent ID**: $AGENT_ID
- **等级**: Level $CURRENT_LEVEL
- **经验值**: $NEW_XP / $THRESHOLD (进度: $((NEW_XP * 100 / THRESHOLD))%)
- **知识库**: $TOTAL_ENTRIES 条

## 今日成长
- 新增知识: $TOTAL_NEW 条
- 获得经验: +$XP_GAIN XP

## 知识分布
EOF

# 统计各类知识数量
for category in architecture patterns code-snippets lessons-learned; do
    count=$(find "$CLAUDE_DIR/knowledge/$category" -type f -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
    echo "- ${category}: $count 条" >> "$REPORT_FILE"
done

cat >> "$REPORT_FILE" <<EOF

## 短期目标
EOF

jq -r '.goals.short_term[]' "$CONFIG_FILE" | sed 's/^/- [ ] /' >> "$REPORT_FILE"

echo -e "${GREEN}✓${NC} 报告已生成: $REPORT_FILE"
echo ""

# 7. 显示下一步建议
echo -e "${BLUE}💡 建议行动:${NC}"

if [ $TOTAL_NEW -eq 0 ]; then
    echo -e "  1. 运行 ${GREEN}claude --skill meta-learning${NC} 学习新知识"
fi

if [ "$DAY_OF_WEEK" -eq 7 ]; then
    echo -e "  2. 完成每周反思: ${GREEN}claude --skill self-reflection${NC}"
fi

PROGRESS=$((NEW_XP * 100 / THRESHOLD))
if [ $PROGRESS -ge 80 ]; then
    echo -e "  3. 即将升级！继续加油 🔥"
fi

echo ""
echo -e "${GREEN}✅ 进化引擎执行完成${NC}"
