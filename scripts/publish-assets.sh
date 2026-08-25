#!/usr/bin/env bash

set -euo pipefail

readonly main_branch="main"
readonly remote_name="origin"
readonly assets_dir="assets"
readonly placeholder="assets/.gitkeep"

fail() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

current_branch="$(git branch --show-current)"
[[ "$current_branch" == "$main_branch" ]] || \
  fail "run this script from the ${main_branch} branch (currently ${current_branch:-detached HEAD})"

git remote get-url "$remote_name" >/dev/null 2>&1 || \
  fail "Git remote '${remote_name}' is not configured"

[[ -d "$assets_dir" ]] || fail "missing ${assets_dir}/ directory"

if ! find "$assets_dir" -type f ! -path "$placeholder" -print -quit | grep -q .; then
  fail "${assets_dir}/ does not contain any concrete asset files"
fi

while IFS= read -r status_line; do
  path="${status_line:3}"
  [[ "$path" == "$assets_dir"/* ]] || \
    fail "pending path outside ${assets_dir}/: ${path}"
done < <(git status --porcelain --untracked-files=all)

branch_name="${1:-$(date '+%Y%m%d%H%M%S')}"
[[ "$branch_name" =~ ^[0-9]{14}$ ]] || \
  fail "branch name must use yyyyMMddHHmmss (14 digits)"

if git show-ref --verify --quiet "refs/heads/${branch_name}"; then
  fail "local branch already exists: ${branch_name}"
fi

if ! remote_branch="$(git ls-remote --heads "$remote_name" "$branch_name")"; then
  fail "could not query remote '${remote_name}'"
fi

if [[ -n "$remote_branch" ]]; then
  fail "remote branch already exists: ${branch_name}"
fi

git switch -c "$branch_name"
git add -A "$assets_dir"
git commit -m "assets: publish ${branch_name}"

if ! git push -u "$remote_name" "$branch_name"; then
  printf 'push failed; branch %s and its commit were kept for retry\n' "$branch_name" >&2
  exit 1
fi

git switch "$main_branch"
printf 'published %s/%s and returned to %s\n' "$remote_name" "$branch_name" "$main_branch"
