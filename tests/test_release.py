import hashlib
import importlib.util
from pathlib import Path
import shutil
import sys
import tempfile
import unittest
import zipfile

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tools'))
import build_package as build
import upload_curseforge as upload

class ReleaseTests(unittest.TestCase):
    def test_reproducible_installable_package(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp) / 'arbitrary-checkout-name'
            root.mkdir()
            for name in build.RUNTIME:
                dest = root / name
                dest.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(ROOT / name, dest)
            (root / '.env').write_text('MUST_NOT_BE_PACKAGED')
            (root / 'personal.lua').write_text('MUST_NOT_BE_PACKAGED')
            v, first, checksum, count = build.build(root, Path(tmp) / 'first', 'v1.7.0')
            _, second, _, _ = build.build(root, Path(tmp) / 'second')
            self.assertEqual(first.read_bytes(), second.read_bytes())
            self.assertEqual(checksum.read_text().split()[0], hashlib.sha256(first.read_bytes()).hexdigest())
            with zipfile.ZipFile(first) as package:
                self.assertEqual(set(package.namelist()), {'GabbaGuildCraft/' + p for p in build.RUNTIME})
                self.assertIn('GabbaGuildCraft/Assets/Minimap.tga', package.namelist())
            with self.assertRaises(ValueError):
                build.build(root, Path(tmp) / 'bad', 'v9.0.0')
            (root / 'UI.lua').unlink()
            (root / 'UI.lua').symlink_to(ROOT / 'UI.lua')
            with self.assertRaises(ValueError):
                build.build(root, Path(tmp) / 'unsafe')

    def test_client_versions_and_metadata(self):
        versions = [{'name': '1.15.9', 'id': 101}, {'name': '2.5.6', 'id': 202}]
        data = upload.metadata(ROOT, 'v1.7.0', 'Changes', versions)
        self.assertEqual(data['gameVersions'], [101, 202])
        self.assertEqual(data['releaseType'], 'release')
        self.assertEqual(data['changelog'], 'Changes')
        for invalid in [versions[:1], versions + versions[:1], [{'name': '1.15.9', 'id': 'bad'}]]:
            with self.assertRaises(ValueError):
                upload.metadata(ROOT, 'v1.7.0', '', invalid)
        with self.assertRaises(ValueError):
            upload.metadata(ROOT, 'v1.6.0', '', versions)

    def test_icon_is_uncompressed_power_of_two_tga(self):
        data = (ROOT / 'Assets/Minimap.tga').read_bytes()
        self.assertEqual(data[2], 2)  # true color, uncompressed
        self.assertEqual(int.from_bytes(data[12:14], 'little'), 64)
        self.assertEqual(int.from_bytes(data[14:16], 'little'), 64)
        self.assertIn(data[16], (24, 32))

if __name__ == '__main__':
    unittest.main()
