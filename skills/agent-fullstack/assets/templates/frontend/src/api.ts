/** HTTP 与 SSE：SWR fetcher、会话 CRUD、流式聊天消费。 */

import type { ChatStreamEvent, Conversation, Message } from "./types";

export async function jsonFetcher<T>(url: string): Promise<T> {
  const res = await fetch(url);
  if (!res.ok) throw new Error(`请求失败：${res.status}`);
  return res.json() as Promise<T>;
}

export async function createConversation(title?: string): Promise<Conversation> {
  const res = await fetch("/api/conversations", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ title }),
  });
  if (!res.ok) throw new Error(`创建会话失败：${res.status}`);
  return res.json() as Promise<Conversation>;
}

export async function fetchMessages(conversationId: string): Promise<Message[]> {
  return jsonFetcher<Message[]>(`/api/conversations/${conversationId}/messages`);
}

/**
 * 消费 POST /api/chat 的 SSE 流（EventSource 不支持 POST，用 fetch + ReadableStream）。
 * 半行数据留在缓冲区，等下一帧拼完整再解析。
 */
export async function streamChat(
  conversationId: string,
  content: string,
  onEvent: (event: ChatStreamEvent) => void,
): Promise<void> {
  const res = await fetch("/api/chat", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ conversation_id: conversationId, content }),
  });
  if (!res.ok || !res.body) {
    throw new Error(`聊天请求失败：${res.status}`);
  }

  const reader = res.body.getReader();
  const decoder = new TextDecoder();
  let buffer = "";

  for (;;) {
    const { done, value } = await reader.read();
    if (done) break;
    buffer += decoder.decode(value, { stream: true });
    const lines = buffer.split("\n");
    buffer = lines.pop() ?? "";
    for (const line of lines) {
      const trimmed = line.trim();
      if (!trimmed.startsWith("data:")) continue;
      try {
        onEvent(JSON.parse(trimmed.slice(5).trim()) as ChatStreamEvent);
      } catch {
        // 忽略无法解析的帧（如代理插入的杂音）
      }
    }
  }
}
