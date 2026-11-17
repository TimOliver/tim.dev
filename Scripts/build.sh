#!/usr/bin/env bash
# Build and validate the deployable static site. Never deploy a failed build.
set -euo pipefail
repo_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repo_root"
python3 Scripts/youtube-posters.py   # fetches only posters not yet saved
python3 Scripts/build-media.py
swift run --disable-automatic-resolution
python3 Scripts/check-site.py
