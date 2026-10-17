#!/usr/bin/env bash
# 一键同时启动后端(:8000)与前端(:5173)，Ctrl-C 一并退出。
set -euo pipefail
cd "$(dirname "$0")"

if [ ! -x ".venv/bin/uvicorn" ]; then
  echo "后端未就绪：请先执行 uv venv --python 3.12 && uv pip install -e backend" >&2
  exit 1
fi
if [ ! -d "frontend/node_modules" ]; then
  echo "前端未就绪：请先执行 (cd frontend && npm install)" >&2
  exit 1
fi

# Ctrl-C 时连同子进程一起退出
trap 'kill 0' INT TERM

(.venv/bin/uvicorn main:app --app-dir backend --reload --port 8000 \
  | sed -u "s/^/[api] /") &
(cd frontend && npm run dev | sed -u "s/^/[web] /") &

wait
