#!/usr/bin/env bash
# scripts/run_all.sh —— 一键完成全部预习任务
#
#   bash scripts/run_all.sh
#
# 行为：
#   1. 登录 / 续期
#   2. 打印任务清单与当前得分
#   3. 逐套处理：已满分跳过、次数用尽跳过、其余自动作答并提交
#   4. 再打印一次任务清单，核对结果
set -uo pipefail
. "$(dirname "$0")/lib.sh"

echo "==================== 一键预习 ===================="
echo "系统地址: $SITE_BASE"
echo "任务编号: $PREVIEW_IDS"
echo "未满分重做: $([ "$RETRY_UNTIL_FULL" = "1" ] && echo 开启 || echo 关闭)"
echo

api_login || exit 1
echo

echo "---- 处理前的任务状态 ----"
api_previews
echo

for ID in $PREVIEW_IDS; do
  SCORE="$(api_score "$ID")"
  TRIED="$(api_attempt_count "$ID")"

  if [ "$SCORE" = "100" ]; then
    echo ">> 第 $ID 套 已满分，跳过"
    continue
  fi
  if [ "$TRIED" -ge 3 ]; then
    echo ">> 第 $ID 套 作答次数已用尽（3/3），跳过（当前 $SCORE 分）"
    continue
  fi
  if [ "$SCORE" != "none" ] && [ "$RETRY_UNTIL_FULL" != "1" ]; then
    echo ">> 第 $ID 套 已作答（$SCORE 分），未开启重做，跳过"
    continue
  fi

  echo ">> 第 $ID 套 当前 $SCORE 分，已用 $TRIED/3 次 —— 开始作答"
  bash "$ROOT/scripts/run_quiz.sh" "$ID"
done

echo
echo "---- 处理后的任务状态 ----"
api_previews
echo "==================== 全部处理完毕 ===================="
