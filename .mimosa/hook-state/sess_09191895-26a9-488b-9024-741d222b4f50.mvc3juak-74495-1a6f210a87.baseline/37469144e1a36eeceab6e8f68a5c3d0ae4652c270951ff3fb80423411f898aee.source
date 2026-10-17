/**
 * 聊天客户端状态（zustand）：当前会话、流式输出状态机。
 * 会话列表/历史消息等服务端数据归 SWR 管，见 components/。
 */

import { create } from "zustand";
import { streamChat } from "../api";

interface SendOptions {
  /** 流结束后回调：组件用它触发 SWR 重新拉取（落库后的最终消息/会话列表）。 */
  onDone: () => void;
}

interface ChatState {
  currentId: string | null;
  streaming: boolean;
  streamText: string;
  thinking: string;
  toolHint: string | null;
  error: string | null;
  setCurrentId: (id: string | null) => void;
  send: (content: string, options: SendOptions) => Promise<void>;
}

export const useChatStore = create<ChatState>((set, get) => ({
  currentId: null,
  streaming: false,
  streamText: "",
  thinking: "",
  toolHint: null,
  error: null,

  setCurrentId: (id) =>
    set({ currentId: id, streamText: "", thinking: "", toolHint: null, error: null }),

  send: async (content, { onDone }) => {
    if (get().streaming) return;
    const conversationId = get().currentId;
    if (!conversationId) return;

    set({ streaming: true, streamText: "", thinking: "", toolHint: null, error: null });
    let text = "";
    try {
      await streamChat(conversationId, content, (event) => {
        switch (event.type) {
          case "delta":
            text += event.text;
            set({ streamText: text });
            break;
          case "thinking":
            set({ thinking: get().thinking + event.text });
            break;
          case "tool_start":
            set({ toolHint: `正在调用工具：${event.name}` });
            break;
          case "tool_end":
            set({ toolHint: null });
            break;
          case "done":
            // 首条消息会新建会话，以后端返回的 id 为准
            set({ currentId: event.conversation_id });
            break;
          case "error":
            set({ error: event.message });
            break;
        }
      });
    } catch (err) {
      set({ error: err instanceof Error ? err.message : String(err) });
    } finally {
      set({ streaming: false });
      onDone();
    }
  },
}));
