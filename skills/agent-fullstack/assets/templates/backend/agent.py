"""AgentScope Agent 构建：OpenAI 兼容模型 + 示例工具。

AgentScope 的 API 细节（事件、Toolkit、多智能体等）见 agentscope-skill；
本文件的写法已对 agentscope 2.0.10 验证。
"""

from datetime import datetime, timezone

import httpx
from agentscope.agent import Agent
from agentscope.credential import OpenAICredential
from agentscope.model import OpenAIChatModel
from agentscope.permission import PermissionBehavior, PermissionDecision
from agentscope.tool import FunctionTool, Toolkit

from config import settings

# Web 服务里没有终端确认环节：对可信工具显式放行，避免流式回复挂起等待人工确认。
# 自建工具如果可能产生副作用，请评估是否改用交互式确认（见 agentscope-skill）。
_AUTO_ALLOW = PermissionDecision(
    behavior=PermissionBehavior.ALLOW,
    message="service auto-allow for scaffold demo tools",
)


def get_current_time() -> str:
    """获取当前 UTC 时间（ISO 8601 格式）。"""
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


async def get_weather(city: str) -> str:
    """查询指定城市的当前天气（示例：演示用 httpx 调用外部 API 的工具写法）。

    Args:
        city: 城市名称（拼音或英文，如 Beijing、Shanghai、Hangzhou）。
    """
    async with httpx.AsyncClient(timeout=10) as client:
        geo_resp = await client.get(
            "https://geocoding-api.open-meteo.com/v1/search",
            params={"name": city, "count": 1, "language": "zh"},
        )
        results = geo_resp.json().get("results") or []
        if not results:
            return f"未找到城市：{city}"
        loc = results[0]
        wx_resp = await client.get(
            "https://api.open-meteo.com/v1/forecast",
            params={
                "latitude": loc["latitude"],
                "longitude": loc["longitude"],
                "current": "temperature_2m,relative_humidity_2m,wind_speed_10m",
                "timezone": "auto",
            },
        )
        current = wx_resp.json().get("current", {})
    return (
        f"{loc.get('name', city)}当前天气：气温 {current.get('temperature_2m')}°C，"
        f"湿度 {current.get('relative_humidity_2m')}%，"
        f"风速 {current.get('wind_speed_10m')} km/h"
    )


def build_agent() -> Agent:
    """每次请求重建无状态 Agent；会话上下文由调用方以历史消息方式传入。"""
    return Agent(
        name=settings.agent_name,
        system_prompt=settings.agent_system_prompt,
        model=OpenAIChatModel(
            credential=OpenAICredential(
                api_key=settings.openai_api_key,
                base_url=settings.openai_base_url,
            ),
            model=settings.openai_model,
            stream=True,
        ),
        toolkit=Toolkit(
            tools=[
                FunctionTool(get_current_time, permission=_AUTO_ALLOW),
                FunctionTool(get_weather, permission=_AUTO_ALLOW),
            ],
        ),
    )
