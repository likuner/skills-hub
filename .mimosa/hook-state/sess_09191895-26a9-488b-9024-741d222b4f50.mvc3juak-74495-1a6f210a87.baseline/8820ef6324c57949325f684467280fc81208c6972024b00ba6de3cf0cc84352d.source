import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import tailwindcss from "@tailwindcss/vite";

export default defineConfig({
  plugins: [react(), tailwindcss()],
  server: {
    proxy: {
      // 开发期把 /api 转发给后端；生产由反向代理承担，前端永远只写相对路径
      "/api": {
        target: "http://localhost:8000",
        changeOrigin: true,
      },
    },
  },
});
