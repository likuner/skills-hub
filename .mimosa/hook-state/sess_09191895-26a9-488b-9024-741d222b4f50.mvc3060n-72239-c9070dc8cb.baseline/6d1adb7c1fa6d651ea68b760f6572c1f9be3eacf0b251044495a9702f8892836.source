/**
 * 响应式根布局：
 * - 桌面（>=768px）：左侧固定侧栏（会话列表）+ 右侧聊天区
 * - 移动端：侧栏收进 Drawer（汉堡按钮唤起），聊天区全宽
 */

import { MenuOutlined, SendOutlined } from "@ant-design/icons";
import { Button, Drawer, Input } from "antd";
import { useState } from "react";
import useSWR from "swr";
import { useSWRConfig } from "swr";
import { createConversation, fetchMessages, jsonFetcher } from "./api";
import { ChatMessages } from "./components/ChatMessages";
import { ConversationList } from "./components/ConversationList";
import { useIsMobile } from "./hooks/useIsMobile";
import { useChatStore } from "./store/chat";
import type { Conversation } from "./types";

export default function App() {
  const isMobile = useIsMobile();
  const [drawerOpen, setDrawerOpen] = useState(false);
  const [input, setInput] = useState("");

  const { currentId, setCurrentId, send, streaming } = useChatStore();
  const { data: conversations } = useSWR<Conversation[]>(
    "/api/conversations",
    jsonFetcher,
  );
  const { data: messages, isLoading: messagesLoading, mutate: mutateMessages } = useSWR(
    currentId ? `/api/conversations/${currentId}/messages` : null,
    fetchMessages,
  );
  const { mutate: globalMutate } = useSWRConfig();

  const title =
    conversations?.find((c) => c.id === currentId)?.title ?? "{{PROJECT_NAME}}";

  const refreshAfterSend = () => {
    void mutateMessages();
    void globalMutate("/api/conversations");
  };

  const handleSend = async () => {
    const content = input.trim();
    if (!content || streaming) return;

    let convId = currentId;
    if (!convId) {
      const conv = await createConversation();
      setCurrentId(conv.id);
      convId = conv.id;
      void globalMutate("/api/conversations");
    }

    setInput("");
    await send(content, { onDone: refreshAfterSend });
  };

  return (
    <div className="flex h-dvh">
      {!isMobile && (
        <aside className="w-64 shrink-0 border-r border-gray-200 bg-white">
          <ConversationList />
        </aside>
      )}

      <main className="flex min-w-0 flex-1 flex-col bg-gray-50">
        <header className="flex h-12 shrink-0 items-center gap-2 border-b border-gray-200 bg-white px-3">
          {isMobile && (
            <Button
              type="text"
              icon={<MenuOutlined />}
              onClick={() => setDrawerOpen(true)}
              aria-label="打开会话列表"
              className="min-w-11"
            />
          )}
          <span className="truncate text-sm font-medium">{title}</span>
        </header>

        <ChatMessages messages={messages ?? []} loading={!!currentId && messagesLoading} />

        <footer className="shrink-0 border-t border-gray-200 bg-white p-3 pb-[calc(0.75rem+env(safe-area-inset-bottom))]">
          <div className="mx-auto flex max-w-2xl items-end gap-2">
            <Input.TextArea
              value={input}
              onChange={(e) => setInput(e.target.value)}
              onPressEnter={(e) => {
                if (!e.shiftKey) {
                  e.preventDefault();
                  void handleSend();
                }
              }}
              placeholder="输入消息，Enter 发送，Shift+Enter 换行"
              autoSize={{ minRows: 1, maxRows: 4 }}
              className="flex-1"
            />
            <Button
              type="primary"
              icon={<SendOutlined />}
              loading={streaming}
              onClick={() => void handleSend()}
              aria-label="发送"
              className="h-9 min-w-11"
            />
          </div>
        </footer>
      </main>

      <Drawer
        title="会话"
        placement="left"
        width="80%"
        open={drawerOpen}
        onClose={() => setDrawerOpen(false)}
        styles={{ body: { padding: 0 } }}
      >
        <ConversationList onAfterSelect={() => setDrawerOpen(false)} />
      </Drawer>
    </div>
  );
}
