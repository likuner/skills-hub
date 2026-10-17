# 架构与目录规范

## 总体分层

```text
浏览器(React/TS) --HTTP/SSE--> FastAPI(Uvicorn) --async--> AgentScope Agent
                                   |                        ├── 模型: OpenAIChatModel(GLM/DeepSeek/…)
                                   |                        └── 工具: Toolkit(FunctionTool…)
                                   └── SQLAlchemy async --> SQLite(dev)/PostgreSQL(prod)
```

职责边界：

- **前端只管呈现与交互**：会话列表、消息气泡、流式渲染、输入。不解析模型协议，
  只消费后端 SSE 事件；不持有密钥，所有模型调用都经后端。
- **后端是唯一信任边界**：鉴权（如需）、密钥、Agent 编排、工具执行、持久化。
- **Agent 无状态、会话有状态**：每次请求用历史消息重建 Agent 上下文（模板实现）。
  会话规模大后再切 AgentScope 服务层（session 管理/持久化），那是 agentscope-skill
  的 deployment_guide 覆盖的范围。

## SSE 事件协议（前后端契约）

`POST /api/chat` 返回 `text/event-stream`，每帧 `data: <JSON>\n\n`：

```jsonc
{"type": "delta",     "text": "增量文本"}
{"type": "thinking",  "text": "推理增量（模型支持时）"}
{"type": "tool_start","name": "get_weather"}
{"type": "tool_end",  "name": "get_weather"}
{"type": "done",      "conversation_id": "…", "message_id": 123, "finished_reason": "completed"}
{"type": "error",     "message": "人话错误描述"}
```

- `done` 必发（含出错路径也要尽量发 `error` 再结束），前端据此解除 streaming 态。
- 首条消息可能新建会话，所以 `done` 要回带 `conversation_id`，前端据此纠正当前会话。
- 扩展事件类型时：改 `backend/main.py` 的生成端 + `frontend/src/types.ts` 的
  `ChatStreamEvent` 联合 + `store/chat.ts` 的 switch，三处同步改。

选 SSE 而非 WebSocket 的原因：单向推送足够、HTTP 语义可穿代理、断线重连简单
（重发即可，服务端有全量消息落库，不依赖连接内状态）。需要双向（打断执行、
工具人工确认）时再升级 WebSocket 或改用 AgentScope 的事件回传机制。

## 状态分工（zustand vs SWR）

| 数据 | 归属 | 理由 |
| --- | --- | --- |
| 会话列表、历史消息 | **SWR**（key 即 URL） | 服务端数据，天然可重验证、可缓存、多组件共享 |
| 当前会话 id、菜单开合 | **zustand** | 纯客户端 UI 状态 |
| 流式进行中标志、流式文本、thinking、工具提示 | **zustand** | 高频写入（每个 delta 一次），SWR 不适合做管道 |

协作方式：zustand 的 `send()` 完成后回调组件传入的 `onDone`，组件在里面调
SWR 的 `mutate()` 拉最终落库的消息与会话列表——流式期间展示 zustand 里的临时
文本，`done` 后以数据库为准。不要把流式文本写进 SWR 缓存。

## 数据模型

```text
Conversation(id: uuid str pk, title: str, created_at: datetime)
Message(id: int pk autoincr, conversation_id: str fk+index,
        role: 'user'|'assistant', content: text, created_at: datetime)
```

- 历史重建：按时间升序取出，`user→UserMsg`、`assistant→AssistantMsg`，连同新
  输入一起作为 `list[Msg]` 传给 `agent.reply_stream()`；系统提示在 Agent 构造时
  已注入，历史里不要再混入 SystemMsg。
- 加实体（如文件、知识库 chunk）时沿用 SQLAlchemy 2.0 `Mapped`/`mapped_column`
  风格，async session 一律 `async with`；迁移上 Alembic，别用手改表。

## 目录纪律

- 后端保持平铺模块（`main/agent/config/database/models`），在单服务规模内最清晰；
  拆包的时机是出现第二个聚合根（如"知识库管理"），而不是文件行数。
- 前端新增页面级功能时在 `src/` 下按 `components/ hooks/ store/ api 化` 的既有
  模式扩展，领域类型集中放 `types.ts`，避免散落定义。
- 不要把构建产物、`.env`、`*.db` 提交进 git（scaffold 的 `.gitignore` 已配好）。
