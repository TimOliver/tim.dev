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
from pathlib import Path

from PIL import Image

REPO_ROOT = Path(__file__).resolve().parent.parent
ASSETS = REPO_ROOT / "Assets"
COLLECTIONS = ("apps", "code", "art", "talks")
MANIFEST = REPO_ROOT / "media-manifest.json"

VARIANT_WIDTHS = (400, 800, 1200, 1600)
LQIP_WIDTH = 20
SOURCE_SUFFIXES = {".png", ".jpg", ".jpeg"}


def is_variant(path: Path) -> bool:
    """True for files this script generated (<stem>@<width>w<ext>)."""
    return "@" in path.stem


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


def build_variants(src: Path, im: Image.Image) -> list[tuple[int, str]]:
    """Emit downscaled variants; never upscale. Returns [(width, site_path)]."""
    # Screenshots with baked-in device chrome are transparent PNGs — keep PNG.
    # Re-containering them as JPEG would fill the bezel's transparency black.
    is_png = src.suffix.lower() == ".png"
    out: list[tuple[int, str]] = []

    for width in VARIANT_WIDTHS:
        if width >= im.width:
            continue  # never upscale; the source itself covers this width
        dst = src.with_name(f"{src.stem}@{width}w{src.suffix}")
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


def main() -> None:
    manifest: dict[str, dict] = {}

    for collection in COLLECTIONS:
        root = ASSETS / "img" / collection
        if not root.is_dir():
            continue
        for src in sorted(root.rglob("*")):
            if not src.is_file():
                continue
            if src.suffix.lower() not in SOURCE_SUFFIXES or is_variant(src):
                continue
            with Image.open(src) as im:
                im.load()
                variants = build_variants(src, im)
                manifest[site_path(src)] = {
                    "width": im.width,
                    "height": im.height,
                    "lqip": lqip_data_uri(im),
                    "srcset": ", ".join(f"{p} {w}w" for w, p in variants),
                }

    MANIFEST.write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n")
    print(f"media-manifest.json: {len(manifest)} image(s)")


if __name__ == "__main__":
    main()
