#!/usr/bin/env python3
"""
One-time (idempotent) weight pass over Assets/img/posts/.

The blog's article column is 950px wide (heroes cap at 750px, inline images at
650px tall), so nothing on the site can ever display more than ~1900px of
image - yet the WordPress import carried full-resolution originals (up to
4032px, 4.6MB). This script:

- Downscales any raster larger than 1900px on its longest side (LANCZOS,
  never upscales).
- Re-encodes JPEGs at quality 80 (progressive) when that meaningfully shrinks
  them; preserves ICC profiles (Display-P3 photos keep their colour), strips
  everything else.
- Converts named photographic PNGs to JPEG (PNG is the wrong container for
  photos - 4.6MB → ~0.5MB) and rewrites their references in Content/ and
  Includes/_posts/. True screenshots stay PNG.
- GIFs and SVGs are untouched.

Run after adding heavy images:  python3 Scripts/optimize-images.py
"""

from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image

REPO_ROOT = Path(__file__).resolve().parent.parent
TARGET = REPO_ROOT / "Assets/img/posts"
MAX_EDGE = 1900
JPEG_QUALITY = 80
# Only re-encode an un-resized JPEG when it's heavy and q80 actually pays.
REENCODE_MIN_BYTES = 400_000
REENCODE_MIN_SAVING = 0.20

# Photographic PNGs (from the 2026-07 site audit) that should be JPEGs.
# Flat-UI screenshots keep PNG's lossless edges; these are photos/renders.
CONVERT_TO_JPEG = {
    "2010/03/pokemon_heartgold.png",
    "2015/12/Pokedex-Denied.png",
    "2010/03/pokewalker.png",
    "2015/12/Pokedex_Snivy.png",
    "2010/01/ipad.png",
    "2010/09/Pokemon_Black_Boxart.png",
    "2012/06/WWDC2012_KeynoteSeaOfNerds.png",
}


def save_jpeg(img: Image.Image, path: Path, source: Image.Image) -> None:
    if img.mode not in ("RGB", "L"):
        img = img.convert("RGB")
    img.save(
        path,
        format="JPEG",
        quality=JPEG_QUALITY,
        optimize=True,
        progressive=True,
        icc_profile=source.info.get("icc_profile"),
    )


def downscaled(img: Image.Image) -> Image.Image | None:
    """The image resized to fit MAX_EDGE, or None if it already fits."""
    if max(img.size) <= MAX_EDGE:
        return None
    scale = MAX_EDGE / max(img.size)
    new_size = (round(img.width * scale), round(img.height * scale))
    return img.resize(new_size, Image.Resampling.LANCZOS)


def rewrite_refs(old_rel: str, new_rel: str) -> int:
    """Point Content/ and Includes/_posts/ references at the converted file."""
    changed = 0
    for base in (REPO_ROOT / "Content", REPO_ROOT / "Includes/_posts"):
        for f in base.rglob("*"):
            if f.suffix not in {".md", ".html"} or not f.is_file():
                continue
            text = f.read_text(encoding="utf-8")
            if old_rel in text:
                f.write_text(text.replace(old_rel, new_rel), encoding="utf-8")
                changed += 1
    return changed


def main() -> None:
    if not TARGET.exists():
        print(f"error: {TARGET} not found", file=sys.stderr)
        sys.exit(1)

    total_before = total_after = 0
    touched = 0
    for path in sorted(TARGET.rglob("*")):
        suffix = path.suffix.lower()
        if suffix not in {".jpg", ".jpeg", ".png"}:
            continue
        rel = path.relative_to(TARGET).as_posix()
        before = path.stat().st_size

        with Image.open(path) as img:
            img.load()
            resized = downscaled(img)

            if suffix == ".png" and rel in CONVERT_TO_JPEG:
                new_path = path.with_suffix(".jpg")
                save_jpeg(resized or img, new_path, img)
                path.unlink()
                refs = rewrite_refs(f"/img/posts/{rel}", f"/img/posts/{rel[:-4]}.jpg")
                after = new_path.stat().st_size
                print(f"  {rel} → .jpg  {before//1024}KB → {after//1024}KB  ({refs} refs updated)")
            elif suffix == ".png":
                if resized is None:
                    continue
                resized.save(path, format="PNG", optimize=True)
                after = path.stat().st_size
                print(f"  {rel}  resized {img.width}px → {resized.width}px  {before//1024}KB → {after//1024}KB")
            else:  # JPEG
                if resized is not None:
                    save_jpeg(resized, path, img)
                elif before >= REENCODE_MIN_BYTES:
                    # Trial re-encode at q80; keep only a real saving.
                    trial = path.with_suffix(".tmp.jpg")
                    save_jpeg(img, trial, img)
                    if trial.stat().st_size <= before * (1 - REENCODE_MIN_SAVING):
                        trial.replace(path)
                    else:
                        trial.unlink()
                        continue
                else:
                    continue
                after = path.stat().st_size
                note = f"resized {img.width}px → {resized.width}px  " if resized is not None else "re-encoded  "
                print(f"  {rel}  {note}{before//1024}KB → {after//1024}KB")

        total_before += before
        total_after += after
        touched += 1

    saved = (total_before - total_after) // (1024 * 1024)
    print(f"\n{touched} files: {total_before//(1024*1024)}MB → {total_after//(1024*1024)}MB  (saved {saved}MB)")


if __name__ == "__main__":
    main()
