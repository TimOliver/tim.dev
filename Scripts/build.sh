#!/usr/bin/env bash
# Build and validate the deployable static site. Never deploy a failed build.
set -euo pipefail
repo_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repo_root"
# The project virtualenv from Scripts/setup.sh, if there is one (it has
# Pillow); otherwise whatever python3 is on the PATH (as on CI).
python=python3
[[ -x .venv/bin/python ]] && python=.venv/bin/python
"$python" Scripts/youtube-posters.py   # fetches only posters not yet saved
"$python" Scripts/build-media.py
swift run --disable-automatic-resolution
"$python" Scripts/check-site.py
