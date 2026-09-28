#!/usr/bin/env bash
# scripts/run_quiz.sh <套号> —— 完成单套预习：打开答题页 → 按答案库勾选 → 提交 → 读取得分
#
# 单独用：
#   bash scripts/run_quiz.sh 3
. "$(dirname "$0")/lib.sh"

ID="$1"
if [ -z "$ID" ]; then echo "用法: bash scripts/run_quiz.sh <套号>"; exit 2; fi

echo "--- 第 $ID 套 ---"

# 1) 生成勾选脚本（含归一化函数，处理打乱顺序与公式题）
CLICK="$("$NODE_BIN" "$ROOT/scripts/clickgen.js" "$ID")" || exit 1

# 2) 打开答题页（注入令牌，免表单登录）
nav "/student/answer/$ID"
echo "  打开后计数: $(page_counter)"

# 3) 执行勾选
agent-browser eval "$CLICK" >/dev/null 2>&1
agent-browser wait 900 >/dev/null 2>&1
echo "  勾选后计数: $(page_counter)"
echo "  仍空着的题: $(page_unanswered)"

# 4) 提交
page_submit
agent-browser wait 1800 >/dev/null 2>&1
echo "  提交结果:   $(page_score)"
