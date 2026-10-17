#!/usr/bin/env bash
# 一键启动项目的前后端开发服务（等价于项目内的 dev.sh，便于在任意目录调用）。
# 用法：bash run_dev.sh <项目目录>
set -euo pipefail

PROJECT_DIR="${1:-.}"
PROJECT_DIR="$(cd "$PROJECT_DIR" && pwd)"

if [ -f "$PROJECT_DIR/dev.sh" ]; then
  exec bash "$PROJECT_DIR/dev.sh"
fi

# 兜底：项目内没有 dev.sh 时直接拉起两个进程
cd "$PROJECT_DIR"
[ -x ".venv/bin/uvicorn" ] || { echo "后端未就绪：uv venv --python 3.12 && uv pip install -e backend" >&2; exit 1; }
[ -d "frontend/node_modules" ] || { echo "前端未就绪：(cd frontend && npm install)" >&2; exit 1; }

trap 'kill 0' INT TERM

(.venv/bin/uvicorn main:app --app-dir backend --reload --port 8000 \
  | sed -u "s/^/[api] /") &
(cd frontend && npm run dev | sed -u "s/^/[web] /") &

wait
