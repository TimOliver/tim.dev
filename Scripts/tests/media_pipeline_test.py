"""Regressions for responsive media generation and the upload metadata hook."""

import contextlib
import hashlib
import importlib.util
import io
import time
import os
import json
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

from PIL import Image, ImageCms, ImageOps, PngImagePlugin


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
        self.media.CACHE = self.root / ".media-cache.json"

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

    def test_variants_follow_source_bytes_not_modification_times(self):
        source = self.posts / "photo.jpg"
        Image.effect_noise((1000, 600), 70).convert("RGB").save(source, quality=95)
        self.build()
        variant = self.posts / "photo@800w.jpg"
        built = variant.read_bytes()
        modified = variant.stat().st_mtime_ns
        # A fresh checkout: every source looks newer, but nothing changed.
        os.utime(source, (time.time() + 60, time.time() + 60))
        self.build()
        self.assertEqual(variant.stat().st_mtime_ns, modified)
        # A replacement dated in the past is still a new picture.
        Image.new("RGB", (1000, 600), "blue").save(source, quality=95)
        os.utime(source, (1, 1))
        self.build()
        self.assertNotEqual(variant.read_bytes(), built)
        with Image.open(variant) as image:
            self.assertEqual(image.convert("RGB").getpixel((10, 10))[2] > 200, True)

    def test_rejected_variants_are_remembered_not_re_encoded(self):
        # Two-colour stripes as a palette PNG: tiny on disk, but every
        # antialiased downscale comes out bigger, so all are rejected.
        source = self.posts / "flat.png"
        stripes = Image.new("P", (1000, 600), 0)
        stripes.putpalette([255, 0, 0, 255, 255, 255])
        for x in range(0, 1000, 2):
            stripes.paste(1, (x, 0, x + 1, 600))
        stripes.save(source, optimize=True)
        first = self.build()["/img/posts/flat.png"]
        self.assertEqual(first["srcset"], "/img/posts/flat.png 1000w")
        widths = []
        real = self.media.encode_variant
        def spy(src, im, width, *rest):
            widths.append(width)
            return real(src, im, width, *rest)
        with patch.object(self.media, "encode_variant", side_effect=spy):
            self.assertEqual(self.build()["/img/posts/flat.png"], first)
        self.assertEqual(widths, [])

    def test_manifest_matches_exif_oriented_original_without_modifying_it(self):
        source = self.posts / "portrait.jpg"
        image = Image.new("RGB", (1000, 600), "red")
        exif = image.getexif()
        exif[274] = 6
        image.save(source, exif=exif)
        before = digest(source)
        entry = self.build()["/img/posts/portrait.jpg"]
        self.assertEqual((entry["width"], entry["height"]), (600, 1000))
        top, width = entry["srcset"].split(", ")[-1].split()
        self.assertEqual(width, "600w")
        with Image.open(self.media.ASSETS / top.lstrip("/")) as candidate:
            self.assertEqual(ImageOps.exif_transpose(candidate).size, (600, 1000))
        self.assertEqual(digest(source), before)

    def test_heavy_original_gets_a_full_width_reencode(self):
        source = self.posts / "render.jpg"
        Image.effect_noise((1032, 600), 60).convert("RGB").save(source, quality=100, subsampling=0)
        before = digest(source)
        entry = self.build()["/img/posts/render.jpg"]
        top, width = entry["srcset"].split(", ")[-1].split()
        self.assertEqual((top, width), ("/img/posts/render@1032w.jpg", "1032w"))
        self.assertLess((self.posts / "render@1032w.jpg").stat().st_size, source.stat().st_size * 0.8)
        self.assertEqual(digest(source), before)

    def test_opaque_png_photo_gets_jpeg_variants_but_flat_png_stays_png(self):
        photo = self.posts / "photo.png"
        Image.effect_noise((900, 500), 60).convert("RGB").save(photo)
        flat = self.posts / "flat.png"
        image = Image.new("RGB", (900, 500), "white")
        for x in range(0, 900, 60):
            image.paste("black", (x, 0, x + 2, 500))
        image.save(flat)
        manifest = self.build()
        self.assertIn("/img/posts/photo@400w.jpg 400w", manifest["/img/posts/photo.png"]["srcset"])
        self.assertFalse((self.posts / "photo@400w.png").exists())
        self.assertIn("/img/posts/flat@400w.png 400w", manifest["/img/posts/flat.png"]["srcset"])
        self.assertFalse((self.posts / "flat@400w.jpg").exists())

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

    def test_jpeg_strips_photoshop_iptc_block(self):
        source = self.root / "from-instagram.jpg"
        Image.new("RGB", (40, 40), "red").save(source)
        # Splice an APP13 Photoshop/IPTC segment (as Facebook/Instagram
        # downloads carry) in after SOI.
        iptc = b"\x1c\x02\x67\x00\x0bFBMD-private"
        irb = b"8BIM\x04\x04\x00\x00" + len(iptc).to_bytes(4, "big") + iptc + b"\x00"
        payload = b"Photoshop 3.0\x00" + irb
        data = source.read_bytes()
        source.write_bytes(data[:2] + b"\xff\xed" + (len(payload) + 2).to_bytes(2, "big") + payload + data[2:])
        with Image.open(source) as before:
            self.assertIn("photoshop", before.info)
        self.assertTrue(self.strip.strip(source))
        with Image.open(source) as after:
            self.assertNotIn("photoshop", after.info)
        self.assertNotIn(b"FBMD", source.read_bytes())

    def test_sweep_skips_generated_variants(self):
        self.assertTrue(self.strip.VARIANT.search("photo@800w.jpg"))
        self.assertFalse(self.strip.VARIANT.search("photo.jpg"))
        self.assertFalse(self.strip.VARIANT.search("me@home.jpg"))

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

    def test_hook_strips_renamed_and_modified_image(self):
        subprocess.run(["git", "init", "-q", str(self.root)], check=True)
        git = lambda *a: subprocess.run(["git", "-c", "user.name=t", "-c", "user.email=t@t", *a], cwd=self.root, check=True, capture_output=True)
        (self.root / "Scripts").mkdir()
        shutil.copy(SCRIPTS / "strip-exif.py", self.root / "Scripts")
        old = self.root / "Assets/old.jpg"
        old.parent.mkdir()
        Image.new("RGB", (64, 64), "red").save(old, quality=95)
        git("add", "Assets")
        git("commit", "-q", "-m", "clean", "--no-verify")
        new = self.root / "Assets/new.jpg"
        old.rename(new)
        image = Image.new("RGB", (64, 64), "red")
        image.putpixel((0, 0), (250, 0, 0))
        exif = image.getexif()
        exif[270] = "private metadata"
        image.save(new, exif=exif, quality=95)
        git("add", "-A", "Assets")
        status = subprocess.run(["git", "diff", "--cached", "--name-status", "-M"], cwd=self.root, capture_output=True, text=True).stdout
        self.assertTrue(status.startswith("R"), status)
        result = subprocess.run(["bash", str(SCRIPTS / "hooks/pre-commit")], cwd=self.root, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        with Image.open(new) as after:
            self.assertFalse(after.getexif())


if __name__ == "__main__":
    unittest.main()
