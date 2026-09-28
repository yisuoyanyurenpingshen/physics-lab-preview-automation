#!/usr/bin/env bash
# scripts/lib.sh —— 公共函数库（配置加载 / 登录 / 令牌 / 页面跳转）
#
# 在其它脚本里这样引用：
#   . "$(dirname "$0")/lib.sh"

_LIB_SRC="${BASH_SOURCE[0]:-$0}"
_ROOT_POSIX="$(cd "$(dirname "$_LIB_SRC")/.." && pwd)"
# Windows(Git Bash) 下 pwd 返回 /c/... ，直接传给 node 会被解析成 C:\c\...
# 用 cygpath -m 转成 C:/... 形式，bash 与 node 都能正确识别。
if command -v cygpath >/dev/null 2>&1; then
  export ROOT="$(cygpath -m "$_ROOT_POSIX")"
else
  export ROOT="$_ROOT_POSIX"
fi

# ---------- 1. 读取配置 ----------
if [ -f "$ROOT/config.sh" ]; then
  # shellcheck disable=SC1090,SC1091
  . "$ROOT/config.sh"
else
  echo "[!] 未找到 config.sh，暂用 config.example.sh 的占位值" >&2
  echo "    请先执行：cp config.example.sh config.sh  并填入账号密码" >&2
  # shellcheck disable=SC1090,SC1091
  . "$ROOT/config.example.sh"
fi

export SITE_BASE="${SITE_BASE:-http://172.25.75.220}"
export PREVIEW_IDS="${PREVIEW_IDS:-1 2 3 4 5 6 7 8 9 10 11 12}"
export RETRY_UNTIL_FULL="${RETRY_UNTIL_FULL:-1}"
NODE_BIN="${NODE_BIN:-node}"

export CACHE_DIR="$ROOT/.cache"
mkdir -p "$CACHE_DIR"
export TOKEN_FILE="$CACHE_DIR/access_token"

API="$ROOT/scripts/api.js"

# ---------- 2. 接口封装 ----------
api_login()    { "$NODE_BIN" "$API" login; }
api_refresh()  { "$NODE_BIN" "$API" refresh; }
api_get()      { "$NODE_BIN" "$API" get "$1"; }
api_score()    { "$NODE_BIN" "$API" score "$1"; }
api_questions(){ "$NODE_BIN" "$API" questions "$1"; }
api_previews() { "$NODE_BIN" "$API" previews; }
# 该套已用掉的作答次数（每套上限 3 次）
api_attempt_count() { "$NODE_BIN" "$API" attempts "$1" | grep -c . ; }

# ---------- 3. 浏览器：注入令牌并跳转到指定路径 ----------
# 依赖 agent-browser（见 README「环境要求」）
nav() {
  local target="$1"
  local access refresh
  access="$(cat "$TOKEN_FILE" 2>/dev/null)"
  refresh="$(cat "$CACHE_DIR/refresh_token" 2>/dev/null)"
  if [ -z "$access" ]; then
    api_login >/dev/null
    access="$(cat "$TOKEN_FILE")"
    refresh="$(cat "$CACHE_DIR/refresh_token" 2>/dev/null)"
  fi
  agent-browser open "$SITE_BASE/login" >/dev/null 2>&1
  agent-browser wait 800 >/dev/null 2>&1
  # 该站把 JWT 存在 sessionStorage，页面内注入后再跳转即可免表单登录
  agent-browser eval "sessionStorage.setItem('access_token','$access'); sessionStorage.setItem('refresh_token','$refresh'); location.href='$target'" >/dev/null 2>&1
  agent-browser wait 2000 >/dev/null 2>&1
}

# ---------- 4. 小工具 ----------
# 读取页面上"已作答 N / M"的计数
page_counter() {
  agent-browser eval "document.body.innerText.match(/已作答\s*\d+\s*\/\s*\d+/)?.[0] || '未找到'" 2>/dev/null
}

# 点击"提交答卷"按钮
page_submit() {
  agent-browser eval "[...document.querySelectorAll('button')].filter(x=>x.innerText.includes('提交答卷'))[0].click(); 'ok'" >/dev/null 2>&1
}

# 读取提交后的"本次得分"
page_score() {
  agent-browser eval "(document.body.innerText.match(/本次得分[^\n]*/)||['未找到'])[0]" 2>/dev/null
}

# 列出当前页面尚未作答的题干（用于排错）
page_unanswered() {
  agent-browser eval "(function(){var o=[];document.querySelectorAll('.question-card').forEach(function(c){var t=(c.querySelector('.q-title')||{}).innerText||'';if(!c.querySelector('.el-radio.is-checked,.el-checkbox.is-checked'))o.push(t.replace(/\n+/g,' ').slice(0,60));});return o.length?o.join(' ||| '):'全部已作答';})()" 2>/dev/null
}
