---
name: agent-fullstack
description: 创建和开发 Agent 全栈项目（Python 3.12 + AgentScope 2.x 后端，React + TypeScript + Vite 前端，OpenAI 兼容模型接入默认智谱 GLM，PC/Mobile 响应式聊天界面）。Use when 用户要新建/开发 AI Agent 应用、智能体 Web 项目、LLM 聊天应用、Agent 前后端项目，或提到给 Agent/大模型做 Web 界面、后端服务、脚手架。AgentScope 框架 API 细节优先查 agentscope-skill。
metadata:
  version: "0.1.0"
---

# Agent 全栈项目（agent-fullstack）

从零脚手架并持续开发一个全栈 Agent 应用：后端 Python 3.12 + AgentScope 2.x 提供
流式聊天与工具调用服务，前端 React + TypeScript 提供响应式聊天界面（PC 双栏、
Mobile 抽屉式侧栏），模型经 OpenAI 兼容协议接入，默认智谱 GLM。

## 与 agentscope-skill 的分工

- 本技能管**项目级**事务：目录结构、脚手架、前后端协作（SSE 流式）、模型接入
  约定、开发与部署流程。
- **AgentScope 框架 API 细节**（Agent/Toolkit/Msg/事件/中间件/多智能体/服务化部署）
  委托给 `agentscope-skill`：写或改 agent 相关代码前先查它，不要凭记忆猜 API。
- 本技能模板中的 AgentScope 用法已对 agentscope 2.0.10 验证过；升级 agentscope
  后若行为异常，先用 agentscope-skill 的 `view_module_signature.py` 复核签名。

## 技术栈

| 层 | 选型 |
| --- | --- |
| 后端运行时 | Python 3.12.x（`uv venv --python 3.12` 固定，pyproject 写 `requires-python >=3.12,<3.13`） |
| Agent 框架 | AgentScope ≥2.0.10（`Agent` + `reply_stream` + `Toolkit`/`FunctionTool`） |
| Web 服务 | FastAPI + Uvicorn（SSE 流式响应） |
| 配置 | pydantic-settings（`.env` 驱动，`Settings` + `lru_cache`） |
| HTTP 客户端 | httpx（异步，工具内调外部 API） |
| 数据库 | SQLAlchemy 2.x async（开发用 aiosqlite，可换 asyncpg/PostgreSQL） |
| 前端 | React 18 + TypeScript（严格模式）+ Vite |
| 前端状态 | Zustand（客户端状态：流式输出/当前会话）+ SWR（服务端数据：会话/消息列表） |
| UI | Ant Design 5（`ConfigProvider` 中文化）+ Tailwind CSS 4（仅 utilities，见下） |
| 工具 hooks | ahooks（`useThrottleFn` 节流滚动等） |
| 模型接入 | OpenAI 兼容统一（`OpenAIChatModel` + `OpenAICredential(base_url=…)`），默认 GLM |

关键约定（模板已内置，改动前先懂原因）：

- **Tailwind 只引 `theme` + `utilities`，跳过 preflight**——preflight 的元素重置会
  覆盖 antd 按钮等组件样式，两者混用是高频坑；antd 自带样式重置。
- **响应式**：`Grid.useBreakpoint()` 判定 `<768px` 为移动端——桌面双栏（侧栏会话
  列表 + 聊天区），移动端侧栏收进 Drawer；输入区吸附底部并留 `safe-area`。
- **SSE 事件协议**：`data: {"type": "delta"|"thinking"|"tool_start"|"tool_end"|"done"|"error", …}`，
  前后端共同遵守，详见 references/architecture.md。

## Quick Start

```bash
# 1. 环境自检（在项目 venv 激活后运行；也可直接全局跑，node/npm 检查与解释器无关）
python /path/to/agent-fullstack/scripts/check_env.py

# 2. 生成项目骨架（目标目录需为空或不存在）
python /path/to/agent-fullstack/scripts/scaffold.py ~/code/my-agent-app

# 3. 配置模型密钥（默认智谱 GLM；换 provider 只改这三个变量）
cd ~/code/my-agent-app && cp backend/.env.example .env   # .env 放项目根（后端从根目录启动）

# 4. 安装依赖并一键启动（后端 :8000，前端 :5173）
uv venv --python 3.12 && uv pip install -e backend
(cd frontend && npm install)
bash /path/to/agent-fullstack/scripts/run_dev.sh ~/code/my-agent-app
# 项目内也自带等价的 ./dev.sh
```

打开 http://localhost:5173 即为响应式聊天界面；示例工具（当前时间、天气查询）
已在 Toolkit 中，可直接问"现在几点""北京天气怎么样"验证工具调用。

## 标准项目结构

scaffold 生成的结构（后续开发保持同构，新项目不要另起布局）：

```text
my-agent-app/
├── backend/
│   ├── main.py           # FastAPI：/api/chat(SSE)、/api/conversations CRUD
│   ├── agent.py          # AgentScope Agent + OpenAI 兼容模型 + 示例工具
│   ├── config.py         # pydantic-settings（.env 驱动）
│   ├── database.py       # SQLAlchemy async engine/session
│   ├── models.py         # Conversation / Message 表
│   ├── pyproject.toml    # requires-python >=3.12,<3.13
│   ├── .env.example      # OPENAI_BASE_URL / OPENAI_API_KEY / OPENAI_MODEL …
│   └── tests/            # pytest（离线，不调真实模型）
├── frontend/
│   ├── src/
│   │   ├── App.tsx               # 响应式布局：桌面 Sider / 移动端 Drawer
│   │   ├── api.ts                # SSE 流式解析 + SWR fetcher
│   │   ├── store/chat.ts         # zustand：流式状态机
│   │   ├── components/           # ConversationList / ChatMessages
│   │   ├── hooks/useIsMobile.ts  # 封装 Grid.useBreakpoint
│   │   └── types.ts              # 前后端共享的领域类型
│   └── vite.config.ts    # tailwind 插件 + /api 代理到 :8000
├── dev.sh                # 项目内一键启动（等价于技能的 run_dev.sh）
└── README.md
```

## 开发循环

- 后端：`uvicorn main:app --app-dir backend --reload --port 8000`（在项目根执行，
  `.env` 与 sqlite 文件都落在根目录）。
- 前端：`(cd frontend && npm run dev)`；开发期 `/api` 由 Vite 代理转发，无需改
  CORS 之外的任何地址。
- 改模型/提示词：只动 `backend/.env`，重启后端即生效；不要把密钥写进代码。
- 加 Agent 工具：在 `backend/agent.py` 写函数 + `FunctionTool(...)` 注册；服务端
  场景记得带 `permission=PermissionDecision(behavior=PermissionBehavior.ALLOW, …)`
  免人工确认（写法抄模板）。
- 前后端联调 SSE：浏览器 DevTools → Network → 该请求为 `text/event-stream`，
  逐帧查看 `data:` 行；断流/只收到一帧多半是中间层缓冲，见
  references/dev-and-deploy.md。

## 模型接入约定

统一走 OpenAI 兼容协议，切换 provider 只改 `.env` 三个变量、零代码改动：

```bash
OPENAI_BASE_URL=https://open.bigmodel.cn/api/paas/v4   # 智谱 GLM（默认）
OPENAI_API_KEY=你的密钥
OPENAI_MODEL=glm-5.3-flash                              # 旗舰用 glm-5.3
# DeepSeek: base_url=https://api.deepseek.com/v1, model=deepseek-chat
# 通义:     base_url=https://dashscope.aliyuncs.com/compatible-mode/v1, model=qwen-plus
```

后端用 AgentScope 的 `OpenAIChatModel`（而非直接调 openai SDK），因此工具调用、
流式事件、重试都由框架统一处理。

## References（按需深读）

| 文件 | 何时读 |
| --- | --- |
| [references/architecture.md](references/architecture.md) | 改目录结构、加实体表、动 SSE 协议、纠结状态放 zustand 还是 SWR 时 |
| [references/backend.md](references/backend.md) | 写/改后端：agent 构建、工具、SQLAlchemy、SSE 端点、测试、uv 约定 |
| [references/frontend.md](references/frontend.md) | 写/改前端：TS 约定、状态、antd×tailwind、SSE 消费、响应式细节 |
| [references/dev-and-deploy.md](references/dev-and-deploy.md) | 联调排错、生产部署（uvicorn workers、前端构建产物、反向代理） |

## Scripts

| 脚本 | 用法 | 说明 |
| --- | --- | --- |
| `scripts/check_env.py` | `python check_env.py` | 自检 python 3.12/node/npm/uv 与关键包，缺失项给安装命令；有失败退出码 1 |
| `scripts/scaffold.py` | `python scaffold.py <目标路径>` | 生成标准骨架并替换 `{{PROJECT_NAME}}`；目标目录须为空 |
| `scripts/run_dev.sh` | `bash run_dev.sh <项目目录>` | 同时拉起前后端，Ctrl-C 一并退出，日志带 `[api]`/`[web]` 前缀 |
