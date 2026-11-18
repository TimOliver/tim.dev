"""Tests for Scripts/deploy-bunny.py against a local stand-in storage zone."""
import contextlib
import importlib.util
import io
import tempfile
import unittest
from pathlib import Path

SCRIPT = Path(__file__).resolve().parent.parent / "deploy-bunny.py"


def load():
    spec = importlib.util.spec_from_file_location("deploy_bunny", SCRIPT)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


class DeployTests(unittest.TestCase):
    def setUp(self):
        self.deploy = load()
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.build = Path(temporary.name) / "Build"
        self.zone_dir = Path(temporary.name) / "zone"
        self.zone = self.deploy.LocalZone(self.zone_dir)
        for path, text in {
            "index.html": "home", "404.html": "missing",
            "2026/11/18/post/index.html": "post", "css/site.abc.css": "css",
            "img/a.jpg": "a", "feed.xml": "feed",
        }.items():
            self.write(path, text)

    def write(self, path, text):
        target = self.build / path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(text)

    def run_deploy(self, dry_run=False):
        out = io.StringIO()
        with contextlib.redirect_stdout(out):
            changed, removed = self.deploy.deploy(self.build, self.zone, "https://tim.dev", dry_run)
        return changed, removed, out.getvalue()

    def test_first_deploy_uploads_everything_and_purges_nothing(self):
        changed, removed, log = self.run_deploy()
        self.assertEqual(len(changed), 6)
        self.assertEqual(removed, [])
        self.assertNotIn("purge:", log)
        self.assertEqual((self.zone_dir / "2026/11/18/post/index.html").read_text(), "post")

    def test_redeploy_of_same_build_does_nothing(self):
        self.run_deploy()
        changed, removed, log = self.run_deploy()
        self.assertEqual((changed, removed), ([], []))
        self.assertNotIn("purge:", log)

    def test_only_changes_upload_pages_last_and_exact_urls_purge(self):
        self.run_deploy()
        self.write("index.html", "home v2")
        self.write("css/site.def.css", "css v2")
        (self.build / "css/site.abc.css").unlink()
        self.write("img/a.jpg", "a v2")
        changed, removed, log = self.run_deploy()
        self.assertEqual(changed, ["css/site.def.css", "img/a.jpg", "index.html"])
        self.assertEqual(removed, ["css/site.abc.css"])
        purged = sorted(line[len("purge: "):] for line in log.splitlines() if line.startswith("purge: "))
        self.assertEqual(purged, ["https://tim.dev/", "https://tim.dev/css/site.abc.css",
                                  "https://tim.dev/img/a.jpg"])
        self.assertFalse((self.zone_dir / "css/site.abc.css").exists())
        self.assertEqual((self.zone_dir / "index.html").read_text(), "home v2")

    def test_dry_run_changes_nothing(self):
        changed, _, _ = self.run_deploy(dry_run=True)
        self.assertEqual(len(changed), 6)
        self.assertFalse(self.zone_dir.exists())

    def test_refuses_an_unfinished_build(self):
        (self.build / "404.html").unlink()
        with self.assertRaises(SystemExit):
            self.run_deploy()

    def test_refuses_to_delete_most_of_the_site_without_force(self):
        for n in range(60):
            self.write(f"img/extra{n}.jpg", str(n))
        self.run_deploy()
        for n in range(60):
            (self.build / f"img/extra{n}.jpg").unlink()
        with self.assertRaises(SystemExit):
            self.run_deploy()
        self.assertTrue((self.zone_dir / "img/extra0.jpg").exists())
        out = io.StringIO()
        with contextlib.redirect_stdout(out):
            self.deploy.deploy(self.build, self.zone, "https://tim.dev", False, force=True)
        self.assertFalse((self.zone_dir / "img/extra0.jpg").exists())

    def test_directory_pages_purge_their_clean_url(self):
        self.assertEqual(self.deploy.urls_for("2026/11/18/post/index.html", "https://tim.dev"),
                         ["https://tim.dev/2026/11/18/post/"])
        self.assertEqual(self.deploy.urls_for("2011/11/20/誕生日/index.html", "https://tim.dev"),
                         ["https://tim.dev/2011/11/20/%E8%AA%95%E7%94%9F%E6%97%A5/"])


if __name__ == "__main__":
    unittest.main()
