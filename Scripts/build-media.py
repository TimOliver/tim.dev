#!/usr/bin/env python3
"""
Generates responsive variants + LQIP blur placeholders for post and collection media
and writes media-manifest.json at the repo root.

Sources are the images you drop into Assets/img/{posts,apps,code,art,talks}/.
For each source this emits <stem>@<width>w<ext> variants beside it, computes a
~20px-wide base64 blur placeholder, and records the intrinsic dimensions (so
cards reserve space and never shift as images load).

The manifest is a BUILD INPUT, not site output - it lives at the repo root
rather than under Assets/, because everything under Assets/ is copied verbatim
into Build/ and shipped.

Idempotent: re-runs skip variants that are newer than their source, and
generated variants are never themselves treated as sources.

GIFs and animated PNGs retain their original animation and receive metadata
without resized variants. Original source files are never modified.

Run after adding or changing images:  python3 Scripts/build-media.py
"""

from __future__ import annotations

import base64
import io
import json
import re
import sys
import tempfile
from pathlib import Path

from PIL import Image, ImageOps

REPO_ROOT = Path(__file__).resolve().parent.parent
ASSETS = REPO_ROOT / "Assets"
COLLECTIONS = ("posts", "apps", "code", "art", "talks", "about")
MANIFEST = REPO_ROOT / "media-manifest.json"

VARIANT_WIDTHS = (400, 800, 1200, 1600)
LQIP_WIDTH = 20
SOURCE_SUFFIXES = {".png", ".jpg", ".jpeg", ".gif"}

# Matches only this script's own <stem>@<width>w<ext> suffix - NOT any "@" in
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
    browser can't parse ANY candidate and falls back to `src` - the 20px
    LQIP blur - with no build error and no JS error. The likeliest real input
    is something like "Simulator Screen Shot - iPhone 15 Pro.png".

    "@" is reserved for this script's own <stem>@<width>w suffix (see
    is_variant above); a hand-authored file using "@" for anything else
    (e.g. the @2x retina convention) would otherwise be silently skipped as
    if it were a generated variant.
    """
    name = path.relative_to(ASSETS).as_posix()
    if any(char.isspace() for char in name) or "," in name or "@" in name:
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
    tiny = im.convert("RGBA" if "transparency" in im.info or "A" in im.getbands() else "RGB")
    tiny = tiny.resize((LQIP_WIDTH, height), Image.Resampling.LANCZOS)
    # Keep the colour profile, but never copy EXIF/XMP into an inline thumbnail.
    icc_profile = tiny.info.get("icc_profile")
    tiny.info.clear()
    buf = io.BytesIO()
    tiny.save(buf, format="PNG", optimize=True, icc_profile=icc_profile)
    return "data:image/png;base64," + base64.b64encode(buf.getvalue()).decode("ascii")


def build_variants(
    src: Path, im: Image.Image, expected: set[Path]
) -> list[tuple[int, str]]:
    """Emit downscaled variants; never upscale. Returns [(width, site_path)].

    Every variant path this source currently needs is added to `expected` -
    reused by prune_orphaned_variants() to delete generated files that no
    source asks for anymore (a replaced or renamed source otherwise leaves
    its old variants behind as dead bytes that still ship into Build/).
    """
    # GIFs keep their original frames, timing and palette; the manifest still
    # supplies dimensions and an original-only srcset. Animated PNGs follow the
    # same rule. Do not accidentally publish a flattened animation as a variant.
    if src.suffix.lower() == ".gif" or getattr(im, "is_animated", False):
        return [(im.width, site_path(src))]

    # Screenshots with baked-in device chrome are transparent PNGs - keep PNG.
    # Re-containering them as JPEG would fill the bezel's transparency black.
    is_png = src.suffix.lower() == ".png"
    out: list[tuple[int, str]] = []

    for width in VARIANT_WIDTHS:
        if width >= im.width * 0.9:
            continue  # never upscale or emit a near-duplicate of the original
        dst = src.with_name(f"{src.stem}@{width}w{src.suffix}")
        newest_input = max(src.stat().st_mtime, Path(__file__).stat().st_mtime)
        if not dst.exists() or dst.stat().st_mtime < newest_input:
            height = max(1, round(im.height * width / im.width))
            mode = "RGBA" if is_png and ("transparency" in im.info or "A" in im.getbands()) else "RGB"
            resized = im.convert(mode).resize((width, height), Image.Resampling.LANCZOS)
            icc_profile = im.info.get("icc_profile")
            resized.info.clear()
            with tempfile.NamedTemporaryFile(dir=dst.parent, prefix=".media-", delete=False) as tmp:
                temporary = Path(tmp.name)
            try:
                if is_png:
                    resized.save(temporary, format="PNG", optimize=True, icc_profile=icc_profile)
                else:
                    resized.save(temporary, format="JPEG", quality=80, progressive=True,
                                 optimize=True, icc_profile=icc_profile)
                temporary.chmod(0o644)
                temporary.replace(dst)
            finally:
                temporary.unlink(missing_ok=True)
        # Antialiasing a tiny flat-colour PNG can increase its byte size. Keep
        # the original as the candidate instead of offering a costlier derivative.
        if dst.stat().st_size >= src.stat().st_size:
            continue
        expected.add(dst)
        out.append((width, site_path(dst)))

    # The source is always the largest candidate.
    out.append((im.width, site_path(src)))
    return out


def prune_orphaned_variants(expected: set[Path]) -> None:
    """Delete generated variants no current source+width still asks for.

    This script rewrites the manifest from scratch every run but, without
    this pass, never touched the variant files themselves - replace a
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
            with Image.open(src) as original:
                original.load()
                # Match how a browser displays EXIF-oriented originals without
                # modifying them. Metadata stripping remains a separate step.
                animated = getattr(original, "is_animated", False)
                im = original if animated else ImageOps.exif_transpose(original)
                variants = build_variants(src, im, expected_variants)
                manifest[site_path(src)] = {
                    "width": im.width,
                    "height": im.height,
                    "lqip": lqip_data_uri(im),
                    "srcset": ", ".join(f"{p} {w}w" for w, p in variants),
                }

    prune_orphaned_variants(expected_variants)

    with tempfile.NamedTemporaryFile(mode="w", dir=MANIFEST.parent, prefix=".media-manifest-",
                                     encoding="utf-8", delete=False) as tmp:
        temporary = Path(tmp.name)
        try:
            tmp.write(json.dumps(manifest, indent=2, sort_keys=True) + "\n")
            tmp.close()
            temporary.chmod(0o644)
            temporary.replace(MANIFEST)
        finally:
            temporary.unlink(missing_ok=True)
    print(f"media-manifest.json: {len(manifest)} image(s)")


if __name__ == "__main__":
    main()
