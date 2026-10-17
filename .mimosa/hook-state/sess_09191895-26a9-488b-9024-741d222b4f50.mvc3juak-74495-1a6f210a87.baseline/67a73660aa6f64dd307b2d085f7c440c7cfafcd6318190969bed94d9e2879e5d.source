"""集中配置：pydantic-settings 从 .env / 环境变量读取，密钥不进代码。"""

from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    # 模型接入（OpenAI 兼容协议；换 provider 只改这三项，代码零改动）
    openai_base_url: str = "https://open.bigmodel.cn/api/paas/v4"
    openai_api_key: str = ""
    openai_model: str = "glm-5.3-flash"

    # 数据库：开发用本地 sqlite；生产换 postgresql+asyncpg://user:pass@host/db
    database_url: str = "sqlite+aiosqlite:///./{{PROJECT_NAME}}.db"

    # CORS 白名单（逗号分隔）。开发期前端跑在 5173，由 Vite 代理转发 /api
    cors_origins: str = "http://localhost:5173"

    agent_name: str = "Assistant"
    agent_system_prompt: str = (
        "你是 {{PROJECT_NAME}} 的智能助手。回答简洁、准确、友好；"
        "涉及实时信息（时间、天气等）时优先调用可用工具。"
    )


@lru_cache
def get_settings() -> Settings:
    return Settings()


settings = get_settings()
