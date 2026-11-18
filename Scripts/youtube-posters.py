#!/usr/bin/env python3
"""Fetch a local poster for every YouTube video embedded in a post.

Posts embed YouTube as a raw iframe (WordPress era) or a <lite-youtube>; the
build turns both into the click-to-play facade, whose placeholder would
otherwise be fetched from YouTube's image server on page load. This saves each
video's thumbnail once as Assets/img/posts/youtube/<id>.jpg (committed, like
any post image), so nothing contacts YouTube until Play is pressed.

Already-saved posters are never re-fetched, so a normal build makes no network
requests. The largest thumbnail YouTube has is kept (maxres 1280x720, else
sd, else hq). Metadata is stripped like every other image. Exits non-zero if
any video still has no poster: the Swift build refuses to render one without.

    python3 Scripts/youtube-posters.py
"""
import io
import re
import subprocess
import sys
import urllib.request
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
POSTS = ROOT / "Content/posts"
OUT = ROOT / "Assets/img/posts/youtube"

# The same embeds ArticleContent rewrites: iframe src (any youtube host,
# protocol-relative included) and an explicit <lite-youtube videoid>.
IFRAME = re.compile(r'<iframe\b[^>]*\bsrc=["\'](?:https?:)?//(?:www\.)?youtube(?:-nocookie)?\.com/embed/([A-Za-z0-9_-]{11})', re.I)
LITE = re.compile(r'<lite-youtube\b[^>]*\bvideoid=["\']([A-Za-z0-9_-]{11})["\']', re.I)
SIZES = ["maxresdefault", "sddefault", "hqdefault"]


def video_ids():
    ids = set()
    for post in sorted(POSTS.glob("*.md")):
        text = post.read_text(encoding="utf-8")
        ids.update(IFRAME.findall(text))
        ids.update(LITE.findall(text))
    return sorted(ids)


def fetch(video_id):
    """The largest real thumbnail's bytes, or None. YouTube answers a missing
    size with a 120x90 grey placeholder (sometimes as a 200), so check."""
    for size in SIZES:
        url = f"https://i.ytimg.com/vi/{video_id}/{size}.jpg"
        request = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
        try:
            with urllib.request.urlopen(request, timeout=20) as response:
                data = response.read()
        except Exception:
            continue
        with Image.open(io.BytesIO(data)) as image:
            if image.size != (120, 90):
                return data
    return None


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    fetched, missing = [], []
    for video_id in video_ids():
        target = OUT / f"{video_id}.jpg"
        if target.exists():
            continue
        data = fetch(video_id)
        if data is None:
            missing.append(video_id)
            continue
        target.write_bytes(data)
        fetched.append(target)
        print(f"youtube-posters: saved {target.relative_to(ROOT)}")
    if fetched:
        subprocess.run([sys.executable, str(ROOT / "Scripts/strip-exif.py"), *map(str, fetched)], check=True)
    if missing:
        sys.exit("youtube-posters: no thumbnail for " + ", ".join(missing)
                 + " - save one by hand as Assets/img/posts/youtube/<id>.jpg")


if __name__ == "__main__":
    main()
