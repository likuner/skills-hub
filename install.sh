#!/usr/bin/env bash
# skills-hub 安装脚本：把仓库 skills/ 下的自研 skill 以符号链接分发到各平台技能目录。
# 幂等，可重复运行；新机器上 git clone 后执行 ./install.sh 即完成接入。
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DIR="$REPO_ROOT/skills"

# 行业统一标准位（ZCode / Claude Code / Codex / Cursor / Copilot 等新版均读取）
AGENTS_SKILLS_DIR="$HOME/.agents/skills"

# 平台专属目录：仅当平台已安装（其配置目录存在）时才补链，兼容只读自身目录的旧版
PLATFORM_SKILLS_DIRS=(
  "$HOME/.claude/skills"
  "$HOME/.codex/skills"
  "$HOME/.cursor/skills"
  "$HOME/.gemini/skills"
)

created=0
skipped=0

link_skill() { # $1=skill 源目录（绝对路径） $2=目标目录
  local src="$1" target_dir="$2" name link
  name="$(basename "$src")"
  link="$target_dir/$name"
  if [ -L "$link" ] && [ "$(readlink "$link")" = "$src" ]; then
    return 0
  fi
  if [ -L "$link" ]; then
    rm "$link" # 指向别处或已失效的链接，安全替换
  elif [ -e "$link" ]; then
    echo "  跳过 ${link}：已存在非符号链接内容，请手动处理" >&2
    skipped=$((skipped + 1))
    return 0
  fi
  ln -s "$src" "$link"
  echo "  链接 $link -> $src"
  created=$((created + 1))
}

prune_dead() { # 清理目标目录中指向本仓库但已失效的链接（对应 skill 已被删除/改名）
  local target_dir="$1" link src
  [ -d "$target_dir" ] || return 0
  for link in "$target_dir"/*; do
    [ -L "$link" ] || continue
    src="$(readlink "$link")"
    case "$src" in
      "$SKILLS_DIR"/*)
        [ -e "$link" ] || { rm "$link"; echo "  清理失效链接 ${link}（原指向 ${src}）"; }
        ;;
    esac
  done
}

[ -d "$SKILLS_DIR" ] || { echo "错误：未找到 $SKILLS_DIR" >&2; exit 1; }
shopt -s nullglob
skill_dirs=("$SKILLS_DIR"/*/)
[ ${#skill_dirs[@]} -gt 0 ] || { echo "错误：skills/ 下没有任何 skill" >&2; exit 1; }

targets=("$AGENTS_SKILLS_DIR")
mkdir -p "$AGENTS_SKILLS_DIR"
for d in "${PLATFORM_SKILLS_DIRS[@]}"; do
  if [ -d "${d%/*}" ]; then
    mkdir -p "$d"
    targets+=("$d")
  fi
done

echo "分发 ${#skill_dirs[@]} 个 skill 到 ${#targets[@]} 个目录："
for src in "${skill_dirs[@]}"; do
  for t in "${targets[@]}"; do
    link_skill "${src%/}" "$t"
  done
done
for t in "${targets[@]}"; do
  prune_dead "$t"
done

echo "完成：新建 $created 个链接，跳过 $skipped 个。分发位置："
printf '  - %s\n' "${targets[@]}"
