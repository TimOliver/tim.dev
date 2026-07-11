#!/usr/bin/env python3
"""
Strip ALL EXIF / metadata from images under Assets/img/posts/.

- JPEG: re-saved with quality='keep' (preserves original quantization tables,
  no perceptible quality loss) and no exif bytes.
- PNG:  re-saved with no text/iTXt/zTXt chunks.
- GIF:  not touched (no standard privacy metadata).

Why we strip everything rather than just GPS: Pillow can't selectively edit
EXIF, and adding piexif as a dep for one tag isn't worth it. Make/Model and
capture timestamps are minor info but harmless to drop. Orientation tags are
also dropped — historical web JPEGs from a 2008–2021 blog have already been
pre-rotated by browsers/editors of the era, so this isn't a practical issue.

Idempotent: re-running on already-stripped images is a no-op (no EXIF found).

Usage:
    python3 Scripts/strip-exif.py             # walks Assets/img/posts/
    python3 Scripts/strip-exif.py <path>...   # processes specific files
                                              # (used by the pre-commit hook)
"""

from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image

REPO_ROOT = Path(__file__).resolve().parent.parent
TARGET = REPO_ROOT / "Assets/img/posts"


def has_metadata(img: Image.Image) -> bool:
    if "exif" in img.info:
        return True
    if hasattr(img, "_getexif") and img._getexif():
        return True
    # PNG text/iTXt/zTXt chunks — Pillow collects them all in .text, including
    # XMP (XML:com.adobe.xmp), which commonly carries GPS. The old
    # parameters/comment check missed those entirely.
    if img.format == "PNG" and getattr(img, "text", None):
        return True
    return False


def strip(path: Path) -> bool:
    """Returns True if the file was rewritten."""
    suffix = path.suffix.lower()
    if suffix in {".jpg", ".jpeg"}:
        with Image.open(path) as img:
            if not has_metadata(img):
                return False
            img.load()
            img.info.pop("exif", None)
            # quality='keep' preserves the JPEG's existing quantization tables —
            # no re-encoding artifacts. The ICC profile and progressive encoding
            # must be passed explicitly: Pillow's JPEG writer only reads them
            # from save() kwargs, so omitting them silently drops the colour
            # profile (desaturating Display-P3 iPhone photos) and re-encodes
            # progressive files as baseline.
            img.save(
                path,
                format="JPEG",
                quality="keep",
                optimize=False,
                icc_profile=img.info.get("icc_profile"),
                progressive=img.info.get("progressive", False),
            )
        return True
    if suffix == ".png":
        with Image.open(path) as img:
            if not has_metadata(img):
                return False
            img.load()
            # Strip text chunks; Pillow won't write them unless we pass pnginfo.
            img.save(path, format="PNG")
        return True
    return False


def main() -> None:
    if len(sys.argv) > 1:
        files = [Path(arg) for arg in sys.argv[1:] if Path(arg).is_file()]
        base: Path | None = None
    else:
        if not TARGET.exists():
            print(f"error: {TARGET} not found", file=sys.stderr)
            sys.exit(1)
        files = sorted(p for p in TARGET.rglob("*") if p.is_file())
        base = TARGET

    stripped = []
    for p in files:
        try:
            if strip(p):
                stripped.append(p.relative_to(base) if base else p)
        except Exception as e:
            display = p.relative_to(base) if base else p
            print(f"  error processing {display}: {e}", file=sys.stderr)
    if base is None and not stripped:
        return  # quiet when invoked from the hook with nothing to do
    print(f"scanned: {len(files)} files")
    print(f"stripped: {len(stripped)}")
    for p in stripped:
        print(f"  {p}")


if __name__ == "__main__":
    main()
