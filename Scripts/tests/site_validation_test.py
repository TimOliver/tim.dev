"""Small generated-site fixtures for RSS and CSS destination validation."""

from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


CHECK_SITE = Path(__file__).resolve().parents[1] / "check-site.py"
POST_URL = "https://tim.dev/2024/01/01/example/"


class SiteValidationTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        for relative, canonical in (("index.html", "https://tim.dev/"),
                                    ("2024/01/01/example/index.html", POST_URL)):
            page = self.root / relative
            page.parent.mkdir(parents=True, exist_ok=True)
            page.write_text(
                f'<html><head><link rel="canonical" href="{canonical}">'
                f'<meta property="og:url" content="{canonical}">'
                '<link rel="stylesheet" href="/css/site.css"></head><body>Example</body></html>'
            )
        (self.root / "css").mkdir()
        (self.root / "css/site.css").write_text(
            'body { background-image: url("../img/background.svg"); }'
        )
        (self.root / "img").mkdir()
        (self.root / "img/background.svg").write_text('<svg xmlns="http://www.w3.org/2000/svg"/>')
        (self.root / "sitemap.xml").write_text(
            '<urlset><url><loc>https://tim.dev/</loc></url>'
            f'<url><loc>{POST_URL}</loc></url></urlset>'
        )
        for name in ("feed", "feed-dev", "feed-icomics", "feed-oss", "feed-personal"):
            (self.root / f"{name}.xml").write_text(
                f'<rss><channel><item><link>{POST_URL}</link><guid>{POST_URL}</guid>'
                '<description>Example</description></item></channel></rss>'
            )

    def validate(self):
        return subprocess.run([sys.executable, str(CHECK_SITE), str(self.root)],
                              capture_output=True, text=True)

    def test_valid_fixture_succeeds(self):
        result = self.validate()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("0 error(s)", result.stdout)

    def test_missing_feed_item_destination_fails(self):
        feed = self.root / "feed.xml"
        missing = "https://tim.dev/2024/01/01/missing/"
        feed.write_text(feed.read_text().replace(POST_URL, missing))
        result = self.validate()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn(f"missing feed item destination: {missing}", result.stderr)
        self.assertIn("1 error(s)", result.stdout)

    def test_missing_relative_css_asset_fails(self):
        (self.root / "img/background.svg").unlink()
        result = self.validate()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("missing CSS asset: ../img/background.svg", result.stderr)
        self.assertIn("1 error(s)", result.stdout)

    def test_sitemap_url_without_trailing_slash_fails(self):
        sitemap = self.root / "sitemap.xml"
        bare = POST_URL.rstrip("/")
        sitemap.write_text(sitemap.read_text().replace(POST_URL, bare))
        result = self.validate()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn(f"sitemap URL lacks the canonical trailing slash: {bare}", result.stderr)
        self.assertIn("1 error(s)", result.stdout)

    def test_lightbox_trigger_without_script_fails(self):
        page = self.root / "2024/01/01/example/index.html"
        page.write_text(page.read_text().replace(
            "Example", '<a href="/css/site.css" data-lightbox>Example</a>'))
        result = self.validate()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("uses data-lightbox but does not load /js/lightbox3.umd.js", result.stderr)
        self.assertIn("1 error(s)", result.stdout)

    def test_dotfile_in_build_fails(self):
        (self.root / "img/.DS_Store").write_bytes(b"\x00")
        result = self.validate()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("img/.DS_Store: dotfile in the build output", result.stderr)
        self.assertIn("1 error(s)", result.stdout)


if __name__ == "__main__":
    unittest.main()
