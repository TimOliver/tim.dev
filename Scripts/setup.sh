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

python3 - <<'PY' || { echo "error: Python 3.10 or newer is required (found $(python3 --version 2>&1))." >&2; exit 1; }
import sys
sys.exit(0 if sys.version_info >= (3, 10) else 1)
PY

if [[ ! -x .venv/bin/python ]]; then
    echo "Creating .venv..."
    python3 -m venv .venv
fi

echo "Installing Python packages..."
.venv/bin/python -m pip install --quiet --upgrade pip
.venv/bin/python -m pip install --quiet -r requirements.txt

bash Scripts/install-hooks.sh

echo
echo "Done. Build the site with: bash Scripts/build.sh"
