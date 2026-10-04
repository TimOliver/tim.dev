#!/usr/bin/env python3
"""
Strip ALL EXIF / metadata from images under Assets/img/posts/.

- JPEG: applies orientation before stripping, retaining quantization tables,
  chroma sampling, ICC profile and progressive encoding.
- PNG:  re-saved with no text/iTXt/zTXt chunks.
- GIF:  not touched (no standard privacy metadata).

Orientation is applied to the pixels before metadata is discarded, so new
phone photos stay the right way up. ICC colour profiles are retained. JPEG
rewrites still recompress pixels; an already-clean image is never rewritten.

Idempotent: re-running on already-stripped images is a no-op (no EXIF found).

Usage:
    python3 Scripts/strip-exif.py             # walks Assets/img/posts/
    python3 Scripts/strip-exif.py <path>...   # processes specific files
                                              # (used by the pre-commit hook)
"""

from __future__ import annotations

import sys
import shutil
import tempfile
from pathlib import Path

from PIL import Image, ImageOps, JpegImagePlugin

REPO_ROOT = Path(__file__).resolve().parent.parent
TARGET = REPO_ROOT / "Assets/img/posts"


def has_metadata(img: Image.Image) -> bool:
    if any(key in img.info for key in ("exif", "xmp", "comment", "XML:com.adobe.xmp")):
        return True
    if hasattr(img, "_getexif") and img._getexif():
        return True
    # PNG text/iTXt/zTXt chunks - Pillow collects them all in .text, including
    # XMP (XML:com.adobe.xmp), which commonly carries GPS. The old
    # parameters/comment check missed those entirely.
    if img.format == "PNG" and getattr(img, "text", None):
        return True
    return False


def strip(path: Path) -> bool:
    """Returns True if the file was rewritten."""
    suffix = path.suffix.lower()
    if suffix not in {".jpg", ".jpeg", ".png"}:
        return False
    with Image.open(path) as img:
        if not has_metadata(img):
            return False
        if getattr(img, "is_animated", False):
            raise ValueError("Animated PNG metadata must be removed with an animation-aware editor")
        img.load()
        save_options = {"icc_profile": img.info.get("icc_profile")}
        if suffix in {".jpg", ".jpeg"}:
            # ImageOps returns a plain Image without JPEG's format/quantization
            # attributes, so quality='keep' cannot be used after transposition.
            # Pass the source encoder settings explicitly instead.
            save_options.update(format="JPEG", qtables=img.quantization,
                                subsampling=JpegImagePlugin.get_sampling(img),
                                optimize=False, progressive=img.info.get("progressive", False))
        else:
            save_options.update(format="PNG", optimize=True)
            if "transparency" in img.info:
                save_options["transparency"] = img.info["transparency"]
        clean = ImageOps.exif_transpose(img)
        clean.info.clear()
        # Write alongside the source and replace only after a complete save.
        # A failed encoder/disk write must not corrupt the author's original.
        with tempfile.NamedTemporaryFile(dir=path.parent, prefix=".strip-exif-", delete=False) as tmp:
            temporary = Path(tmp.name)
        try:
            clean.save(temporary, **save_options)
            shutil.copymode(path, temporary)
            temporary.replace(path)
        finally:
            temporary.unlink(missing_ok=True)
    return True


def main() -> int:
    if len(sys.argv) > 1:
        files = [Path(arg) for arg in sys.argv[1:]]
        base: Path | None = None
    else:
        if not TARGET.exists():
            print(f"error: {TARGET} not found", file=sys.stderr)
            return 1
        files = sorted(p for p in TARGET.rglob("*") if p.is_file())
        base = TARGET

    stripped = []
    errors = 0
    for p in files:
        try:
            if strip(p):
                stripped.append(p.relative_to(base) if base else p)
        except Exception as e:
            errors += 1
            display = p.relative_to(base) if base else p
            print(f"  error processing {display}: {e}", file=sys.stderr)
    if base is None and not stripped:
        return int(errors > 0)  # quiet when there was nothing to do
    print(f"scanned: {len(files)} files")
    print(f"stripped: {len(stripped)}")
    for p in stripped:
        print(f"  {p}")
    return int(errors > 0)


if __name__ == "__main__":
    sys.exit(main())
