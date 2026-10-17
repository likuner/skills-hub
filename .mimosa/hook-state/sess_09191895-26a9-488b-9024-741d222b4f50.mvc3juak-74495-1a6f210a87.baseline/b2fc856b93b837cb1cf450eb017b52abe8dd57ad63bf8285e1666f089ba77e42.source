#!/usr/bin/env python3
"""环境自检：python 3.12.x / node / npm / uv 与后端关键包。

用法：
    python check_env.py            # 检查当前解释器与全局命令
    .venv/bin/python check_env.py  # 建议在项目 venv 内运行

任何一项失败时退出码为 1，并给出对应安装/修复命令。
"""

from __future__ import annotations

import importlib.util
import shutil
import subprocess
import sys

REQUIRED_PYTHON = (3, 12)
REQUIRED_PACKAGES = [
    "agentscope",
    "fastapi",
    "uvicorn",
    "pydantic_settings",
    "httpx",
    "sqlalchemy",
    "aiosqlite",
]

problems: list[str] = []


def report(ok: bool, label: str, detail: str, fix: str | None = None) -> None:
    mark = "✓" if ok else "✗"
    print(f" {mark} {label:<28} {detail}")
    if not ok:
        problems.append(f"{label}: {fix or detail}")


def check_python() -> None:
    v = sys.version_info
    detail = f"{v.major}.{v.minor}.{v.micro}（{sys.executable}）"
    if (v.major, v.minor) == REQUIRED_PYTHON:
        report(True, "Python", detail)
    else:
        report(
            False,
            "Python",
            detail,
            "项目环境请执行: uv venv --python 3.12 && uv pip install -e backend，"
            "再用 .venv/bin/python 运行本脚本",
        )


def check_node() -> None:
    if shutil.which("node") is None:
        report(False, "node", "未安装", "Node.js ≥ 18：https://nodejs.org/ 或 brew install node")
        return
    out = subprocess.run(["node", "--version"], capture_output=True, text=True, timeout=15)
    report(True, "node", out.stdout.strip())


def check_npm() -> None:
    if shutil.which("npm") is None:
        report(False, "npm", "未安装", "随 Node.js 一同安装")
        return
    out = subprocess.run(["npm", "--version"], capture_output=True, text=True, timeout=15)
    report(True, "npm", out.stdout.strip())


def check_uv() -> None:
    if shutil.which("uv") is None:
        report(False, "uv", "未安装", "curl -LsSf https://astral.sh/uv/install.sh | sh")
        return
    out = subprocess.run(["uv", "--version"], capture_output=True, text=True, timeout=15)
    report(True, "uv", out.stdout.strip())


def check_packages() -> None:
    for mod in REQUIRED_PACKAGES:
        if importlib.util.find_spec(mod) is None:
            report(False, f"包 {mod}", "未安装", "uv pip install -e backend（在项目根执行）")
        else:
            report(True, f"包 {mod}", "可导入")


def main() -> int:
    print("Agent 全栈项目环境自检")
    print("=" * 60)
    check_python()
    check_node()
    check_npm()
    check_uv()
    check_packages()
    print("=" * 60)

    if problems:
        print(f"发现 {len(problems)} 个问题：")
        for p in problems:
            print(f"  - {p}")
        return 1
    print("环境就绪，可以 scaffold / run_dev。")
    return 0


if __name__ == "__main__":
    sys.exit(main())
