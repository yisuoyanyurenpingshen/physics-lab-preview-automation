#!/usr/bin/env node
/**
 * scripts/api.js —— 预习系统 HTTP 接口小工具
 *
 * 所有子命令都优先读取环境变量：
 *   SITE_BASE      系统地址，默认 http://172.25.75.220
 *   SITE_USER      账号
 *   SITE_PASSWORD  密码
 *
 * 用法：
 *   node scripts/api.js login            # 登录并缓存令牌
 *   node scripts/api.js refresh          # 用 refresh token 换新的 access token
 *   node scripts/api.js get <path>       # 带令牌 GET，例如 get /api/previews/
 *   node scripts/api.js previews         # 打印任务列表（编号/名称/状态/得分）
 *   node scripts/api.js questions <id>   # 打印某套的题目 JSON
 *   node scripts/api.js score <id>       # 打印某套最新得分（none=未作答）
 *   node scripts/api.js attempts <id>    # 打印某套的全部作答记录
 */
const fs = require("fs");
const path = require("path");

const ROOT = path.resolve(__dirname, "..");
const BASE = (process.env.SITE_BASE || "http://172.25.75.220").replace(/\/+$/, "");
const CACHE_DIR = process.env.CACHE_DIR || path.join(ROOT, ".cache");
const TOKEN_FILE = path.join(CACHE_DIR, "access_token");
const REFRESH_FILE = path.join(CACHE_DIR, "refresh_token");

const read = (f) => { try { return fs.readFileSync(f, "utf8").trim(); } catch { return ""; } };
const write = (f, v) => { fs.mkdirSync(CACHE_DIR, { recursive: true }); fs.writeFileSync(f, v); };

function saveSession(j) {
  if (j.access) write(TOKEN_FILE, j.access);
  if (j.refresh) write(REFRESH_FILE, j.refresh);
}

async function login() {
  const username = process.env.SITE_USER;
  const password = process.env.SITE_PASSWORD;
  if (!username || !password) {
    console.error("[x] 缺少 SITE_USER / SITE_PASSWORD。请先填写 config.sh，或用环境变量传入。");
    process.exit(2);
  }
  const r = await fetch(BASE + "/api/auth/login/", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ username, password }),
  });
  const j = await r.json().catch(() => ({}));
  if (!j.access) {
    console.error("[x] 登录失败 (" + r.status + ")：" + JSON.stringify(j));
    process.exit(1);
  }
  saveSession(j);
  console.log("[√] 登录成功，令牌已缓存到 .cache/");
}

async function refresh() {
  const rt = read(REFRESH_FILE);
  if (!rt) return false;
  const r = await fetch(BASE + "/api/auth/refresh/", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ refresh: rt }),
  });
  const j = await r.json().catch(() => ({}));
  if (!j.access) return false;
  write(TOKEN_FILE, j.access);
  return true;
}

/** 带自动续期的请求：401 时用 refresh token 换新 access 再重试一次 */
async function request(pathname, init = {}) {
  let token = read(TOKEN_FILE);
  if (!token) { await login(); token = read(TOKEN_FILE); }
  const send = (t) => fetch(BASE + pathname, {
    ...init,
    headers: { ...(init.headers || {}), Authorization: "Bearer " + t },
  });
  let r = await send(token);
  if (r.status === 401) {
    const ok = await refresh();
    if (!ok) { await login(); }
    r = await send(read(TOKEN_FILE));
  }
  return r;
}

async function getJson(pathname) {
  const r = await request(pathname);
  if (!r.ok) { console.error("[x] " + pathname + " -> HTTP " + r.status); process.exit(1); }
  return r.json();
}

const NEED_FULL = () => String(process.env.RETRY_UNTIL_FULL ?? "1") === "1";

async function cmdPreviews() {
  const j = await getJson("/api/previews/");
  const atts = await getJson("/api/attempts/?page_size=200");
  const latest = {};
  const used = {};
  for (const a of atts.results || []) {
    used[a.preview] = (used[a.preview] || 0) + 1;
    if (!latest[a.preview] || a.id > latest[a.preview].id) latest[a.preview] = a;
  }
  console.log("编号 | 实验名称 | 状态 | 最新得分 | 已用次数");
  console.log("-----|----------|------|----------|---------");
  for (const p of j.results) {
    const l = latest[p.id];
    console.log(
      String(p.id).padStart(4) + " | " + p.experiment_name + " | " +
      (p.done ? "已完成" : "未完成") + " | " +
      (l ? l.score + "/" + l.total_score : "-") + " | " +
      (used[p.id] || 0)
    );
  }
}

async function cmdScore(id) {
  const j = await getJson("/api/attempts/?page_size=200");
  const atts = (j.results || []).filter((x) => String(x.preview) === String(id));
  const l = atts.sort((a, b) => a.id - b.id).slice(-1)[0];
  console.log(l ? l.score : "none");
}

async function cmdAttempts(id) {
  const j = await getJson("/api/attempts/?page_size=200");
  const atts = (j.results || []).filter((x) => String(x.preview) === String(id));
  atts.forEach((a) => console.log(
    "attempt " + a.attempt_no + " | id=" + a.id + " | " + a.score + "/" + a.total_score +
    " | " + a.submitted_at + " | " + (a.pdf_path || "-")
  ));
}

async function main() {
  const [cmd, arg] = process.argv.slice(2);
  switch (cmd) {
    case "login": await login(); break;
    case "refresh": console.log(await refresh() ? "[√] 已续期" : "[x] 续期失败"); break;
    case "get": {
      const r = await request(arg);
      console.log(await r.text());
      if (!r.ok) process.exit(1);
      break;
    }
    case "previews": await cmdPreviews(); break;
    case "questions": console.log(JSON.stringify(await getJson(`/api/previews/${arg}/questions/`), null, 2)); break;
    case "score": await cmdScore(arg); break;
    case "attempts": await cmdAttempts(arg); break;
    default:
      console.log("用法: node scripts/api.js <login|refresh|previews|questions <id>|score <id>|attempts <id>|get <path>>");
      process.exit(2);
  }
}

main().catch((e) => { console.error("[x] " + e.message); process.exit(1); });
