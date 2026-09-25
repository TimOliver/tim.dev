"""Regressions for responsive media generation and the upload metadata hook."""

import contextlib
import hashlib
import importlib.util
import io
import json
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

from PIL import Image, ImageCms, PngImagePlugin


SCRIPTS = Path(__file__).resolve().parents[1]


def load_script(name):
    spec = importlib.util.spec_from_file_location(name.replace("-", "_"), SCRIPTS / f"{name}.py")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


ICC = ImageCms.ImageCmsProfile(ImageCms.createProfile("sRGB")).tobytes()


class MediaPipelineTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.posts = self.root / "Assets/img/posts"
        self.posts.mkdir(parents=True)
        self.media = load_script("build-media")
        self.media.REPO_ROOT = self.root
        self.media.ASSETS = self.root / "Assets"
        self.media.MANIFEST = self.root / "media-manifest.json"

    def build(self):
        with contextlib.redirect_stdout(io.StringIO()):
            self.media.main()
        return json.loads(self.media.MANIFEST.read_text())

    def test_jpeg_candidates_have_real_dimensions_profiles_and_preserve_original(self):
        source = self.posts / "photo.jpg"
        Image.effect_noise((1000, 600), 70).convert("RGB").save(source, quality=95, icc_profile=ICC)
        before = digest(source)
        entry = self.build()["/img/posts/photo.jpg"]
        self.assertEqual((entry["width"], entry["height"]), (1000, 600))
        self.assertEqual(digest(source), before)
        self.assertTrue(entry["lqip"].startswith("data:image/png;base64,"))
        self.assertEqual([c.split()[1] for c in entry["srcset"].split(", ")], ["400w", "800w", "1000w"])
        for candidate in entry["srcset"].split(", ")[:-1]:
            url, width = candidate.split()
            path = self.media.ASSETS / url.lstrip("/")
            with Image.open(path) as image:
                self.assertEqual(image.width, int(width[:-1]))
                self.assertEqual(image.info["icc_profile"], ICC)
                self.assertFalse(image.getexif())
            self.assertLess(path.stat().st_size, source.stat().st_size)

    def test_gif_and_apng_keep_original_animation(self):
        frames = [Image.new("RGBA", (900, 500), color) for color in ("red", "blue")]
        for extension in ("gif", "png"):
            source = self.posts / f"animation.{extension}"
            frames[0].save(source, save_all=True, append_images=frames[1:], duration=[70, 130], loop=0)
            before = digest(source)
            entry = self.build()[f"/img/posts/animation.{extension}"]
            self.assertEqual(entry["srcset"], f"/img/posts/animation.{extension} 900w")
            self.assertEqual((entry["width"], entry["height"]), (900, 500))
            self.assertEqual(digest(source), before)
            self.assertFalse(list(self.posts.glob(f"animation@*w.{extension}")))
            with Image.open(source) as image:
                self.assertEqual(image.n_frames, 2)

    def test_png_variants_preserve_alpha(self):
        source = self.posts / "screen.png"
        image = Image.effect_noise((900, 500), 70).convert("RGBA")
        image.putpixel((0, 0), (0, 0, 0, 0))
        image.save(source, icc_profile=ICC)
        self.build()
        with Image.open(self.posts / "screen@400w.png") as resized:
            self.assertEqual(resized.mode, "RGBA")
            self.assertLess(resized.getpixel((0, 0))[3], 255)
            self.assertEqual(resized.info["icc_profile"], ICC)

    def test_rebuild_reuses_variants_and_prunes_after_replacing_source(self):
        source = self.posts / "photo.jpg"
        Image.effect_noise((1000, 600), 70).convert("RGB").save(source, quality=95)
        first = self.build()
        variant = self.posts / "photo@800w.jpg"
        modified = variant.stat().st_mtime_ns
        self.assertEqual(self.build(), first)
        self.assertEqual(variant.stat().st_mtime_ns, modified)
        Image.new("RGB", (300, 150), "red").save(source)
        entry = self.build()["/img/posts/photo.jpg"]
        self.assertEqual(entry["srcset"], "/img/posts/photo.jpg 300w")
        self.assertFalse(list(self.posts.glob("photo@*w.jpg")))
        self.assertTrue(source.exists())

    def test_manifest_matches_exif_oriented_original_without_modifying_it(self):
        source = self.posts / "portrait.jpg"
        image = Image.new("RGB", (1000, 600), "red")
        exif = image.getexif()
        exif[274] = 6
        image.save(source, exif=exif)
        before = digest(source)
        entry = self.build()["/img/posts/portrait.jpg"]
        self.assertEqual((entry["width"], entry["height"]), (600, 1000))
        self.assertTrue(entry["srcset"].endswith("portrait.jpg 600w"))
        self.assertEqual(digest(source), before)

    def test_corrupt_source_does_not_replace_previous_manifest(self):
        self.media.MANIFEST.write_text('{"previous": true}\n')
        (self.posts / "broken.jpg").write_bytes(b"not an image")
        with self.assertRaises(OSError):
            self.build()
        self.assertEqual(self.media.MANIFEST.read_text(), '{"previous": true}\n')


class StripExifTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.strip = load_script("strip-exif")

    def test_jpeg_rotation_preserves_colour_and_encoder_settings(self):
        source = self.root / "portrait.jpg"
        image = Image.new("RGB", (80, 40), "red")
        image.paste("blue", (0, 20, 80, 40))
        exif = image.getexif()
        exif[274] = 6
        exif[270] = "private metadata"
        image.save(source, exif=exif, quality=91, subsampling=0, progressive=True, icc_profile=ICC)
        with Image.open(source) as before:
            tables = before.quantization
        self.assertTrue(self.strip.strip(source))
        with Image.open(source) as after:
            self.assertEqual(after.size, (40, 80))
            self.assertFalse(after.getexif())
            self.assertEqual(after.info["icc_profile"], ICC)
            self.assertTrue(after.info["progressive"])
            self.assertEqual(after.quantization, tables)
            self.assertGreater(after.getpixel((5, 5))[2], 200)
            self.assertGreater(after.getpixel((35, 5))[0], 200)
        before = digest(source)
        self.assertFalse(self.strip.strip(source))
        self.assertEqual(digest(source), before)

    def test_png_strips_text_exif_and_keeps_palette_transparency(self):
        source = self.root / "transparent.png"
        image = Image.new("P", (80, 40), 0)
        image.putpalette([0, 0, 0, 255, 0, 0] + [0] * 762)
        exif = image.getexif()
        exif[274] = 6
        info = PngImagePlugin.PngInfo()
        info.add_itxt("XML:com.adobe.xmp", "private metadata")
        image.save(source, exif=exif, pnginfo=info, transparency=0, icc_profile=ICC)
        self.assertTrue(self.strip.strip(source))
        with Image.open(source) as after:
            self.assertEqual(after.size, (40, 80))
            self.assertFalse(after.getexif())
            self.assertFalse(after.text)
            self.assertEqual(after.info["icc_profile"], ICC)
            self.assertEqual(after.convert("RGBA").getpixel((0, 0))[3], 0)

    def test_failed_save_leaves_original_unchanged(self):
        source = self.root / "photo.jpg"
        image = Image.new("RGB", (80, 40), "red")
        exif = image.getexif()
        exif[270] = "private metadata"
        image.save(source, exif=exif)
        before = digest(source)
        with patch.object(Image.Image, "save", side_effect=OSError("disk full")):
            with self.assertRaises(OSError):
                self.strip.strip(source)
        self.assertEqual(digest(source), before)
        self.assertFalse(list(self.root.glob(".strip-exif-*")))

    def test_cli_reports_failure_for_corrupt_and_missing_images(self):
        broken = self.root / "broken.jpg"
        broken.write_bytes(b"not an image")
        for source in (broken, self.root / "missing.jpg"):
            result = subprocess.run([sys.executable, str(SCRIPTS / "strip-exif.py"), str(source)], capture_output=True)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn(b"error processing", result.stderr)

    def test_hook_blocks_bad_image_including_newline_filename(self):
        subprocess.run(["git", "init", "-q", str(self.root)], check=True)
        (self.root / "Scripts").mkdir()
        shutil.copy(SCRIPTS / "strip-exif.py", self.root / "Scripts")
        empty = subprocess.run(["bash", str(SCRIPTS / "hooks/pre-commit")], cwd=self.root, capture_output=True)
        self.assertEqual(empty.returncode, 0, empty.stderr)
        asset = self.root / "Assets/bad image\nname.jpg"
        asset.parent.mkdir()
        asset.write_bytes(b"not an image")
        subprocess.run(["git", "add", "Assets"], cwd=self.root, check=True)
        result = subprocess.run(["bash", str(SCRIPTS / "hooks/pre-commit")], cwd=self.root, capture_output=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn(b"stripping EXIF from 1 staged image", result.stdout)
        self.assertIn(b"error processing", result.stderr)


if __name__ == "__main__":
    unittest.main()
