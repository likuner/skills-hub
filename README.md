# skills-hub

自研 Agent Skills 的源头仓库。所有自己开发的 skill 在这里编写、迭代、做版本管理，通过符号链接分发到各平台的技能目录，被 ZCode、Claude Code、Codex、Cursor、Copilot 等所有支持 Agent Skills 标准的平台识别。

## 目录结构

```text
skills-hub/
├── README.md          # 本文件
├── install.sh         # 分发脚本：把 skills/ 链接到各平台目录（幂等，可重复运行）
├── template/          # 新 skill 模板
└── skills/            # 自研 skill 源头（唯一需要编辑的地方）
    ├── agent-fullstack/
    │   ├── SKILL.md           # 必需：frontmatter（name + description）+ 正文
    │   ├── references/        # 可选：按需加载的领域细节文档
    │   ├── scripts/           # 可选：辅助脚本
    │   └── assets/            # 可选：模板、素材等
    └── agentscope-skill/
```

## 跨平台识别原理

`~/.agents/skills/` 是行业统一的标准技能目录（ZCode、Claude Code、Codex、Cursor、VS Code Copilot 等新版都从此处发现用户级 skill）。本仓库不改动任何平台配置，只用符号链接：

```text
~/Documents/skills-hub/skills/<name>/   ← 唯一源头（在这里编辑）
        │
        ├──> ~/.agents/skills/<name>     # 标准位：新版平台全部识别
        ├──> ~/.claude/skills/<name>     # 平台专属位：仅当该平台已安装时补链，
        └──> ~/.codex/skills/<name>      # 兼容只读自身目录的旧版本
```

改仓库里的文件，所有平台立刻读到新内容（符号链接实时生效，无需重新运行脚本）。

## 新增一个 skill

1. 从模板起步：

   ```bash
   cd ~/Documents/skills-hub
   cp -r template skills/<skill-name>
   # 编辑 skills/<skill-name>/SKILL.md：
   #   - frontmatter 的 name 必须与目录名一致
   #   - description 写清"做什么 + 什么时机触发"，是唯一的触发信号，宁可主动
   ```

2. 执行 `bash install.sh` 完成分发。

3. 重启对应平台（或开新会话），技能列表里应出现新 skill。可以按 `/skill-name` 强制加载验证。

> 撰写与迭代建议借助 skill-creator 技能：先写草稿，用 2–3 个真实口吻的测试提示词试触发，看输出再改，循环到满意为止。

## 新机器上安装

```bash
git clone <本仓库地址> ~/Documents/skills-hub
cd ~/Documents/skills-hub && bash install.sh
```

## 修改 / 删除 skill

- **修改**：直接编辑 `skills/<name>/` 下的文件，提交 git 即可，所有平台即时生效。
- **删除**：`git rm -r skills/<name>` 并提交，再跑一次 `bash install.sh`（会清理指向该 skill 的失效链接）。

## 约定

- 只有自研 skill 进这个仓库；外部安装的 skill（如 dingtalk 系列）留在原位，不纳入管理。
- SKILL.md 正文控制在 500 行以内，细节拆到 `references/`，利用渐进加载控制上下文成本。
- 每次有意义的改动都提交 git，写清改了什么——这就是 skill 的变更历史。
