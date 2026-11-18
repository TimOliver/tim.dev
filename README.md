# tim.dev

Tim Oliver's blog and portfolio, generated with Swift and Ignite.

Build from the repository root on macOS with Xcode/Swift and Python 3.10+.
The media generator requires Pillow (`python3 -m pip install Pillow`). Use a
virtual environment if your Python installation requires one.

```sh
bash Scripts/build.sh
python3 Scripts/dev-server.py Build 8000
```

The build command generates responsive images, publishes the site, and checks
routes, assets, canonical URLs, image markup, feeds, and the sitemap. Open
[the local preview](http://localhost:8000).

Pushing to `master` deploys: `.github/workflows/deploy.yml` builds the site on a
macOS runner and `Scripts/deploy-bunny.py` syncs `Build/` to Bunny, uploading
only the files that changed and purging only their URLs. The host serves
`404.html` for missing routes.

`Package.resolved` locks Swift dependencies. Responsive `@<width>w` image files
are generated and ignored by Git; keep originals in `Assets/` and run the build
command after a fresh checkout. `media-manifest.json` records their dimensions
and candidates. `swift run --disable-automatic-resolution` is sufficient for
subsequent Swift/CSS/JS-only edits after media has been generated.

Run the regression checks after functional changes:

```sh
python3 -m unittest discover -s Scripts/tests -p '*_test.py'
node --test Scripts/tests/frontend_navigation_test.cjs
swift test --disable-automatic-resolution
python3 Scripts/check-site.py
```

The generated-site check is local and does not crawl historical external
websites. Browser verification is still needed for mobile layout, keyboard
navigation, and integrations such as comments and video playback.

Add posts under `Content/posts/`; use `Content/apps/`, `code/`, `art/`, and
`talks/` for portfolio entries. Before adding new photos, run
`python3 Scripts/strip-exif.py <paths...>` to apply their orientation and remove
metadata. `bash Scripts/install-hooks.sh` installs the same protection for
staged images. Original images remain the full-resolution lightbox targets.
