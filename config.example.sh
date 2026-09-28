#!/usr/bin/env bash
# 配置模板 —— 复制成 config.sh 后填入你自己的信息
#
#   cp config.example.sh config.sh
#
# config.sh 已被 .gitignore 忽略，不会被提交到 Git。

# 系统地址（末尾不要带 /）
export SITE_BASE="http://172.25.75.220"

# 你的账号与密码
# 注意：也可以用环境变量临时传入，例如
#   SITE_USER=2025280019 SITE_PASSWORD=xxx bash scripts/run_all.sh
export SITE_USER="你的学号"
export SITE_PASSWORD="你的密码"

# 要处理的预习任务编号（空格分隔）。系统里数字即任务 ID，
# 可在 /student/previews 页面按顺序对应。
export PREVIEW_IDS="1 2 3 4 5 6 7 8 9 10 11 12"

# 是否允许"未满分就重做"（每套最多 3 次作答机会，用尽后无法再提交）
# 1 = 自动重做未满分的套卷；0 = 只做未完成的，不重做
export RETRY_UNTIL_FULL="${RETRY_UNTIL_FULL:-1}"

# Node 可执行文件（一般不用改；Windows 上如 node 不在 PATH 请写绝对路径）
export NODE_BIN="${NODE_BIN:-node}"
