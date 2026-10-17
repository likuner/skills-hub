# 开发调试与部署

## 日常循环

```bash
# 项目根
bash dev.sh                        # 或技能的 run_dev.sh <项目目录>
# 等价于手动：
uvicorn main:app --app-dir backend --reload --port 8000 &
(cd frontend && npm run dev)
```

- 后端改代码 uvicorn 自动重载；改 `.env` 需手动重启（pydantic-settings 只在
  进程启动时读一次）。
- 前端热更新即所见即所得；改 vite.config.ts 需重启 dev server。

## 常见问题

| 症状 | 原因与处理 |
| --- | --- |
| 前端 404 /api/… | Vite 代理没生效：确认 vite.config.ts 的 `server.proxy` 且 dev server 已重启 |
| 浏览器收到 CORS 错 | 直连了 8000 端口而非 5173；或自定端口没加进 `.env` 的 `CORS_ORIGINS` |
| SSE 一次性全到 / 卡住不流 | 中间层缓冲：响应头确认 `X-Accel-Buffering: no`（nginx）；uvicorn 前不要再套压缩代理 |
| 流中途断、done 不来 | 后端异常被吞：看 uvicorn 日志；确认 except 路径也 yield 了 `error` 帧 |
| 401/invalid api key | `.env` 没加载（启动目录不是项目根）或 key 无效；GLM 的 base_url 必须是 `…/api/paas/v4` |
| 工具调了但无结果/流挂起 | FunctionTool 未 ALLOW 又没处理 `RequireUserConfirmEvent`；见 references/backend.md |
| antd 按钮样式怪 | index.css 误引了 preflight；改回只引 theme+utilities |
| npm run build 类型报错 | `tsc --noEmit` 先跑；优先看 `types.ts` 与后端协议是否漂移 |

## 测试与静态检查

```bash
pytest backend/tests                 # 后端（离线，不调模型）
cd frontend && npm run build         # tsc --noEmit + vite build 双校验
```

提交前两个都过；聊天端点测试用假 agent（模板 tests 已示范 monkeypatch
`build_agent`），不要在 CI 里烧真实 token。

## 生产部署

后端（模板 `pyproject.toml` 已含 uvicorn[standard]）：

```bash
uv venv --python 3.12 && uv pip install -e backend
cp backend/.env.example .env && vim .env      # 真实密钥/数据库
uvicorn main:app --app-dir backend --host 0.0.0.0 --port 8000 --workers 2
```

- 多 worker 时 sqlite 不合适，切 `postgresql+asyncpg://…` 后再开 workers。
- 进程守护交给 systemd/supervisor/容器编排；uvicorn 前置 nginx 时保留
  `X-Accel-Buffering: no` 并对 `/api/chat` 关闭 `proxy_buffering`。

前端：

```bash
cd frontend && npm ci && npm run build   # 产物在 frontend/dist
```

- nginx 托管 `dist/` 并把 `/api/` 反代到后端——同源部署无需 CORS。
- SPA 路由（若以后引入 react-router）记得 `try_files $uri /index.html;`。

安全清单（上线前）：

- `.env` 不进 git；密钥定期轮换；日志不打印 `openai_api_key`。
- 工具函数是模型可触达的代码执行面：模板示例工具无害，自建工具要校验入参
  （httpx 工具禁内网地址、限制超时与响应大小）。
- 给 `/api` 加鉴权（模板未带，属预期最小骨架）；对外暴露前压测 SSE 并发。

## 从骨架到规模化

1. 会话/消息量上来：上 Alembic 迁移 + PostgreSQL。
2. 需要服务化（多 agent 会话管理、团队、Web 管理台）：切 AgentScope 内置
   service 层——查 `agentscope-skill` 的 deployment_guide，不要自造轮子。
3. 多智能体编排（worker-as-tool、pipeline）：查 `agentscope-skill` 的
   multi_agent_orchestration。
