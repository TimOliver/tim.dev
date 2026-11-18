#!/usr/bin/env python3
"""Sync Build/ to a Bunny storage zone, uploading only what changed.

The build is deterministic (two builds of the same commit are byte-identical),
so a deploy is a diff: hash every file in Build/, compare with the SHA-256
checksums Bunny reports for the files it holds, then

  1. upload new and changed files - everything else first, HTML and feeds
     last, so no page goes live before the CSS, JS and images it points at;
  2. delete files that are no longer in the build;
  3. purge the URLs whose files changed or went away - after the delete, so
     the CDN can't re-fetch a removed file in between (or the whole pull
     zone, past PURGE_ALL_OVER URLs). Each purge is a wildcard, so the
     /post/?fbclid=... and /post/index.html variants go too.

Nothing is uploaded twice and nothing unchanged is purged, so a new post is a
handful of requests. Run with --dry-run to print the plan without touching
anything.

    python3 Scripts/deploy-bunny.py [--dry-run] [--build DIR]

Credentials come from the environment (GitHub Actions secrets):

    BUNNY_STORAGE_ZONE      storage zone name
    BUNNY_STORAGE_KEY       storage zone password (FTP & API access)
    BUNNY_STORAGE_HOST      region endpoint, e.g. syd.storage.bunnycdn.com
                            (default storage.bunnycdn.com, Falkenstein)
    BUNNY_API_KEY           account API key, for purging
    BUNNY_PULL_ZONE_ID      pull zone id, for a full purge
    SITE_URL                default https://tim.dev

For testing, --against DIR treats a local folder as the storage zone.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
WORKERS = 12
PURGE_ALL_OVER = 300
# Pages and feeds go up after the files they reference.
LAST = (".html", ".xml", ".txt", ".webmanifest")


def local_files(build: Path) -> dict[str, str]:
    """Build-relative path -> SHA-256 (uppercase hex, as Bunny reports it)."""
    files = {}
    for path in sorted(build.rglob("*")):
        if path.is_file() and not path.name.startswith("."):
            files[path.relative_to(build).as_posix()] = hashlib.sha256(path.read_bytes()).hexdigest().upper()
    return files


def urls_for(path: str, site: str) -> list[str]:
    """Purge patterns for a stored file: its URL plus any query-string
    variant the CDN may have cached separately (shared links carry ?fbclid=
    and the like), and a page's /index.html spelling. Bunny treats a trailing
    * as a wildcard. A page's folder isn't wildcarded as a whole: for the
    home page that would purge the entire site."""
    url = site + "/" + urllib.parse.quote(path)
    if path == "index.html" or path.endswith("/index.html"):
        folder = url[: -len("index.html")]
        return [folder, folder + "?*", url + "*"]
    return [url + "*"]


def http(method: str, url: str, key: str, data: bytes | None = None, headers: dict | None = None,
         missing_ok: bool = False) -> bytes:
    """One Bunny API call, retried with backoff on 5xx and network errors."""
    for attempt in range(4):
        req = urllib.request.Request(url, data=data, method=method, headers={"AccessKey": key, **(headers or {})})
        try:
            with urllib.request.urlopen(req, timeout=60) as response:
                return response.read()
        except urllib.error.HTTPError as error:
            if error.code == 404 and missing_ok:
                return b"[]"
            if error.code < 500 or attempt == 3:
                raise SystemExit(f"deploy: {method} {url} failed: HTTP {error.code} {error.read()[:200]!r}")
        except (urllib.error.URLError, TimeoutError) as error:
            if attempt == 3:
                raise SystemExit(f"deploy: {method} {url} failed: {error}")
        time.sleep(2 ** attempt)
    raise AssertionError("unreachable")


class LocalZone:
    """A folder standing in for the storage zone (tests, --against)."""

    def __init__(self, root: Path):
        self.root = root

    def checksums(self) -> dict[str, str]:
        return local_files(self.root) if self.root.exists() else {}

    def put(self, path: str, data: bytes, checksum: str) -> None:
        target = self.root / path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(data)

    def delete(self, path: str) -> None:
        (self.root / path).unlink(missing_ok=True)


class BunnyZone:
    """Bunny Storage HTTP API: per-directory listings with checksums."""

    def __init__(self, zone: str, key: str, host: str):
        self.base = f"https://{host}/{urllib.parse.quote(zone)}/"
        self.key = key

    def request(self, method: str, path: str, data: bytes | None = None, headers: dict | None = None) -> bytes:
        return http(method, self.base + urllib.parse.quote(path), self.key, data, headers,
                    missing_ok=method in ("GET", "DELETE"))

    def checksums(self) -> dict[str, str]:
        found: dict[str, str] = {}
        pending = [""]
        with ThreadPoolExecutor(WORKERS) as pool:
            while pending:
                listings = list(pool.map(lambda d: (d, json.loads(self.request("GET", d))), pending))
                pending = []
                for directory, entries in listings:
                    for entry in entries:
                        path = directory + entry["ObjectName"]
                        if entry.get("IsDirectory"):
                            pending.append(path + "/")
                        else:
                            # A missing checksum just means "re-upload it".
                            found[path] = (entry.get("Checksum") or "").upper()
        return found

    def put(self, path: str, data: bytes, checksum: str) -> None:
        # Bunny verifies the body against Checksum and rejects a corrupt upload.
        self.request("PUT", path, data, {"Checksum": checksum, "Content-Type": "application/octet-stream"})

    def delete(self, path: str) -> None:
        self.request("DELETE", path)


def purge(urls: list[str], dry_run: bool) -> None:
    key = os.environ.get("BUNNY_API_KEY")
    if not urls:
        return
    zone = os.environ.get("BUNNY_PULL_ZONE_ID")
    if len(urls) > PURGE_ALL_OVER and zone:
        print(f"purge: whole pull zone ({len(urls)} URLs changed)")
        if not dry_run:
            api(key, f"https://api.bunny.net/pullzone/{zone}/purgeCache")
        return
    for url in urls:
        print(f"purge: {url}")
    if not dry_run:
        with ThreadPoolExecutor(WORKERS) as pool:
            list(pool.map(lambda u: api(key, "https://api.bunny.net/purge?" + urllib.parse.urlencode({"url": u})), urls))


def api(key: str | None, url: str) -> None:
    if not key:
        raise SystemExit("deploy: BUNNY_API_KEY is not set, so the CDN can't be purged")
    http("POST", url, key, b"")


def plan(local: dict[str, str], remote: dict[str, str]) -> tuple[list[str], list[str]]:
    changed = [p for p, digest in local.items() if remote.get(p) != digest]
    changed.sort(key=lambda p: (p.endswith(LAST), p))
    removed = sorted(p for p in remote if p not in local)
    return changed, removed


def deploy(build: Path, zone, site: str, dry_run: bool, force: bool = False) -> tuple[list[str], list[str]]:
    local = local_files(build)
    if "index.html" not in local or "404.html" not in local:
        raise SystemExit(f"deploy: {build} doesn't look like a finished build (no index.html/404.html)")
    remote = zone.checksums()
    changed, removed = plan(local, remote)
    print(f"deploy: {len(local)} files in the build, {len(remote)} on the zone; "
          f"{len(changed)} to upload, {len(removed)} to delete")
    for path in changed:
        print(("new:     " if path not in remote else "changed: ") + path)
    for path in removed:
        print("removed: " + path)
    # A wrong --build or a half-empty Build/ would otherwise wipe the site.
    if len(removed) > max(50, len(remote) // 4) and not force and not dry_run:
        raise SystemExit(f"deploy: refusing to delete {len(removed)} of {len(remote)} files; "
                         "re-run with --force if that's intended")
    if not dry_run:
        # Assets first, then pages: two passes keep that order under concurrency.
        first = [p for p in changed if not p.endswith(LAST)]
        last = [p for p in changed if p.endswith(LAST)]
        with ThreadPoolExecutor(WORKERS) as pool:
            for batch in (first, last):
                list(pool.map(lambda p: zone.put(p, (build / p).read_bytes(), local[p]), batch))
        # Delete before purging, or the CDN could re-cache a removed file
        # from storage in between.
        with ThreadPoolExecutor(WORKERS) as pool:
            list(pool.map(zone.delete, removed))
    # New files have nothing cached; only replaced and removed ones need a purge.
    stale = [u for p in changed if p in remote for u in urls_for(p, site)]
    stale += [u for p in removed for u in urls_for(p, site)]
    # A local stand-in zone has no CDN in front of it: just report.
    purge(sorted(set(stale)), dry_run or isinstance(zone, LocalZone))
    return changed, removed


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    parser.add_argument("--build", type=Path, default=ROOT / "Build")
    parser.add_argument("--dry-run", action="store_true", help="print the plan, change nothing")
    parser.add_argument("--against", type=Path, help="use a local folder as the storage zone")
    parser.add_argument("--force", action="store_true", help="allow deleting over a quarter of the zone")
    args = parser.parse_args()
    site = (os.environ.get("SITE_URL") or "https://tim.dev").rstrip("/")
    if args.against:
        zone = LocalZone(args.against)
    else:
        missing = [k for k in ("BUNNY_STORAGE_ZONE", "BUNNY_STORAGE_KEY") if not os.environ.get(k)]
        if missing:
            raise SystemExit("deploy: missing " + ", ".join(missing))
        zone = BunnyZone(os.environ["BUNNY_STORAGE_ZONE"], os.environ["BUNNY_STORAGE_KEY"],
                         os.environ.get("BUNNY_STORAGE_HOST") or "storage.bunnycdn.com")
    deploy(args.build, zone, site, args.dry_run, args.force)


if __name__ == "__main__":
    main()
