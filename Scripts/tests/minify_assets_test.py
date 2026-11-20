"""Tests for Scripts/minify-assets.py on a stand-in Build/ folder."""
import contextlib
import importlib.util
import io
import tempfile
import unittest
from pathlib import Path

SCRIPT = Path(__file__).resolve().parent.parent / "minify-assets.py"


def load():
    spec = importlib.util.spec_from_file_location("minify_assets", SCRIPT)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


CSS = """/* A comment the browser doesn't need. */
.card {
    color: var(--text);   /* trailing comment */
    content: "/* not a comment */";
    width: calc(100% - 2 * var(--pad));
}
"""

JS = """// A comment the browser doesn't need.
(function () {
    var url = 'https://tim.dev/'; // the // inside the string must survive
    var re = /^(auto|light|dark)$/;
    return url + re.source;
})();
"""


class MinifyAssetsTests(unittest.TestCase):
    def setUp(self):
        self.minify = load()
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.build = Path(temporary.name) / "Build"
        self.files = {
            "css/site.css": CSS, "css/site.1a2b3c4d.css": CSS,
            "js/site.js": JS, "js/site.5e6f7a8b.js": JS,
            "css/lightbox3.css": CSS, "js/lightbox3.umd.js": JS,
            "js/embla-carousel.umd.js": JS, "js/lite-yt-embed.js": JS,
        }
        for path, text in self.files.items():
            target = self.build / path
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text(text, encoding="utf-8")

    def run_minify(self):
        with contextlib.redirect_stdout(io.StringIO()):
            return self.minify.main(self.build)

    def read(self, path):
        return (self.build / path).read_text(encoding="utf-8")

    def test_minifies_own_files_and_their_hashed_copies(self):
        self.assertEqual(self.run_minify(), 0)
        for path in ("css/site.css", "css/site.1a2b3c4d.css"):
            css = self.read(path)
            self.assertNotIn("A comment", css)
            self.assertNotIn("trailing comment", css)
            self.assertIn('"/* not a comment */"', css)
            self.assertIn("calc(100% - 2 * var(--pad))", css)
            self.assertLess(len(css), len(CSS))
        for path in ("js/site.js", "js/site.5e6f7a8b.js"):
            js = self.read(path)
            self.assertNotIn("A comment", js)
            self.assertIn("'https://tim.dev/'", js)
            self.assertIn("/^(auto|light|dark)$/", js)
            self.assertLess(len(js), len(JS))

    def test_leaves_vendored_files_untouched(self):
        self.run_minify()
        for path in ("css/lightbox3.css", "js/lightbox3.umd.js",
                     "js/embla-carousel.umd.js", "js/lite-yt-embed.js"):
            self.assertEqual(self.read(path), self.files[path], path)

    def test_is_idempotent(self):
        self.run_minify()
        once = self.read("css/site.css"), self.read("js/site.js")
        self.run_minify()
        self.assertEqual((self.read("css/site.css"), self.read("js/site.js")), once)

    def test_fails_on_an_empty_build(self):
        empty = self.build.parent / "Empty"
        (empty / "css").mkdir(parents=True)
        with contextlib.redirect_stderr(io.StringIO()):
            self.assertEqual(self.minify.main(empty), 1)


if __name__ == "__main__":
    unittest.main()
