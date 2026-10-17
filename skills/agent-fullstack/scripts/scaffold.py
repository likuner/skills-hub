#!/usr/bin/env python3
"""生成 Agent 全栈项目骨架。

用法：
    python scaffold.py <目标路径>

- 目标路径不存在则创建，存在则必须为空目录
- 项目名取路径末段（字母开头，仅限字母/数字/-/_）
- 模板中的 {{PROJECT_NAME}} / {{PROJECT_SLUG}} 占位符会被替换
"""

from __future__ import annotations

import argparse
import re
import shutil
import sys
from pathlib import Path

TEMPLATES_DIR = Path(__file__).resolve().parent.parent / "assets" / "templates"
NAME_RE = re.compile(r"^[A-Za-z][A-Za-z0-9_-]*$")


def slugify(name: str) -> str:
    slug = re.sub(r"[^a-z0-9]+", "-", name.lower()).strip("-")
    return slug or "agent-app"


def render_text(text: str, name: str, slug: str) -> str:
    return text.replace("{{PROJECT_NAME}}", name).replace("{{PROJECT_SLUG}}", slug)


def copy_tree(src: Path, dst: Path, name: str, slug: str) -> list[Path]:
    created: list[Path] = []
    for item in sorted(src.rglob("*")):
        if item.name == ".DS_Store":
            continue
        target = dst / item.relative_to(src)
        if item.is_dir():
            target.mkdir(parents=True, exist_ok=True)
            continue
        target.parent.mkdir(parents=True, exist_ok=True)
        try:
            content = item.read_text(encoding="utf-8")
            target.write_text(render_text(content, name, slug), encoding="utf-8")
        except UnicodeDecodeError:
            shutil.copy2(item, target)
        created.append(target)
    return created


def main() -> int:
    parser = argparse.ArgumentParser(description="生成 Agent 全栈项目骨架")
    parser.add_argument("target", help="目标项目路径（须为空或不存在）")
    args = parser.parse_args()

    target = Path(args.target).expanduser().resolve()
    name = target.name
    if not NAME_RE.match(name):
        print(f"项目名不合法：{name!r}（须字母开头，仅含字母/数字/-/_）", file=sys.stderr)
        return 2

    if target.exists() and any(target.iterdir()):
        print(f"目标目录非空：{target}", file=sys.stderr)
        return 2

    if not TEMPLATES_DIR.is_dir():
        print(f"模板目录缺失：{TEMPLATES_DIR}", file=sys.stderr)
        return 2

    target.mkdir(parents=True, exist_ok=True)
    slug = slugify(name)

    created: list[Path] = []
    # root/ 内容放项目根；backend/、frontend/ 内容放对应子目录
    for sub, dest in (("root", target), ("backend", target / "backend"), ("frontend", target / "frontend")):
        src = TEMPLATES_DIR / sub
        if src.is_dir():
            created += copy_tree(src, dest, name, slug)

    dev_sh = target / "dev.sh"
    if dev_sh.exists():
        dev_sh.chmod(0o755)

    print(f"已生成项目 {name} → {target}（{len(created)} 个文件）")
    print()
    print("后续步骤：")
    print(f"  cd {target}")
    print("  uv venv --python 3.12 && uv pip install -e backend")
    print("  cp backend/.env.example .env   # 填入 OPENAI_API_KEY")
    print("  (cd frontend && npm install)")
    print("  bash dev.sh                   # 后端 :8000，前端 :5173")
    return 0


if __name__ == "__main__":
    sys.exit(main())
