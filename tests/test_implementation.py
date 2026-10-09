import re
import subprocess
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

class ExtendedImplementation(unittest.TestCase):
    def text(self, path):
        return (ROOT / path).read_text(encoding='utf-8')

    def test_all_compile_files_are_in_makefile(self):
        make = self.text('Makefile')
        section = make.split('WeaveGlass_FILES = ', 1)[1].split('WeaveGlass_CFLAGS', 1)[0]
        declared = set(re.findall(r'[\w/]+\.(?:m|xm)', section))
        actual = {'Tweak.xm'} | {str(p.relative_to(ROOT)) for p in (ROOT / 'Sources').rglob('*.m')}
        self.assertEqual(actual, declared)

    def test_all_local_headers_resolve(self):
        paths = list((ROOT / 'Sources').rglob('*.m')) + [ROOT / 'Tweak.xm']
        for source in paths:
            text = source.read_text(encoding='utf-8')
            for name in re.findall(r'^#import "([^"]+)"', text, re.M):
                candidates = [source.parent / name, ROOT / name]
                candidates += [folder / name for folder in (ROOT / 'Sources').iterdir() if folder.is_dir()]
                self.assertTrue(any(p.exists() for p in candidates), f'{source.name}: {name}')

    def test_safe_defaults(self):
        config = self.text('Sources/Core/WGConfiguration.m')
        for name in ['WGPreferenceCapsuleDock', 'WGPreferenceChatComposer',
                     'WGPreferenceHomeSearch', 'WGPreferenceNavigationTint', 'WGPreferenceNativeGlass']:
            self.assertIn(name + ': @NO', config)
        self.assertIn('WGPreferenceEnabled: @YES', config)

    def test_only_public_classes_hooked(self):
        tweak = self.text('Tweak.xm')
        self.assertEqual(re.findall(r'%hook\s+(\w+)', tweak), ['UIViewController', 'UITabBarController'])
        self.assertIn('WGEnvironment shouldActivate', tweak)

    def test_settings_without_standard_tab_bar(self):
        access = self.text('Sources/Integration/WGSettingsAccess.m')
        self.assertIn('numberOfTouchesRequired = 3', access)
        self.assertIn('numberOfTapsRequired = 3', access)
        self.assertIn('kWGWindowGestureKey', access)
        tweak = self.text('Tweak.xm')
        self.assertIn('attachToWindow:self.view.window', tweak)

    def test_dynamic_runtime_guard(self):
        host = self.text('Sources/Appearance/WGHostAppearanceStyler.m')
        self.assertIn('WGClassResolver controller:', host)
        self.assertIn('i < 350', host)
        self.assertIn('restoreView:', host)
        self.assertIn('WGPreferenceChatComposer', host)
        self.assertIn('WGPreferenceHomeSearch', host)

    def test_capsule_has_restore_and_badge(self):
        dock = self.text('Sources/Appearance/WGSegmentedDockView.m')
        bar = self.text('Sources/Appearance/WGTabBarStyler.m')
        self.assertIn('selectTab:', dock)
        self.assertIn('badgeValue', dock)
        self.assertIn('UIAccessibilityTraitSelected', dock)
        self.assertIn('restoreNativeTabButtons:', bar)
        self.assertIn('WGPreferenceCapsuleDock', bar)
        self.assertIn('snapshots.count != bar.items.count', bar)

    def test_watermark_private_and_bounded(self):
        src = self.text('Sources/Utilities/WGWatermarkController.m')
        self.assertIn('PHPickerViewController', src)
        self.assertIn('UIGraphicsImageRenderer', src)
        self.assertIn('4096.0', src)
        self.assertIn('UIActivityViewController', src)
        self.assertNotIn('upload', src.lower())

    def test_import_size_limit_and_reset(self):
        settings = self.text('Sources/Settings/WGSettingsController.m')
        self.assertIn('2 * 1024 * 1024', settings)
        self.assertIn('resetActiveAppearancePreferences', settings)

    def test_version_alignment(self):
        self.assertIn('0.3.0', self.text('control'))
        self.assertIn('0.3.0', self.text('Sources/Core/WGEnvironment.m'))
        self.assertIn('0.3.0', self.text('Sources/Settings/WGSettingsController.m'))

if __name__ == '__main__':
    unittest.main()
