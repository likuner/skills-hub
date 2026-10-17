/** 统一的移动端判定：断线口收敛在一处，组件不要各自量窗口宽。 */

import { Grid } from "antd";

const { useBreakpoint } = Grid;

/** < 768px（antd md 断点以下）视为移动端。 */
export function useIsMobile(): boolean {
  const screens = useBreakpoint();
  // 首屏 breakpoint 可能尚未就绪，默认按桌面渲染避免闪烁
  return screens.md === false;
}
