#!/usr/bin/env bash

set -euo pipefail

readonly main_branch="main"
readonly remote_name="origin"
readonly assets_dir="assets"

active_worktree=""
temp_root=""
published_branches=()
timestamp_dirs=()
batch_mode=false

fail() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

cleanup_worktree() {
  if [[ -n "$active_worktree" ]]; then
    git worktree remove --force "$active_worktree" >/dev/null 2>&1 || true
    active_worktree=""
  fi

  if [[ -n "$temp_root" && -d "$temp_root" ]]; then
    rmdir "$temp_root" >/dev/null 2>&1 || true
    temp_root=""
  fi
}

trap cleanup_worktree EXIT

is_timestamp_name() {
  [[ "$1" =~ ^[0-9]{14}$ ]]
}

contains_assets() {
  find "$1" -type f ! -name '.gitkeep' ! -name '.DS_Store' -print -quit | grep -q .
}

validate_branch_available() {
  local branch_name="$1"
  local remote_branch

  is_timestamp_name "$branch_name" || fail "branch name must use yyyyMMddHHmmss (14 digits): ${branch_name}"

  if git show-ref --verify --quiet "refs/heads/${branch_name}"; then
    fail "local branch already exists: ${branch_name}"
  fi

  if ! remote_branch="$(git ls-remote --heads "$remote_name" "refs/heads/${branch_name}")"; then
    fail "could not query remote '${remote_name}'"
  fi

  [[ -z "$remote_branch" ]] || fail "remote branch already exists: ${branch_name}"
}

publish_snapshot() {
  local source_dir="$1"
  local branch_name="$2"

  temp_root="$(mktemp -d "${TMPDIR:-/tmp}/proxyassistant-assets-publish.XXXXXX")"
  active_worktree="${temp_root}/worktree"

  git worktree add --quiet --detach "$active_worktree" "$main_branch"
  git -C "$active_worktree" switch --quiet --orphan "$branch_name"
  git -C "$active_worktree" rm -rf --ignore-unmatch . >/dev/null
  git -C "$active_worktree" clean -fdx >/dev/null
  mkdir -p "${active_worktree}/${assets_dir}"
  rsync -a --exclude '.DS_Store' --exclude '.gitkeep' "${source_dir}/" "${active_worktree}/${assets_dir}/"

  contains_assets "${active_worktree}/${assets_dir}" || fail "snapshot is empty: ${source_dir}"

  git -C "$active_worktree" add -A "$assets_dir"
  git -C "$active_worktree" commit -m "assets: publish ${branch_name}"

  if [[ "$(git -C "$active_worktree" ls-tree --name-only HEAD)" != "$assets_dir" ]]; then
    fail "published branch root must contain only ${assets_dir}/: ${branch_name}"
  fi

  if ! git -C "$active_worktree" push -u "$remote_name" "$branch_name"; then
    printf 'push failed; branch %s and its commit were kept for retry\n' "$branch_name" >&2
    exit 1
  fi

  git worktree remove --force "$active_worktree"
  active_worktree=""
  rmdir "$temp_root"
  temp_root=""
  published_branches+=("$branch_name")
}

current_branch="$(git branch --show-current)"
[[ "$current_branch" == "$main_branch" ]] || \
  fail "run this script from the ${main_branch} branch (currently ${current_branch:-detached HEAD})"

git remote get-url "$remote_name" >/dev/null 2>&1 || \
  fail "Git remote '${remote_name}' is not configured"

[[ -d "$assets_dir" ]] || fail "missing ${assets_dir}/ directory"

if git ls-tree -r --name-only HEAD -- "$assets_dir" | grep -v -E '^assets/\.gitkeep$' | grep -q .; then
  fail "${main_branch} must not track concrete files under ${assets_dir}/"
fi

while IFS= read -r candidate; do
  directory_name="${candidate##*/}"
  if is_timestamp_name "$directory_name"; then
    timestamp_dirs+=("$candidate")
  fi
done < <(find "$assets_dir" -mindepth 1 -maxdepth 1 -type d -print | LC_ALL=C sort)

if [[ ${#timestamp_dirs[@]} -gt 0 ]]; then
  batch_mode=true
  [[ $# -eq 0 ]] || fail "do not pass a branch name when publishing timestamp directories"

  for snapshot_dir in "${timestamp_dirs[@]}"; do
    branch_name="${snapshot_dir##*/}"
    contains_assets "$snapshot_dir" || fail "timestamp directory is empty: ${snapshot_dir}"
    validate_branch_available "$branch_name"
  done

  for snapshot_dir in "${timestamp_dirs[@]}"; do
    publish_snapshot "$snapshot_dir" "${snapshot_dir##*/}"
  done
else
  [[ $# -le 1 ]] || fail "usage: $0 [yyyyMMddHHmmss]"
  contains_assets "$assets_dir" || fail "${assets_dir}/ does not contain any concrete asset files"
  branch_name="${1:-$(date '+%Y%m%d%H%M%S')}"
  validate_branch_available "$branch_name"
  publish_snapshot "$assets_dir" "$branch_name"
fi

if [[ "$batch_mode" == true ]]; then
  for snapshot_dir in "${timestamp_dirs[@]}"; do
    git clean -fdx -- "$snapshot_dir"
  done

  if ! contains_assets "$assets_dir"; then
    git restore --worktree -- "$assets_dir"
  fi
else
  git clean -fdx -- "$assets_dir"
  git restore --worktree -- "$assets_dir"
fi

printf 'published to %s: %s\n' "$remote_name" "${published_branches[*]}"
printf 'removed published snapshots and preserved all other %s content\n' "$assets_dir"
