# ProxyAssistant Assets

`ProxyAssistant-assets` stores versioned image assets for
`/Users/bugwz/Project/Dabble/ProxyAssistant/public/img`.

The `main` branch intentionally contains no concrete assets. Put the next
complete asset snapshot in `assets/`, then publish it as an immutable branch
whose name uses the local timestamp format `yyyyMMddHHmmss`, for example
`20260203143345`.

```bash
./scripts/publish-assets.sh
```

The script validates the workspace, creates and commits the timestamp branch,
pushes it to `origin`, and switches back to the empty `main` branch. A timestamp
can also be supplied explicitly:

```bash
./scripts/publish-assets.sh 20260203143345
```

The publishing workflow is documented for Codex in
`.agents/skills/publish-proxyassistant-assets/SKILL.md`.

## License

MIT
