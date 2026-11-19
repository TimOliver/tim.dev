#!/usr/bin/env bash
#
# One-time setup for a fresh clone: a project virtualenv (.venv) with the
# Python packages in requirements.txt, plus the git hooks. Safe to re-run;
# it only installs what's missing.
#
#     bash Scripts/setup.sh
#
# Scripts/build.sh and the pre-commit hook use .venv automatically. To run a
# Python script by hand, activate it first: source .venv/bin/activate
#
set -euo pipefail
cd "$(dirname "$0")/.."  # repo root

# Pillow 13 needs Python 3.11+. The first `python3` on PATH can be older (a
# pyenv global, or macOS's own 3.9), so take the newest suitable one found.
new_enough() { "$1" -c 'import sys; sys.exit(0 if sys.version_info >= (3, 11) else 1)' 2>/dev/null; }
python=""
for candidate in python3.14 python3.13 python3.12 python3.11 python3; do
    if command -v "$candidate" >/dev/null && new_enough "$candidate"; then
        python=$candidate
        break
    fi
done
if [[ -z $python ]]; then
    echo "error: Python 3.11 or newer is required (found $(python3 --version 2>&1))." >&2
    exit 1
fi

# A .venv made by an older Python can't install the pinned packages: rebuild it.
if [[ -x .venv/bin/python ]] && ! new_enough .venv/bin/python; then
    echo "Rebuilding .venv (it was made with $(.venv/bin/python --version 2>&1))..."
    rm -rf .venv
fi

if [[ ! -x .venv/bin/python ]]; then
    echo "Creating .venv with $($python --version 2>&1)..."
    "$python" -m venv .venv
fi

echo "Installing Python packages..."
.venv/bin/python -m pip install --quiet --upgrade pip
.venv/bin/python -m pip install --quiet -r requirements.txt

bash Scripts/install-hooks.sh

echo
echo "Done. Build the site with: bash Scripts/build.sh"
