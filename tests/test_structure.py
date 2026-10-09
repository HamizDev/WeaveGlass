import plistlib
import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


class ProjectTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.config = (ROOT / 'reference/CONFIG_KEYS.md').read_text(encoding='utf-8-sig')

    def test_original_handoff_catalog_size_and_order(self):
        blocks = re.findall(r'^## (.+?)（(\d+)）\s*\n```\n(.*?)\n```', self.config, re.M | re.S)
        self.assertEqual(len(blocks), 14)
        keys = []
        for group, count, body in blocks:
            lines = [s.strip() for s in body.splitlines() if s.strip()]
            self.assertEqual(len(lines), int(count), group)
            keys.extend(lines)
        self.assertEqual(len(keys), 1067)
        self.assertEqual(len(set(keys)), 1067)
        catalog = (ROOT / 'Sources/Core/WGConfigCatalog.m').read_text()
        for key in keys:
            self.assertIn('@"' + key + '"', catalog, key)

    def test_original_handoff_has_all_per_class_headers(self):
        rows = (ROOT / 'reference/CLASS_INDEX.md').read_text(encoding='utf-8-sig')
        self.assertIn('共 291 个类', rows)
        # The original 291 reverse-engineered headers are retained in the private source handoff,
        # but deliberately not distributed by this CI repository.
        self.assertTrue((ROOT / 'reference/CLASS_INDEX.md').is_file())

    def test_filter_bundle(self):
        data = plistlib.loads((ROOT / 'WeaveGlass.plist').read_bytes())
        self.assertEqual(data['Filter']['Bundles'], ['com.tencent.xin'])

    def test_target_package(self):
        make = (ROOT / 'Makefile').read_text()
        self.assertIn('TARGET = iphone:clang:latest:26.0', make)
        self.assertIn('THEOS_PACKAGE_SCHEME = rootless', make)
        self.assertIn('ARCHS = arm64', make)
        control = (ROOT / 'control').read_text()
        self.assertIn('Package: com.weaveglass.tweak', control)
        self.assertIn('firmware (>= 26.0)', control)
        self.assertIn('TWEAK_NAME = WeaveGlass', make)

    def test_compile_source_paths_exist(self):
        make = (ROOT / 'Makefile').read_text()
        files = re.search(r'^WeaveGlass_FILES\s*=\s*(.*?)(?=\nWeaveGlass_CFLAGS)', make, re.S | re.M).group(1)
        paths = re.findall(r'([\w/]+\.(?:m|xm))', files)
        self.assertGreaterEqual(len(paths), 14)
        for path in paths:
            self.assertTrue((ROOT / path).is_file(), path)

    def test_runtime_gates_and_native_material(self):
        env = (ROOT / 'Sources/Core/WGEnvironment.m').read_text()
        self.assertIn('majorVersion >= 26', env)
        self.assertIn('com.tencent.xin', env)
        glass = (ROOT / 'Sources/Appearance/WGGlassEffect.m').read_text()
        self.assertIn('NSClassFromString(@"UIGlassEffect")', glass)
        self.assertIn('effectWithStyle:', glass)
        tweak = (ROOT / 'Tweak.xm').read_text()
        self.assertIn('%hook UITabBarController', tweak)
        self.assertIn('[WGEnvironment shouldActivate]', tweak)


if __name__ == '__main__':
    unittest.main()
