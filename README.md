# 物理实验预习答题 · 自动化脚本

把「物理实验预习答题系统」里逐套答题的重复操作脚本化：**一次配置，之后一条命令跑完全部未完成的预习任务**。

本文档即中文使用指导，从零开始照着做即可跑通。

---

## 目录

- [一、这是什么](#一这是什么)
- [二、使用前必读](#二使用前必读)
- [三、环境要求](#三环境要求)
- [四、快速开始（5 步）](#四快速开始5-步)
- [五、常用命令速查](#五常用命令速查)
- [六、配置文件说明](#六配置文件说明)
- [七、答案库格式](#七答案库格式)
- [八、工作原理](#八工作原理)
- [九、常见问题 FAQ](#九常见问题-faq)
- [十、目录结构](#十目录结构)
- [十一、技术说明](#十一技术说明)
- [十二、免责声明](#十二免责声明)

---

## 一、这是什么

系统里的「预习」任务，本质是**一份在线答题卷**（单选 + 多选 + 判断，满分 100，每套限 3 次作答机会）。
没有独立的"阅读材料/观看课程"页面 —— 题面本身就是课程知识点。

这个仓库做三件事：

| 能力 | 说明 |
|---|---|
| **一键完成** | `bash scripts/run_all.sh` —— 登录 → 遍历全部任务 → 自动作答 → 提交 → 读分 → 打印结果表 |
| **防重复提交** | 提交前先查 `GET /api/attempts/`：已满分的跳过，次数用尽的跳过，只处理真正需要做的 |
| **可增量修正** | 答案库是纯 JSON，改完立刻生效，重跑只补未满分的，不会浪费作答次数 |

---

## 二、使用前必读

1. **这是你自己的账号，请只用于你自己的任务。** 不要拿别人的账号跑。
2. **答案库是该课程的题解，是否公开由你决定。** 建议仓库设为 **Private**。若改为公开，等于把答案公开发布，请自行判断是否合适。
3. **每套只有 3 次作答机会。** 脚本已经内置"次数用尽即跳过"的保护，但请勿手工把 3 次刷完再指望脚本救援。
4. **不要提交 `config.sh`。** 里面是你的账号密码，`.gitignore` 已默认忽略它。
5. 本项目通过系统**本身的公开接口**完成操作（登录 → 取题 → 提交），不篡改数据、不绕过权限。

---

## 三、环境要求

| 依赖 | 说明 |
|---|---|
| **Node.js ≥ 18** | 需要内置 `fetch`。Windows / macOS / Linux 均可 |
| **Bash** | Windows 用 **Git Bash**（不是 cmd / PowerShell） |
| **agent-browser** | 用于真实浏览器中勾选选项 |
| **网络** | 能访问系统地址（默认 `http://172.25.75.220`，通常需在校园网/内网） |

### 安装 agent-browser

```bash
npm install -g agent-browser --registry=https://registry.npmmirror.com
agent-browser --version    # 能打印版本号即可
```

> Windows 若提示找不到命令，请确认 npm 全局 bin 目录在 PATH 中：
> `C:\Users\<你的用户名>\AppData\Roaming\npm`

---

## 四、快速开始（5 步）

### 第 1 步 · 获取代码

```bash
git clone <本仓库地址>
cd physics-lab-preview-automation
```

### 第 2 步 · 创建配置文件

```bash
cp config.example.sh config.sh
```

### 第 3 步 · 填写账号

用任意编辑器打开 `config.sh`，填入你的学号与密码：

```bash
export SITE_BASE="http://172.25.75.220"
export SITE_USER="你的学号"
export SITE_PASSWORD="你的密码"
export PREVIEW_IDS="1 2 3 4 5 6 7 8 9 10 11 12"
export RETRY_UNTIL_FULL="1"
```

### 第 4 步 · 看看现在有哪些任务

```bash
bash scripts/run_all.sh
```

> 这一步会打印任务清单；如果只想先看状态、不想动手，用：
> ```bash
> node scripts/api.js previews
> ```

### 第 5 步 · 一条命令跑完

```bash
bash scripts/run_all.sh
```

输出形如：

```
==================== 一键预习 ====================
系统地址: http://172.25.75.220
任务编号: 1 2 3 4 5 6 7 8 9 10 11 12
未满分重做: 开启

[√] 登录成功，令牌已缓存到 .cache/

---- 处理前的任务状态 ----
编号 | 实验名称 | 状态 | 最新得分 | 已用次数
-----|----------|------|----------|---------
   1 | 弗兰克-赫兹实验 | 已完成 | 100/100 | 2
   3 | 密立根油滴实验 | 已完成 | 76/100 | 1
...

>> 第 1 套 已满分，跳过
>> 第 3 套 当前 76 分，已用 1/3 次 —— 开始作答
--- 第 3 套 ---
  打开后计数: 已作答 0 / 20
  勾选后计数: 已作答 20 / 20
  仍空着的题: 全部已作答
  提交结果:   本次得分 100 分
...
```

---

## 五、常用命令速查

| 目的 | 命令 |
|---|---|
| **一键完成全部** | `bash scripts/run_all.sh` |
| 只做某一套 | `bash scripts/run_quiz.sh 3` |
| 看任务清单和得分 | `node scripts/api.js previews` |
| 看某套得分 | `node scripts/api.js score 3` |
| 看某套作答记录 | `node scripts/api.js attempts 3` |
| 看某套题目原文 | `node scripts/api.js questions 3` |
| 手动登录 / 续期 | `node scripts/api.js login` / `node scripts/api.js refresh` |
| 临时用别的账号跑一次 | `SITE_USER=xxx SITE_PASSWORD=yyy bash scripts/run_all.sh` |

---

## 六、配置文件说明

| 变量 | 默认值 | 说明 |
|---|---|---|
| `SITE_BASE` | `http://172.25.75.220` | 系统地址，**末尾不要带 `/`** |
| `SITE_USER` | — | 学号 |
| `SITE_PASSWORD` | — | 密码 |
| `PREVIEW_IDS` | `1 2 3 4 5 6 7 8 9 10 11 12` | 要处理的任务编号，空格分隔 |
| `RETRY_UNTIL_FULL` | `1` | `1`=未满分就重做；`0`=只做未完成的，不碰已作答的 |
| `NODE_BIN` | `node` | Node 路径，找不到 node 时写绝对路径 |

---

## 七、答案库格式

答案库是根目录的 `answers.json`，按任务编号组织：

```jsonc
{
  "1": {
    // 单选题：写正确选项的文本（不用写 A/B/C 前缀）
    "singles": ["X输入和Y输入", "氩原子的第一激发电位"],

    // 多选题：一个数组是一道题，里面是该题所有正确选项的文本
    "multiples": [
      ["处于定态的原子是稳定的", "能量最低的定态叫基态"],
      ["加热", "光照", "碰撞"]
    ],

    // 判断题：题干关键字 -> "正确" 或 "错误"
    "judges": { "升力和曳力系数是无量纲量": "正确" },

    // 【可选】当不同题目的选项文本完全相同时用。题干关键字 -> 该题正确选项
    "multiQ": { "根据衍射光的方向": ["反射光栅", "透射光栅"] }
  }
}
```

**三条规则：**

1. **写选项文本，不写序号。** 系统每次刷新都会随机打乱选项顺序，按序号作答必然错。
2. **必须和页面文字一致。** 公式题不用手写 Unicode，脚本内置归一化会自动处理（见下）。
3. **文本撞车时用 `multiQ`。** 例如某套有两道题选项都是「反射光栅 / 透射光栅」，全局匹配会串题，这时按题干关键字限定范围。

改完 `answers.json` 直接重跑 `run_all.sh` 即可，不需要其它操作。

---

## 八、工作原理

```
① 登录         POST /api/auth/login/         → access + refresh 令牌，缓存到 .cache/
② 取当前状态    GET  /api/attempts/          → 每套的得分与已用次数（决定跳过谁）
③ 取题         GET  /api/previews/{id}/questions/
④ 打开答题页    浏览器注入令牌 → sessionStorage → 跳转 /student/answer/{id}
⑤ 按文本勾选    answers.json 与页面选项文本做「归一化后」比对，命中即点击
⑥ 提交         POST（页面"提交答卷"按钮）
⑦ 读分         页面"本次得分" + GET /api/attempts/ 二次确认
```

**防重复提交的三道闸：**

```
已满分(100)        → 跳过
已用次数 ≥ 3       → 跳过（没有机会了）
RETRY_UNTIL_FULL=0 → 已作答的一律跳过
```

---

## 九、常见问题 FAQ

**Q1. 提示找不到 `node` / `agent-browser`？**
Windows 用 **Git Bash** 运行，不要用 cmd。仍找不到就在 `config.sh` 里写绝对路径：
```bash
export NODE_BIN="C:/Program Files/nodejs/node.exe"
```

**Q2. 提示 `未找到 config.sh`？**
你还没做第 2 步。执行 `cp config.example.sh config.sh` 并填写账号。

**Q3. 登录失败 / 401？**
- 先确认账号密码正确、且能访问系统地址（`curl -I http://172.25.75.220` 看通不通）。
- 令牌过期不用管，脚本会自动续期；续期失败会自动重新登录。
- 删掉 `.cache/` 可强制重新登录。

**Q4. 某套一直不满分怎么办？**
1. 打开该套页面看哪些题没选上：`bash scripts/run_quiz.sh 3`，看输出的「仍空着的题」；
2. 对照 `node scripts/api.js questions 3` 的标准题面，修正 `answers.json` 里对应的文本；
3. 重跑。**注意别把 3 次机会刷完。**

**Q5. 分数有了但系统里显示"未完成"？**
刷新任务列表即可。`node scripts/api.js previews` 里的"已完成"以 `done` 字段为准。

**Q6. 为什么不能直接按 A/B/C/D 作答？**
因为系统每次返回的选项顺序都是随机的（`option_orders` 每次请求都不同）。按文本匹配是唯一稳定的做法。

**Q7. 公式题为什么匹配不上？**
页面上的公式经过 MathJax 渲染，字符是 Unicode 数学字母（如 `𝑉`、`𝑑`、`Δ`、`φ`），而答案里通常写 ASCII。
`scripts/clickgen.js` 内置了 `norm()` 归一化函数，把 Unicode 数学字母、希腊字母（含斜体变体）统一映射成 ASCII 名称，并去掉 `·`、`×` 等排版符号和所有空白，再做比较。
新增公式题时**无需手动转换**，按正常写法写即可。

**Q8. 多选题选不上 / 只记录到最后一个？**
Element Plus 的 checkbox 直接批量 `click()` 会被状态覆盖。脚本已改为**逐个点击并间隔 150ms**，不要改成一次性批量点击。

**Q9. 能跑在自己电脑以外的机器上吗？**
可以，只要那台机器能访问系统地址、装了 Node 和 agent-browser。

---

## 十、目录结构

```
.
├── README.md                  # 本文件（中文使用指导）
├── config.example.sh          # 配置模板 → 复制成 config.sh
├── answers.json               # 答案库（按任务编号）
├── LICENSE
├── scripts/
│   ├── lib.sh                 # 公共函数：配置 / 登录 / 令牌 / 页面操作
│   ├── api.js                 # 接口工具：login / previews / questions / score / attempts
│   ├── run_all.sh             # ★ 一键完成全部任务
│   ├── run_quiz.sh            # 完成单套
│   └── clickgen.js            # 按答案库生成"浏览器勾选"脚本（含归一化）
├── docs/
│   ├── 系统分析.md            # 接口、数据结构的逆向整理
│   └── 预习任务完成报告.md     # 一次实际完成的记录（示例）
└── .cache/                    # 令牌缓存（已 gitignore）
```

---

## 十一、技术说明

| 项目 | 内容 |
|---|---|
| 目标系统 | Django REST Framework + Vue 3 + Element Plus + MathJax（SPA） |
| 认证方式 | JWT（access 30 分钟 / refresh 7 天），前端存 **sessionStorage** |
| 关键接口 | `/api/auth/login/`、`/api/auth/refresh/`、`/api/previews/`、`/api/previews/{id}/questions/`、`/api/attempts/` |
| 浏览器自动化 | `agent-browser`（注入令牌免表单登录 → 页面内点击 → 读页面文本） |
| 难点 | 选项随机排序、MathJax 公式的 Unicode 字符、跨题重复选项、Element Plus 多选状态合并 |

更详细的接口与数据结构见 [`docs/系统分析.md`](docs/系统分析.md)。

---

## 十二、免责声明

本项目用于减少**重复的机械操作**，脚本按你自己维护的答案库作答。
使用者需自行确保：账号为本人所有、使用方式符合课程与学校的规定。
作者不对因使用本项目产生的任何后果（包括但不限于答题次数用尽、成绩争议、账号异常）负责。

---

## License

MIT
