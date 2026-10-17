#!/usr/bin/env bash
# skills-hub 卸载脚本：移除 install.sh 分发到各平台技能目录的全部符号链接。
# 只删指向本仓库 skills/ 的链接（含已失效的），不碰其他来源的 skill 和真实目录，也不删仓库本体。
# 幂等，可重复运行。
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DIR="$REPO_ROOT/skills"

# 目标目录清单须与 install.sh 保持一致
AGENTS_SKILLS_DIR="$HOME/.agents/skills"
PLATFORM_SKILLS_DIRS=(
  "$HOME/.claude/skills"
  "$HOME/.codex/skills"
  "$HOME/.cursor/skills"
  "$HOME/.gemini/skills"
)

removed=0

collect_targets() { # 输出当前实际存在的目标目录
  local d
  [ -d "$AGENTS_SKILLS_DIR" ] && printf '%s\n' "$AGENTS_SKILLS_DIR"
  for d in "${PLATFORM_SKILLS_DIRS[@]}"; do
    [ -d "$d" ] && printf '%s\n' "$d"
  done
}

remove_links() { # 删除目标目录中所有指向本仓库 skills/ 的符号链接
  local target_dir="$1" link src
  for link in "$target_dir"/*; do
    [ -L "$link" ] || continue # 真实目录/文件不属于本仓库（install 阶段就未接管），不动
    src="$(readlink "$link")"
    case "$src" in
      "$SKILLS_DIR"/*)
        rm "$link"
        echo "  已移除 ${link}（原指向 ${src}）"
        removed=$((removed + 1))
        ;;
    esac
  done
}

rmdir_if_empty() { # 清掉 install.sh mkdir -p 出来、现已无内容的目录
  [ -d "$1" ] || return 0
  if [ -z "$(ls -A "$1" 2>/dev/null)" ]; then
    rmdir "$1"
    echo "  已删除空目录 $1"
  fi
}

shopt -s nullglob

echo "卸载 skills-hub 分发链接（仓库本体 $REPO_ROOT 不受影响）："
while IFS= read -r target_dir; do
  remove_links "$target_dir"
  rmdir_if_empty "$target_dir"
done < <(collect_targets)

# ~/.agents 是 install.sh 无条件创建的，为空则一并回收；平台根目录（~/.claude 等）留给平台自身
rmdir_if_empty "$HOME/.agents"

if [ "$removed" -eq 0 ]; then
  echo "完成：未发现指向本仓库的链接，无需卸载。"
else
  echo "完成：共移除 $removed 个链接。"
fi
echo "如需彻底移除，请手动执行：rm -rf $REPO_ROOT"
