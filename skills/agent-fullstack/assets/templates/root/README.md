# {{PROJECT_NAME}}

Agent 全栈应用：Python 3.12 + AgentScope 2.x 后端（FastAPI，SSE 流式），React + TypeScript 前端（Vite + antd + Tailwind，PC/Mobile 响应式），模型经 OpenAI 兼容协议接入（默认智谱 GLM）。

## 环境要求

- Python 3.12.x（用 [uv](https://docs.astral.sh/uv/) 固定）
- Node.js ≥ 18 / npm ≥ 9

## 快速开始

```bash
# 1. 后端环境（项目根执行）
uv venv --python 3.12
uv pip install -e backend

# 2. 配置密钥（默认智谱 GLM；换 provider 只改这三个变量）
cp backend/.env.example .env
# 编辑 .env 填入 OPENAI_API_KEY

# 3. 前端依赖
cd frontend && npm install && cd ..

# 4. 一键启动（后端 :8000，前端 :5173）
bash dev.sh
```

打开 http://localhost:5173 。内置示例工具：问"现在几点""北京天气怎么样"可验证工具调用。

## 常用命令

```bash
pytest backend/tests                                      # 后端测试（离线，不调模型）
uvicorn main:app --app-dir backend --reload --port 8000   # 仅启动后端
cd frontend && npm run dev                                # 仅启动前端
cd frontend && npm run build                              # 前端构建（tsc + vite）
```

## 目录

```text
backend/    FastAPI + AgentScope（main/agent/config/database/models + tests）
frontend/   React + TS（Vite + antd + Tailwind + zustand/SWR/ahooks）
dev.sh      一键启动前后端
.env        配置（含密钥，勿提交；从 backend/.env.example 复制）
```

## 模型接入

`.env` 中三项控制模型，代码零改动：

| Provider | OPENAI_BASE_URL | OPENAI_MODEL |
| --- | --- | --- |
| 智谱 GLM（默认） | `https://open.bigmodel.cn/api/paas/v4` | `glm-5.3-flash`（旗舰 `glm-5.3`） |
| DeepSeek | `https://api.deepseek.com/v1` | `deepseek-chat` |
| 通义千问 | `https://dashscope.aliyuncs.com/compatible-mode/v1` | `qwen-plus` |
