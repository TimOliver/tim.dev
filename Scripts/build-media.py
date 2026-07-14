#!/usr/bin/env python3
"""
Generates responsive variants + LQIP blur placeholders for collection media
and writes media-manifest.json at the repo root.

Sources are the images you drop into Assets/img/{apps,code,art,talks}/.
For each source this emits <stem>@<width>w<ext> variants beside it, computes a
~20px-wide base64 blur placeholder, and records the intrinsic dimensions (so
cards reserve space and never shift as images load).

The manifest is a BUILD INPUT, not site output — it lives at the repo root
rather than under Assets/, because everything under Assets/ is copied verbatim
into Build/ and shipped.

Idempotent: re-runs skip variants that are newer than their source, and
generated variants are never themselves treated as sources.

Run after adding collection images:  python3 Scripts/build-media.py
"""

from __future__ import annotations

import base64
import io
import json
import re
import sys
from pathlib import Path

from PIL import Image

REPO_ROOT = Path(__file__).resolve().parent.parent
ASSETS = REPO_ROOT / "Assets"
COLLECTIONS = ("apps", "code", "art", "talks")
MANIFEST = REPO_ROOT / "media-manifest.json"

VARIANT_WIDTHS = (400, 800, 1200, 1600)
LQIP_WIDTH = 20
SOURCE_SUFFIXES = {".png", ".jpg", ".jpeg"}

# Matches only this script's own <stem>@<width>w<ext> suffix — NOT any "@" in
# the stem. A looser "@" in path.stem check (the old behaviour) also matches
# a hand-authored icon@2x.png, silently treating it as a generated variant
# and skipping it forever. validate_source() below turns that collision into
# a loud failure instead.
_VARIANT_RE = re.compile(r"@\d+w$")


def is_variant(path: Path) -> bool:
    """True for files this script generated (<stem>@<width>w<ext>)."""
    return bool(_VARIANT_RE.search(path.stem))


def validate_source(path: Path) -> None:
    """Hard-fail on filenames that would silently corrupt the srcset or
    collide with the variant naming convention.

    srcset is a comma-and-whitespace-delimited list of "<url> <width>w"
    candidates. A space or comma in the filename splits mid-URL, so the
    browser can't parse ANY candidate and falls back to `src` — the 20px
    LQIP blur — with no build error and no JS error. The likeliest real input
    is something like "Simulator Screen Shot - iPhone 15 Pro.png".

    "@" is reserved for this script's own <stem>@<width>w suffix (see
    is_variant above); a hand-authored file using "@" for anything else
    (e.g. the @2x retina convention) would otherwise be silently skipped as
    if it were a generated variant.
    """
    name = path.name
    if " " in name or "," in name or "@" in name:
        print(
            f"error: {path.relative_to(REPO_ROOT)} has a space, comma, or '@' "
            "in its filename. Rename it (spaces/commas break srcset parsing; "
            "'@' is reserved for this script's own <stem>@<width>w variants) "
            "and re-run Scripts/build-media.py.",
            file=sys.stderr,
        )
        sys.exit(1)


def site_path(path: Path) -> str:
    """Assets/img/apps/x/icon.png -> /img/apps/x/icon.png"""
    return "/" + path.relative_to(ASSETS).as_posix()


def lqip_data_uri(im: Image.Image) -> str:
    """A ~20px-wide PNG of the image, inlined as a base64 data URI."""
    height = max(1, round(im.height * LQIP_WIDTH / im.width))
    tiny = im.resize((LQIP_WIDTH, height), Image.LANCZOS)
    buf = io.BytesIO()
    tiny.save(buf, format="PNG", optimize=True)
    return "data:image/png;base64," + base64.b64encode(buf.getvalue()).decode("ascii")


def build_variants(
    src: Path, im: Image.Image, expected: set[Path]
) -> list[tuple[int, str]]:
    """Emit downscaled variants; never upscale. Returns [(width, site_path)].

    Every variant path this source currently needs is added to `expected` —
    reused by prune_orphaned_variants() to delete generated files that no
    source asks for anymore (a replaced or renamed source otherwise leaves
    its old variants behind as dead bytes that still ship into Build/).
    """
    # Screenshots with baked-in device chrome are transparent PNGs — keep PNG.
    # Re-containering them as JPEG would fill the bezel's transparency black.
    is_png = src.suffix.lower() == ".png"
    out: list[tuple[int, str]] = []

    for width in VARIANT_WIDTHS:
        if width >= im.width:
            continue  # never upscale; the source itself covers this width
        dst = src.with_name(f"{src.stem}@{width}w{src.suffix}")
        expected.add(dst)
        if not dst.exists() or dst.stat().st_mtime < src.stat().st_mtime:
            height = max(1, round(im.height * width / im.width))
            resized = im.resize((width, height), Image.LANCZOS)
            if is_png:
                resized.save(dst, format="PNG", optimize=True)
            else:
                resized.convert("RGB").save(
                    dst, format="JPEG", quality=80, progressive=True, optimize=True
                )
        out.append((width, site_path(dst)))

    # The source is always the largest candidate.
    out.append((im.width, site_path(src)))
    return out


def prune_orphaned_variants(expected: set[Path]) -> None:
    """Delete generated variants no current source+width still asks for.

    This script rewrites the manifest from scratch every run but, without
    this pass, never touched the variant files themselves — replace a
    2400px source with an 800px one, or rename it, and its old
    <stem>@1600w<ext> stays on disk, gets copied into Build/, and deploys as
    dead bytes nothing references.
    """
    for collection in COLLECTIONS:
        root = ASSETS / "img" / collection
        if not root.is_dir():
            continue
        for path in sorted(root.rglob("*")):
            if path.is_file() and is_variant(path) and path not in expected:
                path.unlink()
                print(f"pruned orphaned variant: {path.relative_to(ASSETS)}")


def main() -> None:
    manifest: dict[str, dict] = {}
    expected_variants: set[Path] = set()

    for collection in COLLECTIONS:
        root = ASSETS / "img" / collection
        if not root.is_dir():
            continue
        for src in sorted(root.rglob("*")):
            if not src.is_file():
                continue
            if src.suffix.lower() not in SOURCE_SUFFIXES or is_variant(src):
                continue
            validate_source(src)
            with Image.open(src) as im:
                im.load()
                variants = build_variants(src, im, expected_variants)
                manifest[site_path(src)] = {
                    "width": im.width,
                    "height": im.height,
                    "lqip": lqip_data_uri(im),
                    "srcset": ", ".join(f"{p} {w}w" for w, p in variants),
                }

    prune_orphaned_variants(expected_variants)

    MANIFEST.write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n")
    print(f"media-manifest.json: {len(manifest)} image(s)")


if __name__ == "__main__":
    main()
