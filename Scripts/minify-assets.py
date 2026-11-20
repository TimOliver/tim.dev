#!/usr/bin/env python3
"""
Minifies the site's own CSS and JS in Build/, after Ignite has written it.

The sources under Assets/ stay readable and commented; only the deployed copies
are squeezed. site.css alone goes from ~18 KB to ~6 KB compressed, and it's the
stylesheet that blocks the first paint on every page.

Both the plain files and their content-hashed copies (site.css and
site.3f2a9c1e.css) are minified in place. The hash was taken from the readable
source, which is fine: it only has to change when the content does, and
minifying the same source always gives the same output.

Vendored third-party files are left exactly as downloaded (see VENDORED), so a
version bump stays a straight re-download and they're never touched by hand.

Run by Scripts/build.sh after `swift run`:  python3 Scripts/minify-assets.py
"""

from __future__ import annotations

import sys
from pathlib import Path

import rcssmin
import rjsmin

REPO = Path(__file__).resolve().parent.parent
BUILD = REPO / "Build"

# Name prefixes of vendored files: lightbox3 (bespoke build, kept verbatim),
# Embla (already minified) and lite-youtube-embed.
VENDORED = ("lightbox3", "embla-carousel", "lite-yt-embed")

MINIFIERS = {
    ".css": lambda text: rcssmin.cssmin(text),
    ".js": lambda text: rjsmin.jsmin(text),
}


def is_vendored(path: Path) -> bool:
    return path.name.startswith(VENDORED)


def minify_file(path: Path) -> tuple[int, int]:
    """Minifies one file in place; returns its size before and after."""
    text = path.read_text(encoding="utf-8")
    out = MINIFIERS[path.suffix](text)
    if not out.endswith("\n"):
        out += "\n"
    path.write_text(out, encoding="utf-8")
    return len(text.encode()), len(out.encode())


def main(build: Path = BUILD) -> int:
    before = after = count = 0
    for folder, suffix in (("css", ".css"), ("js", ".js")):
        for path in sorted((build / folder).glob(f"*{suffix}")):
            if is_vendored(path):
                continue
            b, a = minify_file(path)
            before, after, count = before + b, after + a, count + 1
    if count == 0:
        print(f"error: no CSS or JS found under {build}", file=sys.stderr)
        return 1
    print(f"Minified {count} CSS/JS files: {before:,} -> {after:,} bytes")
    return 0


if __name__ == "__main__":
    sys.exit(main())
