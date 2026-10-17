"""测试环境：独立 sqlite 库 + ASGI 客户端 fixture（不调真实模型）。"""

import os
import tempfile

# 必须在导入 app 相关模块之前设置，Settings/database 在导入时读取
_TEST_DIR = tempfile.mkdtemp(prefix="{{PROJECT_NAME}}_test_")
os.environ["DATABASE_URL"] = f"sqlite+aiosqlite:///{_TEST_DIR}/test.db"

import pytest  # noqa: E402
from httpx import ASGITransport, AsyncClient  # noqa: E402


@pytest.fixture
async def client():
    import database
    import main

    await database.init_db()
    transport = ASGITransport(app=main.app)
    async with AsyncClient(transport=transport, base_url="http://test") as c:
        yield c
