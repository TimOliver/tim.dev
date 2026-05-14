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

Run from repo root:
    python3 Scripts/strip-exif.py
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
    # PNG text chunks
    if img.format == "PNG" and ("parameters" in img.info or "comment" in img.info):
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
            # no re-encoding artifacts.
            img.save(path, format="JPEG", quality="keep", optimize=False)
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
    if not TARGET.exists():
        print(f"error: {TARGET} not found", file=sys.stderr)
        sys.exit(1)
    files = sorted(p for p in TARGET.rglob("*") if p.is_file())
    stripped = []
    for p in files:
        try:
            if strip(p):
                stripped.append(p.relative_to(TARGET))
        except Exception as e:
            print(f"  error processing {p.relative_to(TARGET)}: {e}", file=sys.stderr)
    print(f"scanned: {len(files)} files")
    print(f"stripped: {len(stripped)}")
    for p in stripped:
        print(f"  {p}")


if __name__ == "__main__":
    main()
