/** 会话列表：桌面渲染在 Sider，移动端渲染在 Drawer（同一组件两处复用）。 */

import { PlusOutlined } from "@ant-design/icons";
import { App as AntApp, Button, Empty, List, Popconfirm, Skeleton } from "antd";
import useSWR from "swr";
import { useSWRConfig } from "swr";
import { jsonFetcher, createConversation } from "../api";
import { useChatStore } from "../store/chat";
import type { Conversation } from "../types";

interface ConversationListProps {
  /** 选中会话后的回调（移动端 Drawer 借此关闭自身）。 */
  onAfterSelect?: () => void;
}

export function ConversationList({ onAfterSelect }: ConversationListProps) {
  const { message } = AntApp.useApp();
  const { mutate: globalMutate } = useSWRConfig();
  const { data, isLoading, mutate } = useSWR<Conversation[]>(
    "/api/conversations",
    jsonFetcher,
  );
  const currentId = useChatStore((s) => s.currentId);
  const setCurrentId = useChatStore((s) => s.setCurrentId);

  const handleCreate = async () => {
    try {
      const conv = await createConversation();
      await mutate();
      setCurrentId(conv.id);
      onAfterSelect?.();
    } catch {
      message.error("创建会话失败");
    }
  };

  const handleDelete = async (id: string) => {
    const res = await fetch(`/api/conversations/${id}`, { method: "DELETE" });
    if (res.ok) {
      if (currentId === id) setCurrentId(null);
      await mutate();
      await globalMutate(`/api/conversations/${id}/messages`);
    }
  };

  return (
    <div className="flex h-full flex-col">
      <div className="p-3">
        <Button type="primary" icon={<PlusOutlined />} block onClick={handleCreate}>
          新建对话
        </Button>
      </div>
      <div className="min-h-0 flex-1 overflow-y-auto px-2">
        {isLoading ? (
          <Skeleton active paragraph={{ rows: 4 }} />
        ) : !data || data.length === 0 ? (
          <Empty description="还没有对话" image={Empty.PRESENTED_IMAGE_SIMPLE} />
        ) : (
          <List
            dataSource={data}
            renderItem={(conv) => (
              <List.Item
                className={`min-h-11 cursor-pointer rounded-lg px-3 transition-colors ${
                  conv.id === currentId ? "bg-blue-50" : "hover:bg-gray-100"
                }`}
                onClick={() => {
                  setCurrentId(conv.id);
                  onAfterSelect?.();
                }}
              >
                <div className="min-w-0 flex-1">
                  <div className="truncate text-sm">{conv.title}</div>
                </div>
                <Popconfirm
                  title="删除这个会话？"
                  onConfirm={(e) => {
                    e?.stopPropagation();
                    void handleDelete(conv.id);
                  }}
                  onCancel={(e) => e?.stopPropagation()}
                >
                  <Button
                    type="text"
                    size="small"
                    danger
                    onClick={(e) => e.stopPropagation()}
                    aria-label="删除会话"
                  >
                    删除
                  </Button>
                </Popconfirm>
              </List.Item>
            )}
          />
        )}
      </div>
    </div>
  );
}
