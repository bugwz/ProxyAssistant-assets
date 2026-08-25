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

如需一次发布多个快照，在 `assets/` 下分别创建以 `yyyyMMddHHmmss` 命名的目录，然后直接运行脚本。每个时间目录会发布到同名独立分支，目录中的内容会成为该分支的 `assets/` 内容；分支根目录不会包含 `main` 的其他文件，`assets/` 下的非时间文件和目录也不会发布或清理。

如果推送失败，脚本会保留已经创建的本地时间分支及其提交，方便使用同一提交重试，不会自动生成第二份快照。

## 开源协议

[MIT](LICENSE)
