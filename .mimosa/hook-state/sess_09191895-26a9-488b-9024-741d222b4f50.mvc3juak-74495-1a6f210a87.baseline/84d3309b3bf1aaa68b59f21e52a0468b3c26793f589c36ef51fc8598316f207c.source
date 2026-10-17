/** 领域类型：与后端 SSE 契约一一对应（改协议时同步改这里）。 */

export interface Conversation {
  id: string;
  title: string;
  created_at: string;
}

export type MessageRole = "user" | "assistant";

export interface Message {
  id: number;
  role: MessageRole;
  content: string;
  created_at: string;
}

export type ChatStreamEvent =
  | { type: "delta"; text: string }
  | { type: "thinking"; text: string }
  | { type: "tool_start"; name: string }
  | { type: "tool_end"; name: string }
  | { type: "done"; conversation_id: string; finished_reason: string }
  | { type: "error"; message: string };
