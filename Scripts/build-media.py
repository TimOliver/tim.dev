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

from PIL import Image, ImageOps, JpegImagePlugin

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
    src: Path, im: Image.Image, expected: set[Path], previous: dict | None = None
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
    # An OPAQUE PNG (a photo or screenshot saved as PNG) may encode far smaller
    # as JPEG; each width uses whichever format is smaller by a clear margin.
    is_png = src.suffix.lower() == ".png"
    has_alpha = is_png and ("transparency" in im.info or "A" in im.getbands())
    jpeg_ok = not has_alpha and not (is_png and src.with_suffix(".jpg").exists())
    out: list[tuple[int, str]] = []
    newest_input = max(src.stat().st_mtime, Path(__file__).stat().st_mtime)

    # Downscaled widths, plus a re-encode at the source's own width: some
    # originals (high-quality renders, PNG photos) are several times heavier
    # per pixel than a quality-80 JPEG, and the largest candidate is what
    # 2x/3x screens fetch. The untouched original stays the lightbox target.
    widths = [w for w in VARIANT_WIDTHS if w < im.width * 0.9] + [im.width]
    # A rejected full-width re-encode is deleted, so remember the verdict:
    # when the last manifest (written after this source last changed) kept
    # the original on top, don't re-encode it on every run.
    if (previous and previous.get("srcset", "").endswith(f"{site_path(src)} {im.width}w")
            and MANIFEST.exists() and MANIFEST.stat().st_mtime >= newest_input):
        widths.pop()
    for width in widths:
        variant = encode_variant(src, im, width, is_png, has_alpha, jpeg_ok, newest_input)
        if variant is None:
            continue
        # Keep a variant only when it beats the original by enough to matter;
        # otherwise the original itself is the better candidate. (Antialiasing
        # a tiny flat-colour PNG can even make a downscale bigger.)
        size, original = variant.stat().st_size, src.stat().st_size
        if width == im.width:
            worthwhile = size <= original * 0.8 and original - size >= 10_000
        else:
            worthwhile = size < original
        if not worthwhile:
            continue
        expected.add(variant)
        out.append((width, site_path(variant)))

    # The source is the largest candidate unless a full-width re-encode won.
    if not out or out[-1][0] != im.width:
        out.append((im.width, site_path(src)))
    return out


def full_chroma(src: Path) -> bool:
    """True for a JPEG source encoded 4:4:4 (reads only the header)."""
    if src.suffix.lower() not in (".jpg", ".jpeg"):
        return False
    with Image.open(src) as im:
        return JpegImagePlugin.get_sampling(im) == 0


def encode_variant(src: Path, im: Image.Image, width: int, is_png: bool, has_alpha: bool,
                   jpeg_ok: bool, newest_input: float) -> Path | None:
    """Write (or reuse) <stem>@<width>w as PNG or JPEG; returns its path."""
    as_png = src.with_name(f"{src.stem}@{width}w.png") if is_png else None
    as_jpg = src.with_name(f"{src.stem}@{width}w{'.jpg' if is_png else src.suffix}") if jpeg_ok else None
    # Reuse whichever format a previous run chose, while it is still fresh.
    for existing in (as_png, as_jpg):
        if existing and existing.exists() and existing.stat().st_mtime >= newest_input:
            return existing

    height = max(1, round(im.height * width / im.width))
    mode = "RGBA" if has_alpha else "RGB"
    resized = im.convert(mode)
    if width != im.width:
        resized = resized.resize((width, height), Image.Resampling.LANCZOS)
    icc_profile = im.info.get("icc_profile")
    resized.info.clear()

    encoded: dict[Path, bytes] = {}
    if as_png:
        buffer = io.BytesIO()
        resized.save(buffer, format="PNG", optimize=True, icc_profile=icc_profile)
        encoded[as_png] = buffer.getvalue()
    if as_jpg:
        buffer = io.BytesIO()
        # Converted PNGs are often screenshots with text: a little more quality.
        # A JPEG saved without chroma subsampling (4:4:4: the app heroes, where 4:2:0
        # smears red UI text) is a showcase graphic, not a photo: it keeps 4:4:4 at
        # quality 95, 97 for the full-width copy (q80 flattens dithered gradients into blocks).
        if full_chroma(src):
            quality, extra = (97 if width == im.width else 95), {"subsampling": 0}
        else:
            quality, extra = (85 if is_png else 80), {}
        resized.save(buffer, format="JPEG", quality=quality, progressive=True,
                     optimize=True, icc_profile=icc_profile, **extra)
        encoded[as_jpg] = buffer.getvalue()
    if as_png and as_jpg and len(encoded[as_jpg]) > len(encoded[as_png]) * 0.75:
        del encoded[as_jpg]  # PNG wins unless JPEG is clearly smaller
    elif as_png and as_jpg:
        del encoded[as_png]
    (dst, data), = encoded.items()

    for other in (as_png, as_jpg):
        if other and other != dst:
            other.unlink(missing_ok=True)
    with tempfile.NamedTemporaryFile(dir=dst.parent, prefix=".media-", delete=False) as tmp:
        temporary = Path(tmp.name)
        tmp.write(data)
    try:
        temporary.chmod(0o644)
        temporary.replace(dst)
    finally:
        temporary.unlink(missing_ok=True)
    return dst


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
    try:
        previous_manifest = json.loads(MANIFEST.read_text())
    except (OSError, ValueError):
        previous_manifest = {}
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
                variants = build_variants(src, im, expected_variants,
                                          previous_manifest.get(site_path(src)))
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
