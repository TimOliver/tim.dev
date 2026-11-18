#!/usr/bin/env bash
#
# Undoes Scripts/setup.sh and everything a build generates, putting the clone
# back to how it was checked out: the .venv, the Swift build, Build/, the
# generated Includes/_* pages, the image variants and their cache,
# Python caches and the git hooks setup.sh installed.
#
#     bash Scripts/clean.sh            # remove them
#     bash Scripts/clean.sh --dry-run  # just list what would go
#
# Only ever removes those generated paths: never tracked files, your own
# uncommitted work, or other ignored files (local notes, editor settings).
# Run Scripts/setup.sh and Scripts/build.sh to get it all back.
#
set -euo pipefail
cd "$(dirname "$0")/.."  # repo root

dry_run=0
if [[ "${1:-}" == "--dry-run" ]]; then
    dry_run=1
elif [[ $# -gt 0 ]]; then
    echo "usage: bash Scripts/clean.sh [--dry-run]" >&2
    exit 2
fi

removed=0
remove() {
    local path=$1
    [[ -e "$path" || -L "$path" ]] || return 0
    # Never delete anything git tracks, whatever the list below says.
    if [[ -n "$(git ls-files -- "$path" | head -1)" ]]; then
        echo "skip (tracked): $path" >&2
        return 0
    fi
    removed=$((removed + 1))
    if [[ $dry_run -eq 1 ]]; then
        echo "would remove: $path"
    else
        rm -rf -- "$path"
    fi
}

# setup.sh
remove .venv

# Swift build and the generated site.
remove .build
remove .swiftpm
remove Build
for dir in Includes/_posts Includes/_apps Includes/_code Includes/_art Includes/_talks; do
    remove "$dir"
done

# build-media.py output: <stem>@<width>w variants next to their originals
# (only files git ignores, so a tracked image with an @ in its name is safe),
# plus its cache. media-manifest.json stays: it's committed.
variants=0
while IFS= read -r -d '' path; do
    if git check-ignore -q -- "$path"; then
        variants=$((variants + 1))
        if [[ $dry_run -eq 0 ]]; then
            rm -f -- "$path"
        fi
    fi
done < <(find Assets/img -type f -name '*@[0-9]*w.*' -print0)
if [[ $variants -gt 0 ]]; then
    removed=$((removed + variants))
    if [[ $dry_run -eq 1 ]]; then
        echo "would remove: $variants image variants under Assets/img"
    fi
fi
remove .media-cache.json

# Python bytecode caches.
while IFS= read -r -d '' dir; do
    remove "$dir"
done < <(find Scripts -type d -name __pycache__ -print0)

# Git hooks, but only the symlinks install-hooks.sh made.
for src in Scripts/hooks/*; do
    dest=".git/hooks/$(basename "$src")"
    if [[ -L "$dest" && "$(readlink "$dest")" == "../../Scripts/hooks/$(basename "$src")" ]]; then
        removed=$((removed + 1))
        if [[ $dry_run -eq 1 ]]; then
            echo "would remove: $dest (git hook)"
        else
            rm -f -- "$dest"
        fi
    fi
done

if [[ $removed -eq 0 ]]; then
    echo "Already clean."
elif [[ $dry_run -eq 1 ]]; then
    echo "Dry run: nothing removed."
else
    echo "Cleaned. Run 'bash Scripts/setup.sh' and 'bash Scripts/build.sh' to set it all up again."
fi
