#!/usr/bin/env python3
"""
Migrate WordPress -> Jekyll export at tim.dev-local/jekyll-export into the
Ignite-friendly layout under tim.dev/Content/posts and tim.dev/Assets/img/posts.

What it does, per post:
  - Strips WordPress cruft from front matter (id, guid, dsq_thread_id,
    ao_post_optimize, apple_news_*, layout, Hide *, spay_email, ...).
  - Keeps: title, date, author, image, categories (-> tags), permalink (-> path).
  - Normalizes date from ISO 8601 ('2008-11-16T13:01:08+09:00') to Ignite's
    accepted 'YYYY-MM-DD HH:MM:SS' (Ignite parses dates as GMT, but we only care
    about day-level granularity for sort/display, so dropping the offset is OK).
  - Decodes HTML entities in title (&#8217; etc.).
  - Body URL rewrites:
      * Strips WP resize variant suffix from images: 'foo-300x225.jpg' -> 'foo.jpg'
        (also '@2x'/'@3x' retina variants).
      * '/wp-content/uploads/YYYY/MM/...' -> '/img/posts/YYYY/MM/...'
      * Absolute old-domain URLs (tim-oliver.com, timoliver.com.au, timoliver.blog)
        -> root-relative.
      * Collapses '[![alt](X)](X)' (markdown image-as-link after variant strip
        becomes redundant) -> '![alt](X)'.

Image copy (separate pass):
  - Walks wp-content/uploads/YYYY/MM/, copies originals (no '-WxH' variant
    suffix, no '@2x'/'@3x') to Assets/img/posts/YYYY/MM/.
  - Strips ALL EXIF / metadata from copied JPEGs and PNGs (Pillow required).
    GPS coordinates leak otherwise; Make/Model/DateTime go too for a clean
    sweep. JPEG re-saved with quality='keep' so no perceptible quality loss.
    Idempotent: re-running on already-stripped images is a no-op.

Drafts (_drafts) are intentionally skipped — filenames look like WP autosave
artifacts, not real drafts.

Run from repo root:
    python3 Scripts/migrate-wp.py
"""

from __future__ import annotations

import html
import re
import shutil
import sys
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path

try:
    from PIL import Image
except ImportError:
    print("error: Pillow is required for EXIF stripping. `pip3 install Pillow`.", file=sys.stderr)
    sys.exit(1)

REPO_ROOT = Path(__file__).resolve().parent.parent
JEKYLL_ROOT = Path.home() / "Developer/tim.dev-local/jekyll-export"
POSTS_SRC = JEKYLL_ROOT / "_posts"
UPLOADS_SRC = JEKYLL_ROOT / "wp-content/uploads"

CONTENT_DST = REPO_ROOT / "Content/posts"
ASSETS_DST = REPO_ROOT / "Assets/img/posts"

# Front matter keys we keep (everything else is dropped).
KEPT_KEYS = {"title", "date", "author", "image", "categories", "permalink"}

# Regex helpers
RE_OLD_DOMAINS = re.compile(
    r"https?://(?:www\.)?(?:tim-oliver\.com|timoliver\.com\.au|timoliver\.blog)"
)
# Strip WP resize variants from image filenames in URLs (also retina @2x/@3x).
RE_WP_VARIANT = re.compile(
    r"(/wp-content/uploads/\d{4}/\d{2}/[^\s\"')]+?)-\d+x\d+(?:@\dx)?(\.(?:jpe?g|png|gif))",
    re.IGNORECASE,
)
RE_WP_UPLOADS = re.compile(r"/wp-content/uploads/")
# Collapse '[![alt](X "title")](X)' / '[![alt](X)](X)' to '![alt](X)' when both
# URLs match. Title is optional. Done AFTER variant stripping so inner+outer
# normalize to the same URL.
RE_IMG_AS_LINK = re.compile(
    r"""\[
        !\[(?P<alt>[^\]]*)\]
        \((?P<inner>\S+?)(?:\s+"[^"]*")?\)
        \]
        \((?P<outer>\S+?)\)""",
    re.VERBOSE,
)


@dataclass
class Post:
    src: Path
    metadata: dict[str, object] = field(default_factory=dict)
    body: str = ""


def parse_frontmatter(text: str) -> tuple[dict[str, object], str]:
    """Hand-rolled YAML-subset parser for Jekyll/WP exports.

    Handles:
      key: value
      key: 'quoted value with: colons'
      key:
          - item
          - 'quoted item'
    Returns (metadata dict, body string).
    """
    if not text.startswith("---"):
        return {}, text
    # Split off frontmatter block: between the opening '---' and the next '---'.
    parts = text.split("\n---", 1)
    if len(parts) < 2:
        return {}, text
    header = parts[0].lstrip("-").lstrip("\n")
    body = parts[1].lstrip("\n")

    meta: dict[str, object] = {}
    current_key: str | None = None
    current_array: list[str] | None = None

    for raw in header.splitlines():
        if not raw.strip():
            continue
        if raw.startswith("    -") or raw.startswith("\t-"):
            value = raw.lstrip(" \t-").strip()
            value = strip_quotes(value)
            if current_array is None:
                # array continuation without preceding 'key:' — defensive
                continue
            current_array.append(value)
            continue
        # top-level: key: value  OR  key:
        if ":" not in raw:
            continue
        key, _, value = raw.partition(":")
        key = key.strip()
        value = value.strip()
        if value == "":
            # start of an array block
            current_key = key
            current_array = []
            meta[key] = current_array
        else:
            meta[key] = strip_quotes(value)
            current_key = None
            current_array = None

    return meta, body


def strip_quotes(s: str) -> str:
    if len(s) >= 2 and s[0] == s[-1] and s[0] in ("'", '"'):
        return s[1:-1]
    return s


def normalize_date(date_str: str) -> str | None:
    """ISO 8601 with offset -> 'YYYY-MM-DD HH:MM:SS' (dropping offset)."""
    # Common format: '2008-11-16T13:01:08+09:00' or '2008-11-16T13:01:08Z'
    m = re.match(r"^(\d{4}-\d{2}-\d{2})[T ](\d{2}:\d{2}:\d{2})", date_str)
    if m:
        return f"{m.group(1)} {m.group(2)}"
    # Already date-only
    m = re.match(r"^(\d{4}-\d{2}-\d{2})$", date_str)
    if m:
        return f"{m.group(1)} 00:00:00"
    return None


def rewrite_urls(text: str) -> str:
    """Apply URL rewrites in order: strip variants, fix paths, fix old domains,
    collapse image-as-link duplicates."""
    # 1. Strip WP image variant suffixes (must come before path rewrite so the
    # variant regex sees /wp-content/uploads/...).
    text = RE_WP_VARIANT.sub(r"\1\2", text)
    # Loop in case a URL has both -WxH and @2x stripped at different positions.
    prev = None
    while prev != text:
        prev = text
        text = RE_WP_VARIANT.sub(r"\1\2", text)

    # 2. Strip old absolute domains -> root-relative.
    text = RE_OLD_DOMAINS.sub("", text)

    # 3. Rewrite /wp-content/uploads/ -> /img/posts/
    text = RE_WP_UPLOADS.sub("/img/posts/", text)

    # 4. Collapse '[![alt](X)](X)' redundancy.
    def collapse(m: re.Match[str]) -> str:
        if m.group("inner") == m.group("outer"):
            return f"![{m.group('alt')}]({m.group('outer')})"
        return m.group(0)

    text = RE_IMG_AS_LINK.sub(collapse, text)
    return text


def build_clean_frontmatter(meta: dict[str, object]) -> str:
    """Emit a clean single-line frontmatter block from a metadata dict."""
    lines = ["---"]

    # title
    if "title" in meta and isinstance(meta["title"], str):
        title = html.unescape(meta["title"])
        lines.append(f"title: {yaml_quote(title)}")

    # date — normalized
    if "date" in meta and isinstance(meta["date"], str):
        normalized = normalize_date(meta["date"])
        if normalized:
            lines.append(f"date: {normalized}")

    # author
    if "author" in meta and isinstance(meta["author"], str):
        lines.append(f"author: {yaml_quote(meta['author'])}")

    # image (rewritten path)
    if "image" in meta and isinstance(meta["image"], str):
        image = rewrite_urls(meta["image"])
        lines.append(f"image: {image}")

    # categories -> tags (comma-joined, lowercased)
    cats = meta.get("categories")
    if isinstance(cats, list) and cats:
        tags = ", ".join(c.lower() for c in cats)
        lines.append(f"tags: {tags}")

    # permalink -> path
    if "permalink" in meta and isinstance(meta["permalink"], str):
        lines.append(f"path: {meta['permalink']}")

    lines.append("---")
    return "\n".join(lines) + "\n"


def yaml_quote(s: str) -> str:
    """Quote a string for YAML when it contains special characters."""
    if any(ch in s for ch in ":#'\"") or s != s.strip():
        # Use double quotes, escape internal double quotes.
        escaped = s.replace("\\", "\\\\").replace('"', '\\"')
        return f'"{escaped}"'
    return s


def migrate_posts() -> tuple[int, int]:
    """Returns (written, skipped)."""
    if not POSTS_SRC.exists():
        print(f"error: source posts dir not found: {POSTS_SRC}", file=sys.stderr)
        sys.exit(1)
    CONTENT_DST.mkdir(parents=True, exist_ok=True)

    written = skipped = 0
    for src in sorted(POSTS_SRC.glob("*.md")):
        text = src.read_text(encoding="utf-8")
        meta, body = parse_frontmatter(text)
        if not meta:
            print(f"skip (no frontmatter): {src.name}")
            skipped += 1
            continue
        clean_fm = build_clean_frontmatter(meta)
        clean_body = rewrite_urls(body)
        out = CONTENT_DST / src.name
        out.write_text(clean_fm + clean_body, encoding="utf-8")
        written += 1
    return written, skipped


def is_image_variant(name: str) -> bool:
    """True if filename has a WP resize/retina suffix like '-300x225' or '-300x225@2x'."""
    return bool(
        re.search(r"-\d+x\d+(?:@\dx)?\.(?:jpe?g|png|gif)$", name, re.IGNORECASE)
    )


def strip_metadata(path: Path) -> None:
    """Remove all EXIF / metadata from a JPEG or PNG in-place. No-op on other formats."""
    suffix = path.suffix.lower()
    if suffix in {".jpg", ".jpeg"}:
        with Image.open(path) as img:
            has_exif = "exif" in img.info or (
                hasattr(img, "_getexif") and bool(img._getexif())
            )
            if not has_exif:
                return
            img.load()
            img.info.pop("exif", None)
            img.save(path, format="JPEG", quality="keep", optimize=False)
    elif suffix == ".png":
        with Image.open(path) as img:
            if "exif" not in img.info:
                return
            img.load()
            img.save(path, format="PNG")


def copy_images() -> tuple[int, int]:
    """Returns (copied, skipped). Skips already-up-to-date files."""
    if not UPLOADS_SRC.exists():
        print(f"warning: uploads dir not found: {UPLOADS_SRC}", file=sys.stderr)
        return 0, 0
    ASSETS_DST.mkdir(parents=True, exist_ok=True)

    copied = skipped = 0
    # Walk YYYY/MM/ subdirs explicitly so non-conforming subdirs (smush/, freebies/,
    # wpcf7_captcha/, etc.) are ignored.
    for year_dir in sorted(UPLOADS_SRC.iterdir()):
        if not year_dir.is_dir() or not re.match(r"^\d{4}$", year_dir.name):
            continue
        for month_dir in sorted(year_dir.iterdir()):
            if not month_dir.is_dir() or not re.match(r"^\d{2}$", month_dir.name):
                continue
            dest_dir = ASSETS_DST / year_dir.name / month_dir.name
            for src_file in sorted(month_dir.iterdir()):
                if not src_file.is_file():
                    continue
                # Skip non-image files (php, css, js, log, etc.).
                if src_file.suffix.lower() not in {".jpg", ".jpeg", ".png", ".gif"}:
                    continue
                if is_image_variant(src_file.name):
                    continue
                dest_dir.mkdir(parents=True, exist_ok=True)
                dest_file = dest_dir / src_file.name
                # mtime is the sole idempotency signal — strip_metadata changes
                # file size so size-equality can't be used, and the mtime is
                # restored from src after the strip so a second run skips.
                if (
                    dest_file.exists()
                    and int(dest_file.stat().st_mtime) == int(src_file.stat().st_mtime)
                ):
                    skipped += 1
                    continue
                shutil.copy2(src_file, dest_file)
                strip_metadata(dest_file)
                src_stat = src_file.stat()
                os_utime(dest_file, src_stat.st_atime, src_stat.st_mtime)
                copied += 1
    return copied, skipped


def os_utime(path: Path, atime: float, mtime: float) -> None:
    import os
    os.utime(path, (atime, mtime))


def main() -> None:
    print(f"src posts:  {POSTS_SRC}")
    print(f"src images: {UPLOADS_SRC}")
    print(f"dst posts:  {CONTENT_DST}")
    print(f"dst images: {ASSETS_DST}")
    print()
    print("migrating posts...")
    written, skipped = migrate_posts()
    print(f"  posts written: {written}, skipped: {skipped}")
    print("copying images...")
    copied, img_skipped = copy_images()
    print(f"  images copied: {copied}, up-to-date: {img_skipped}")


if __name__ == "__main__":
    main()
