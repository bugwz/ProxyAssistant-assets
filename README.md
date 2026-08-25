# ProxyAssistant 资源仓库

本仓库用于保存 [bugwz/ProxyAssistant](https://github.com/bugwz/ProxyAssistant) 项目使用的版本化资源文件。

## 分支约定

- `main` 分支不保存具体资源，只保留仓库配置、发布脚本以及空的 `assets/` 暂存目录。
- 每次发布都创建一个不可变的完整资源快照分支。
- 快照分支使用本地时间命名，格式为 `yyyyMMddHHmmss`，例如 `20260203143345`。
- 已发布的时间分支不得复用、修改或强制推送。

## 发布资源

将下一版完整资源复制到 `assets/`，并保持原有目录结构，然后运行：

```bash
./scripts/publish-assets.sh
```

脚本会检查工作区、创建并提交时间分支、将分支推送到 `origin`，最后切回不包含具体资源的 `main` 分支。

如需使用指定的时间分支名，可以显式传入：

```bash
./scripts/publish-assets.sh 20260203143345
```

如果推送失败，脚本会保留已经创建的本地时间分支及其提交，方便使用同一提交重试，不会自动生成第二份快照。

## AI 代理规范

本仓库同时兼容 Codex 和 Claude Code：

- `AGENTS.md` 是两者共用的项目规范。
- `CLAUDE.md` 导入 `AGENTS.md`，供 Claude Code 自动加载。
- `.agents/skills/publish/SKILL.md` 和 `.agents/skills/commit/SKILL.md` 是发布、提交技能的唯一源文件。
- `.claude/skills/publish` 和 `.claude/skills/commit` 指向同一组技能，供 Claude Code 自动发现，避免维护重复规则。

需要发布资源时，也可以直接要求 Codex 或 Claude Code 发布 `assets/` 中的完整资源快照。

## 开源协议

[MIT](LICENSE)
