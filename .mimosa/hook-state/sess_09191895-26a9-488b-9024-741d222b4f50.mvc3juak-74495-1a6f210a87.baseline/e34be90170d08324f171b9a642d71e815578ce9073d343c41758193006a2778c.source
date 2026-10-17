"""离线接口测试：不调真实模型（chat 用假 Agent 替身）。"""

from agentscope.event import ReplyEndEvent, TextBlockDeltaEvent

import main


class FakeAgent:
    """产出固定 delta/done 事件的假 Agent，替代真实模型调用。"""

    async def reply_stream(self, inputs):
        for text in ("你好", "，世界"):
            yield TextBlockDeltaEvent(reply_id="r1", block_id="b1", delta=text)
        yield ReplyEndEvent(session_id="s1", reply_id="r1")


async def test_health(client):
    resp = await client.get("/api/health")
    assert resp.status_code == 200
    assert resp.json() == {"status": "ok"}


async def test_conversation_crud(client):
    resp = await client.post("/api/conversations", json={"title": "测试会话"})
    assert resp.status_code == 200
    conv = resp.json()
    assert conv["title"] == "测试会话"

    resp = await client.get("/api/conversations")
    assert any(c["id"] == conv["id"] for c in resp.json())

    resp = await client.get(f"/api/conversations/{conv['id']}/messages")
    assert resp.status_code == 200
    assert resp.json() == []

    resp = await client.delete(f"/api/conversations/{conv['id']}")
    assert resp.json() == {"ok": True}


async def test_invalid_conversation_id_rejected(client):
    resp = await client.get("/api/conversations/not-a-valid-id/messages")
    assert resp.status_code == 404


async def test_chat_stream(client, monkeypatch):
    async def fake_build_agent():
        return FakeAgent()

    monkeypatch.setattr(main, "build_agent", fake_build_agent)

    resp = await client.post("/api/chat", json={"content": "打个招呼"})
    assert resp.status_code == 200
    assert resp.headers["content-type"].startswith("text/event-stream")
    body = resp.text
    assert '"type": "delta"' in body
    assert "你好" in body and "，世界" in body
    assert '"type": "done"' in body

    # done 帧里回带 conversation_id，前端据此纠正当前会话
    done_line = next(line for line in body.splitlines() if '"done"' in line)
    assert '"conversation_id":' in done_line

    # 用户与助手消息均落库
    import json

    conv_id = json.loads(done_line.split("data: ", 1)[1])["conversation_id"]
    resp = await client.get(f"/api/conversations/{conv_id}/messages")
    roles = [m["role"] for m in resp.json()]
    assert roles == ["user", "assistant"]


async def test_chat_empty_content_rejected(client):
    resp = await client.post("/api/chat", json={"content": "   "})
    assert resp.status_code == 422
