# 后端模式（Python 3.12 + AgentScope 2.x + FastAPI）

所有代码以 agentscope **2.0.10** 验证；升级后先用 agentscope-skill 的
`view_module_signature.py` 复核签名再动手。

## 环境约定（uv + 3.12）

```bash
cd <project>
uv venv --python 3.12                 # 固定 3.12.x
uv pip install -e backend             # 读 backend/pyproject.toml
source .venv/bin/activate
pytest backend/tests
uvicorn main:app --app-dir backend --reload --port 8000   # 注意在项目根执行
```

- `pyproject.toml` 写 `requires-python = ">=3.12,<3.13"`，锁死小版本段。
- 在项目根启动：`.env`（`SettingsConfigDict(env_file=".env")` 相对 CWD）与
  sqlite 文件都落在根目录，便于 `.gitignore` 统一管理。
- 新增依赖：改 `backend/pyproject.toml` 后 `uv pip install -e backend`，不要
  `pip install` 裸装（会漂移出未声明依赖）。

## 配置（pydantic-settings）

```python
from functools import lru_cache
from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")
    openai_base_url: str = "https://open.bigmodel.cn/api/paas/v4"
    openai_api_key: str = ""
    openai_model: str = "glm-5.3-flash"
    database_url: str = "sqlite+aiosqlite:///./app.db"
    cors_origins: str = "http://localhost:5173"

@lru_cache
def get_settings() -> Settings:
    return Settings()

settings = get_settings()
```

- 密钥只进 `.env`/环境变量；`Settings` 实例全局单例，测试里用
  `get_settings.cache_clear()` + monkeypatch 环境变量覆盖。
- 列表型配置（如 cors_origins）用逗号分隔字符串再 `.split(",")`，比 JSON 环境变量省事。

## Agent 构建（模板 agent.py 的要点）

```python
from agentscope.agent import Agent
from agentscope.credential import OpenAICredential
from agentscope.model import OpenAIChatModel
from agentscope.permission import PermissionBehavior, PermissionDecision
from agentscope.tool import FunctionTool, Toolkit

_auto_allow = PermissionDecision(behavior=PermissionBehavior.ALLOW,
                                 message="服务端自动放行")

agent = Agent(
    name="Assistant",
    system_prompt="…",
    model=OpenAIChatModel(
        credential=OpenAICredential(api_key=settings.openai_api_key,
                                    base_url=settings.openai_base_url),
        model=settings.openai_model,
        stream=True,
    ),
    toolkit=Toolkit(tools=[
        FunctionTool(get_current_time, permission=_auto_allow),
        FunctionTool(get_weather, permission=_auto_allow),
    ]),
)
```

- **credential 带 `base_url` 即可接任何 OpenAI 兼容端点**（GLM/DeepSeek/通义/本地 vLLM）。
- `FunctionTool` 默认要求人工确认（会发 `RequireUserConfirmEvent`）。Web 服务里
  两个选择：像模板那样 `permission=ALLOW` 静默放行（信任函数本身安全），或在
  SSE 循环里捕获 `RequireUserConfirmEvent` 转成交互事件——不要忽略它，否则流
  挂起等输入。
- 工具函数写法：docstring 首行是给模型看的描述，参数用 Google 风格 `Args:` 注释，
  AgentScope 会据此生成 schema；返回字符串。异步工具直接 `async def`（httpx 示例
  见模板的 `get_weather`）。

## 流式 SSE 端点（main.py 的要点）

```python
from agentscope.event import (ReplyEndEvent, TextBlockDeltaEvent,
                              TextBlockStartEvent, ThinkingBlockDeltaEvent,
                              ToolCallEndEvent, ToolCallStartEvent)

async def event_stream(agent, history):
    parts: list[str] = []
    try:
        async for ev in agent.reply_stream(history):
            match ev:
                case TextBlockStartEvent() if parts:
                    parts.append("\n\n")            # 多段文本（工具调用间）分隔
                case TextBlockDeltaEvent():
                    parts.append(ev.delta)
                    yield sse({"type": "delta", "text": ev.delta})
                case ThinkingBlockDeltaEvent():
                    yield sse({"type": "thinking", "text": ev.delta})
                case ToolCallStartEvent():
                    yield sse({"type": "tool_start", "name": ev.name})
                case ToolCallEndEvent():
                    yield sse({"type": "tool_end", "name": ev.name})
                case ReplyEndEvent():
                    yield sse({"type": "done", "finished_reason": ev.finished_reason.value})
    except Exception as e:                          # 网络断/密钥错/限流
        yield sse({"type": "error", "message": str(e)})

def sse(obj: dict) -> str:
    return f"data: {json.dumps(obj, ensure_ascii=False)}\n\n"
```

- 响应头带 `Cache-Control: no-cache` 与 `X-Accel-Buffering: no`（nginx 场景），
  `StreamingResponse(..., media_type="text/event-stream")`。
- 消费完在 `finally` 里把 `parts` 拼成的助手消息落库；出错时已有内容也要落，
  前端刷新后不丢半截回答。
- `reply_stream()` 的生成器结束≠一定成功（可能停在等待确认）；以 `ReplyEndEvent`
  为完成信号，模板工具已 `ALLOW` 所以正常流不会出现等待。
- 每次 `reply()` 内部同样消费事件，简单场景可以不用手写循环，但 SSE 场景必须
  用 `reply_stream()`。

## SQLAlchemy async

```python
engine = create_async_engine(settings.database_url)
SessionLocal = async_sessionmaker(engine, expire_on_commit=False)

async def init_db():                                # 幂等建表，lifespan 里调用
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
```

- 模型用 2.0 风格：`Mapped[str] = mapped_column(String(64), primary_key=True)`。
- FastAPI 依赖注入 session：`async with SessionLocal() as s: yield s`。
- 换 PostgreSQL：`DATABASE_URL=postgresql+asyncpg://…`，其余代码不动（先
  `uv pip install asyncpg`）。

## 测试（pytest，离线）

- `httpx.AsyncClient(transport=ASGITransport(app=app))` 直打 ASGI，不起端口。
- ASGITransport 不跑 lifespan：fixture 里手动 `await init_db()`。
- 聊天端点测试不调真实模型：monkeypatch `main.build_agent` 返回假 agent——
  一个 `reply_stream` 产出固定 delta/done 事件的简单类，见模板 tests。
- 跑法：项目根 `pytest backend/tests`（pyproject 已配 `pythonpath = ["backend"]`）。
