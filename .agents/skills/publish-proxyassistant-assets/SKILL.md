---
name: publish-proxyassistant-assets
description: Publish a complete ProxyAssistant image snapshot from this repository's assets directory to a new immutable yyyyMMddHHmmss Git branch. Use when assets have been copied here for release or when checking the repository's asset-release workflow.
---

# Publish ProxyAssistant assets

This repository stores the assets consumed by
`/Users/bugwz/Project/Dabble/ProxyAssistant/public/img`.

## Invariants

- Keep `main` free of concrete resources; it contains the reusable repository
  files and the empty `assets/` staging directory only.
- Treat each 14-digit `yyyyMMddHHmmss` branch as an immutable, complete asset
  snapshot. Never update, force-push, or reuse a published snapshot branch.
- Preserve the directory layout supplied inside `assets/`; consumers depend on
  stable paths.
- Publish to the existing `origin` remote. Do not change its URL as part of a
  release.

## Release workflow

When the user asks to release the resources already copied into `assets/`:

1. Inspect `git status`, confirm the current branch is `main`, and confirm all
   pending paths are under `assets/`. Do not discard or include unrelated work.
2. Review the asset tree and confirm it contains at least one file other than
   `.gitkeep`. Treat the directory as a complete snapshot, not a patch over an
   older timestamp branch.
3. Run `./scripts/publish-assets.sh`. Pass an explicit branch name only when the
   user supplied one; otherwise let the script generate the current local time.
4. Verify that the push succeeded, that `main` is checked out again, and that
   `git status --short --branch` is clean.
5. Report the published branch name and remote. If the push fails, leave the
   timestamp branch intact so the same commit can be retried; do not create a
   second snapshot or rewrite history.

The script intentionally returns to `main` only after a successful push. This
removes the released concrete assets from the main-branch working tree while
retaining them in the timestamp branch.
