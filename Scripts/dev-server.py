#!/usr/bin/env python3
"""
A static file server that disables all client caching - useful for iterating on
CSS/JS in the Ignite build output where iOS Safari aggressively re-serves stale
copies from `Last-Modified`-based revalidation.

Serves the directory passed on argv (default: ./Build) on port 8000.

    python3 Scripts/dev-server.py [path] [port]
"""

from __future__ import annotations

import sys
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path


class NoCacheHandler(SimpleHTTPRequestHandler):
    def end_headers(self) -> None:
        self.send_header("Cache-Control", "no-store, no-cache, must-revalidate, max-age=0")
        self.send_header("Pragma", "no-cache")
        self.send_header("Expires", "0")
        super().end_headers()


def main() -> None:
    root = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else Path("Build").resolve()
    port = int(sys.argv[2]) if len(sys.argv) > 2 else 8000
    if not root.is_dir():
        print(f"error: {root} is not a directory", file=sys.stderr)
        sys.exit(1)
    # Use the handler's `directory=` arg instead of chdir - `swift run` wipes
    # and recreates Build/, which would orphan a chdir'd cwd and crash every
    # request with FileNotFoundError on os.getcwd().
    handler = partial(NoCacheHandler, directory=str(root))
    print(f"serving {root} on http://localhost:{port}/ (no-cache)")
    # Threading: image-heavy pages fetch dozens of assets in parallel, and a
    # single stalled connection (iOS Safari over LAN) would wedge a
    # single-threaded server for everyone.
    ThreadingHTTPServer(("", port), handler).serve_forever()


if __name__ == "__main__":
    main()
