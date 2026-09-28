#!/usr/bin/env bash
# scripts/status.sh —— 只看状态，不做任何提交（安全，可随时运行）
#
#   bash scripts/status.sh
. "$(dirname "$0")/lib.sh"

echo "系统地址: $SITE_BASE"
echo "任务编号: $PREVIEW_IDS"
echo
api_previews
echo
echo "（以上仅为读取结果，本次没有提交任何答卷）"
