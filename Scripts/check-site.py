#!/usr/bin/env python3
"""Check generated routes, assets, metadata, article images and RSS content.

Run after building: python3 Scripts/check-site.py [Build]
Only local references are checked; historical external sites are not fetched.
"""

from __future__ import annotations

import re
import sys
import xml.etree.ElementTree as ET
from collections import Counter
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import unquote, urljoin, urlsplit


SITE = "https://tim.dev"


class Page(HTMLParser):
    def __init__(self, html: str):
        super().__init__(convert_charrefs=True)
        self.ids: list[str] = []
        self.references: list[tuple[str, str]] = []
        self.images: list[dict[str, str]] = []
        self.canonicals: list[str] = []
        self.og_urls: list[str] = []
        self.robots: list[str] = []
        self.text: list[str] = []
        self.code_depth = 0
        self.anchor_depth = 0
        self.nested_anchors = False
        self.feed(html)

    def handle_starttag(self, tag, attributes):
        attrs = dict(attributes)
        if tag in {"pre", "code", "script", "style"}:
            self.code_depth += 1
        if tag == "a":
            self.nested_anchors |= self.anchor_depth > 0
            self.anchor_depth += 1
        if attrs.get("id"):
            self.ids.append(attrs["id"])
        if tag == "link" and attrs.get("rel") == "canonical":
            self.canonicals.append(attrs.get("href", ""))
        if tag == "meta" and attrs.get("property") == "og:url":
            self.og_urls.append(attrs.get("content", ""))
        if tag == "meta" and attrs.get("name") == "robots":
            self.robots.append(attrs.get("content", ""))
        if tag == "img":
            self.images.append(attrs)
        for key in ("href", "src"):
            if attrs.get(key):
                self.references.append((key, attrs[key]))
        for key in ("srcset", "data-srcset"):
            for candidate in attrs.get(key, "").split(","):
                if candidate.strip():
                    self.references.append((key, candidate.strip().split()[0]))

    def handle_endtag(self, tag):
        if tag in {"pre", "code", "script", "style"}:
            self.code_depth = max(0, self.code_depth - 1)
        if tag == "a":
            self.anchor_depth = max(0, self.anchor_depth - 1)

    def handle_data(self, text):
        if not self.code_depth:
            self.text.append(text)


def main() -> int:
    root = Path(sys.argv[1] if len(sys.argv) > 1 else "Build").resolve()
    paths = sorted(root.rglob("*.html"))
    if not paths:
        print(f"No HTML pages found in {root}; build the site first.", file=sys.stderr)
        return 1
    pages = {path: Page(path.read_text()) for path in paths}
    errors: set[str] = set()

    def fail(path: Path, message: str):
        errors.add(f"{path.relative_to(root)}: {message}")

    def route(path: Path) -> str:
        relative = path.relative_to(root).as_posix()
        return "/" + (relative[:-10] if relative.endswith("index.html") else relative)

    def local_target(url: str, base: str):
        resolved = urlsplit(urljoin(base, url))
        if resolved.scheme not in {"http", "https"} or resolved.netloc != "tim.dev":
            return None
        decoded = unquote(resolved.path)
        target = (root / decoded.lstrip("/")).resolve()
        if not target.is_relative_to(root):
            return None
        if target.is_dir():
            target /= "index.html"
        return target, unquote(resolved.fragment)

    for path, page in pages.items():
        base = SITE + route(path)
        duplicates = [value for value, count in Counter(page.ids).items() if count > 1]
        if duplicates:
            fail(path, f"duplicate IDs: {duplicates}")
        if page.nested_anchors:
            fail(path, "nested anchors")
        if path == root / "404.html":
            if page.canonicals or page.og_urls or "noindex" not in page.robots:
                fail(path, "error page must be noindex without a canonical/og:url")
        elif len(page.canonicals) != 1:
            fail(path, f"expected one canonical, found {len(page.canonicals)}")
        else:
            canonical = page.canonicals[0]
            parsed = urlsplit(canonical)
            if parsed.scheme != "https" or parsed.netloc != "tim.dev" or "//" in parsed.path:
                fail(path, f"malformed canonical: {canonical}")
            target = local_target(canonical, base)
            if target and target[0] != path:
                fail(path, f"canonical does not identify this output file: {canonical}")
            if page.og_urls != [canonical]:
                fail(path, "og:url does not match canonical")
        for attribute, url in page.references:
            target = local_target(url, base)
            if not target:
                continue
            file, fragment = target
            if not file.is_file():
                fail(path, f"missing {attribute} target: {url}")
            elif fragment and file in pages and fragment not in pages[file].ids:
                fail(path, f"missing fragment: {url}")
        for img in page.images:
            if not urlsplit(img.get("src", "")).path.startswith("/img/posts/"):
                continue
            if any(not img.get(dimension, "").isdigit() or int(img[dimension]) <= 0 for dimension in ("width", "height")):
                fail(path, f"post image lacks intrinsic dimensions: {img.get('src')}")
            if not img.get("srcset") or not img.get("sizes"):
                fail(path, f"post image lacks responsive candidates/sizes: {img.get('src')}")
            if img.get("loading") not in {"eager", "lazy"}:
                fail(path, f"post image lacks loading policy: {img.get('src')}")
        if re.search(r"!?\[[^\]\n]+\]\((?:/|https?://)[^)]+\)|!\[\]\([^)]+\)", "".join(page.text)):
            fail(path, "unrendered Markdown link/image outside code")

    feeds = sorted(root.glob("feed*.xml"))
    if len(feeds) != 5:
        errors.add(f"Expected five RSS feeds, found {len(feeds)}")
    for path in feeds:
        try:
            feed = ET.parse(path)
        except ET.ParseError as error:
            fail(path, f"invalid XML: {error}")
            continue
        items = feed.findall("./channel/item")
        if not items:
            fail(path, "feed is empty")
        for item in items:
            link = item.findtext("link", "")
            if not re.match(r"https://tim\.dev/\d{4}/", link):
                fail(path, f"non-blog item: {link}")
            if "//" in urlsplit(link).path:
                fail(path, f"double slash in item URL: {link}")
            if item.findtext("guid") != link:
                fail(path, f"item guid/link mismatch: {link}")
            destination = local_target(link, SITE + "/")
            if not destination or not destination[0].is_file():
                fail(path, f"missing feed item destination: {link}")
            for element in item:
                if element.tag.split("}")[-1] not in {"description", "encoded"}:
                    continue
                content = Page(element.text or "")
                if re.search(r"!\[[^\]]*\]\(", "".join(content.text)):
                    fail(path, f"unrendered Markdown image in {link}")
                for attribute, url in content.references:
                    if not urlsplit(url).scheme:
                        fail(path, f"relative {attribute} in feed entry: {url}")
                    target = local_target(url, link)
                    if target and not target[0].is_file():
                        fail(path, f"missing feed asset/link: {url}")

    for stylesheet in root.rglob("*.css"):
        for match in re.finditer(r"url\(\s*['\"]?([^'\")]+)['\"]?\s*\)", stylesheet.read_text()):
            url = match.group(1).strip()
            target = local_target(url, SITE + "/" + stylesheet.relative_to(root).as_posix())
            if target and not target[0].is_file():
                fail(stylesheet, f"missing CSS asset: {url}")

    sitemap = root / "sitemap.xml"
    try:
        tree = ET.parse(sitemap)
        for element in tree.iter():
            if element.tag.split("}")[-1] == "loc":
                target = local_target(element.text or "", SITE + "/")
                if not target or not target[0].is_file():
                    fail(sitemap, f"missing sitemap destination: {element.text}")
                elif not urlsplit(element.text or "").path.endswith(("/", ".html")):
                    fail(sitemap, f"sitemap URL lacks the canonical trailing slash: {element.text}")
    except (OSError, ET.ParseError) as error:
        errors.add(f"sitemap.xml: {error}")

    # A page that uses a front-end feature must load its script; Site.swift
    # strips unused loaders from article pages and must never over-strip.
    feature_loaders = {
        "data-lightbox": "/js/lightbox3.umd.js",
        "<lite-youtube": "/js/lite-yt-embed.js",
    }
    for path in paths:
        html = path.read_text()
        for marker, script in feature_loaders.items():
            stem, extension = script.rsplit(".", 1)
            loaded = re.search(rf'src="{re.escape(stem)}(\.[0-9a-f]{{8}})?\.{extension}"', html)
            if marker in html and not loaded:
                fail(path, f"uses {marker} but does not load {script}")

    # Dotfiles (.DS_Store and the like) must never deploy; Site.swift deletes
    # them after publishing, so one here means that pass broke.
    for dotfile in root.rglob(".*"):
        fail(dotfile, "dotfile in the build output")

    for error in sorted(errors):
        print(error, file=sys.stderr)
    print(f"Checked {len(pages)} HTML pages, {len(feeds)} RSS feeds and sitemap: {len(errors)} error(s).")

    # Not an error: required collection Details rows nobody has filled in yet.
    # `swift run IgniteStarter` logs each one as "TBC: <path> <row>".
    unfilled = sum(1 for path in paths if "<dd>[TBC]</dd>" in path.read_text())
    if unfilled:
        print(f"Note: {unfilled} collection page(s) still show [TBC] Details rows.")
    return int(bool(errors))


if __name__ == "__main__":
    raise SystemExit(main())
