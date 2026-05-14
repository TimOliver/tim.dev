#!/usr/bin/env bash
#
# Installs tim.dev's git hooks by symlinking each file in Scripts/hooks/ into
# .git/hooks/. Re-runs are idempotent — existing symlinks pointing to the same
# target are left alone; existing real files are refused unless --force is set.
#
# Hooks aren't tracked under .git/hooks/ (git doesn't version that directory),
# so this needs to run once per fresh clone.
#
set -euo pipefail

cd "$(dirname "$0")/.."  # repo root

if [[ ! -d ".git" ]]; then
    echo "error: not in a git repo root (no .git/ here)" >&2
    exit 1
fi

force=0
if [[ "${1:-}" == "--force" ]]; then
    force=1
fi

mkdir -p .git/hooks

installed=()
for src in Scripts/hooks/*; do
    name=$(basename "$src")
    dest=".git/hooks/$name"
    target="../../Scripts/hooks/$name"

    if [[ -L "$dest" ]] && [[ "$(readlink "$dest")" == "$target" ]]; then
        continue  # already correctly installed
    fi
    if [[ -e "$dest" && $force -eq 0 ]]; then
        echo "skip: $dest already exists (pass --force to replace)" >&2
        continue
    fi
    ln -sf "$target" "$dest"
    chmod +x "$src"
    installed+=("$name")
done

if [[ ${#installed[@]} -eq 0 ]]; then
    echo "hooks already installed."
else
    echo "installed: ${installed[*]}"
fi
