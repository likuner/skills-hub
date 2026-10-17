# 前端模式（React + TypeScript + Vite + antd + Tailwind）

## TypeScript 约定

- 严格模式开满（模板 tsconfig），`npm run build` 先 `tsc --noEmit` 再 vite build，
  类型错误视为构建失败。
- 领域类型（`Conversation`/`Message`/`ChatStreamEvent`）集中放 `src/types.ts`，
  与后端 SSE 契约一一对应；改协议时同步改这里。
- 导入类型用 `import type`，与 antd 运行时导入分开。
- SWR 用泛型保证 fetcher 类型：`useSWR<Conversation[]>(url, jsonFetcher)`。

## 状态：zustand + SWR 协作

```ts
export const useChatStore = create<ChatState>((set, get) => ({
  currentId: null, streaming: false, streamText: "", thinking: "",
  send: async (content, { onDone }) => {
    set({ streaming: true, streamText: "", thinking: "", error: null });
    let text = "";
    await streamChat(get().currentId!, content, (e) => {
      if (e.type === "delta") { text += e.text; set({ streamText: text }); }
      // thinking / tool_start / tool_end / done / error 同理
    });
    set({ streaming: false });
    onDone();   // 组件里调 SWR mutate，拉落库后的最终消息
  },
}));
```

- 高频 delta 只写 zustand（同步、无请求层开销）；`done` 后的数据一律以 SWR
  重新拉取的数据库为准，不在前端"续写"SWR 缓存。
- 需要 SWR 全局重验证时用 `useSWRConfig().mutate(key)`。

## SSE 消费（api.ts）

用 `fetch` + `ReadableStream` 手写（EventSource 不支持 POST）：

```ts
const res = await fetch("/api/chat", { method: "POST", /* body */ });
const reader = res.body!.getReader();
const decoder = new TextDecoder();
let buf = "";
for (;;) {
  const { done, value } = await reader.read();
  if (done) break;
  buf += decoder.decode(value, { stream: true });
  const lines = buf.split("\n");
  buf = lines.pop() ?? "";              // 半行留到下一帧
  for (const line of lines) {
    if (!line.startsWith("data:")) continue;
    onEvent(JSON.parse(line.slice(5).trim()));
  }
}
```

- 开发期 `/api` 走 Vite 代理（vite.config.ts），生产期由反向代理承担，前端代码
  永远只写相对路径 `/api/...`。
- `res.ok` 为假要先抛错（后端异常时 SSE 里也可能没有 error 帧）。

## antd × Tailwind 共存（高频坑）

Tailwind v4 的 preflight 会重置 `button`/`img` 等元素样式，与 antd 组件冲突
（按钮背景消失、图标错位）。**模板的 index.css 只引入两段**：

```css
@import "tailwindcss/theme.css";     /* 断点/变量，供 md: lg: 等使用 */
@import "tailwindcss/utilities.css"; /* 工具类 */
/* 刻意不引 preflight，antd 自带样式重置 */
```

不要图省事改回 `@import "tailwindcss"`。布局、间距、响应式用 Tailwind 工具类；
组件本身用 antd——两者分工而不是互相覆盖。

## 响应式规范（PC + Mobile）

- 判定：`src/hooks/useIsMobile.ts` 封装 `Grid.useBreakpoint()`，`!bp.md`（<768px）
  为移动端。组件只消费这个 hook，不要各自再算窗口宽。
- 布局：
  - 桌面：`flex` 双栏——左侧 `w-64` 会话侧栏 + 右侧聊天区。
  - 移动：侧栏内容整体装进 antd `Drawer`（`placement="left"`，宽 80%），顶栏放
    汉堡按钮；`ConversationList` 组件两处复用，选中后回调里顺手关 Drawer。
- 消息区滚动：容器 `overflow-y-auto`，流式期间用 ahooks `useThrottleFn` 节流
  滚到底（200ms），避免每个 delta 都触发一次 scroll。
- 输入区：吸附底部，移动端 padding 计入安全区
  `pb-[calc(0.75rem+env(safe-area-inset-bottom))]`；发送按钮触达面积 ≥44px。
- `index.html` 的 viewport 必须带 `viewport-fit=cover`，否则刘海屏安全区不生效。
- 自检两视口：DevTools 设备模式 375×812（iPhone）与 1280×800，确认侧栏抽屉化、
  长消息换行、输入区不被键盘遮挡。

## 组件惯例

- 消息气泡用 Tailwind 类而非内联样式：用户右对齐 `bg-blue-500 text-white`，
  助手左对齐 `bg-gray-100`，统一 `rounded-2xl max-w-[85%] md:max-w-2xl`。
- 流式中在助手气泡尾部渲染闪烁光标（`animate-pulse` 的小方块），`done` 后消失。
- `thinking`/`tool_hint` 在助手气泡上方以浅色小字展示（可折叠），不混入正文。
- antd 弹层（message/notification）经 `App` 组件（`antd` 的 `App`）拿实例，
  避免 ConfigProvider 上下文丢失。
