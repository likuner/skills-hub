/** 消息区：历史气泡 + 流式中的临时气泡（zustand），滚动到底用 ahooks 节流。 */

import { useThrottleFn } from "ahooks";
import { useEffect, useRef } from "react";
import { Empty, Skeleton } from "antd";
import { useChatStore } from "../store/chat";
import type { Message } from "../types";

interface ChatMessagesProps {
  messages: Message[];
  loading: boolean;
}

export function ChatMessages({ messages, loading }: ChatMessagesProps) {
  const containerRef = useRef<HTMLDivElement>(null);
  const { streamText, thinking, toolHint, streaming, error } = useChatStore();

  // 流式期间 delta 很密：滚动到底节流到 200ms 一次
  const { run: scrollToBottom } = useThrottleFn(
    () => {
      const el = containerRef.current;
      if (el) el.scrollTop = el.scrollHeight;
    },
    { wait: 200 },
  );

  useEffect(() => {
    scrollToBottom();
  }, [messages.length, streamText, thinking, scrollToBottom]);

  const hasContent = messages.length > 0 || streaming;

  return (
    <div ref={containerRef} className="min-h-0 flex-1 overflow-y-auto px-3 py-4 md:px-6">
      {loading ? (
        <Skeleton active paragraph={{ rows: 6 }} />
      ) : !hasContent ? (
        <div className="flex h-full items-center justify-center">
          <Empty description="开始新的对话吧" image={Empty.PRESENTED_IMAGE_SIMPLE} />
        </div>
      ) : (
        <div className="mx-auto flex max-w-2xl flex-col gap-3">
          {messages.map((msg) => (
            <Bubble key={msg.id} role={msg.role} content={msg.content} />
          ))}

          {streaming && (
            <div className="flex flex-col gap-1">
              {thinking && (
                <div className="max-w-[85%] self-start rounded-xl bg-amber-50 px-3 py-1 text-xs text-amber-700">
                  {thinking}
                </div>
              )}
              {toolHint && (
                <div className="max-w-[85%] self-start rounded-xl bg-purple-50 px-3 py-1 text-xs text-purple-600">
                  {toolHint}
                </div>
              )}
              <Bubble role="assistant" content={streamText || "…"} streaming />
            </div>
          )}

          {!streaming && error && (
            <div className="self-center rounded-lg bg-red-50 px-3 py-1 text-xs text-red-600">
              {error}
            </div>
          )}
        </div>
      )}
    </div>
  );
}

function Bubble({
  role,
  content,
  streaming = false,
}: {
  role: Message["role"];
  content: string;
  streaming?: boolean;
}) {
  const isUser = role === "user";
  return (
    <div className={`flex ${isUser ? "justify-end" : "justify-start"}`}>
      <div
        className={`max-w-[85%] whitespace-pre-wrap break-words rounded-2xl px-4 py-2 text-sm leading-6 md:max-w-xl ${
          isUser ? "bg-blue-500 text-white" : "bg-gray-100 text-gray-900"
        }`}
      >
        {content}
        {streaming && <span className="ml-0.5 inline-block h-4 w-2 animate-pulse bg-gray-400 align-middle" />}
      </div>
    </div>
  );
}
