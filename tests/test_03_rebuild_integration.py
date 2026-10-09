"""Static assertions only: these are not equivalent to iOS compilation or device testing."""
import re
import unittest
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]

def read(path):
    return (ROOT / path).read_text(encoding='utf-8-sig')

class RebuildIntegration(unittest.TestCase):
    def test_original_rebuild_spec_is_not_published_or_compiled(self):
        self.assertFalse((ROOT / 'reference/rebuild-spec/WCGlass_REBUILD_SPEC.md').exists())
        make = read('Makefile')
        for prohibited in ['WGEnhancementHooks.xm','WGChatHooks.xm','WGAccountState.m','WCGlass-rebuild-extracted']:
            self.assertNotIn(prohibited, make)

    def test_old_new_key_coverage(self):
        newkeys = re.findall(r'^#define kWG_[A-Z0-9_]+\s+@"([^"]+)"', read('reference/rebuild-spec/Sources/Core/WGKeys.h'), re.M)
        legacy = read('Sources/Core/WGConfigCatalog.m')
        self.assertEqual(len(newkeys), 1050)
        self.assertEqual(len(set(newkeys)), 1050)
        self.assertEqual(sum(f'@"{key}"' in legacy for key in newkeys), 1048)
        self.assertEqual(set(k for k in newkeys if f'@"{k}"' not in legacy),
                         {'com.wcglass.hot-update-pipeline-did-settle', 'com.wclg.content-corners.changed'})

    def test_new_flags_are_wired_and_default_off(self):
        config = read('Sources/Core/WGConfiguration.m')
        ui = read('Sources/Settings/WGSettingsController.m')
        for flag in ['WGPreferenceMorphDock','WGPreferenceChatTitleCapsule','WGPreferenceAutoClassMatch']:
            self.assertIn(flag + ': @NO', config)
            self.assertIn(flag, ui)
            self.assertIn(flag, read('Sources/Core/WGConfiguration.h'))
        self.assertIn('com.weaveglass.settings', config)
        self.assertNotIn('standardUserDefaults', config)

    def test_resolver_is_existence_check_only(self):
        src = read('Sources/Core/WGClassResolver.m')
        self.assertIn('class_getSuperclass', src)
        self.assertIn('NSClassFromString', src)
        self.assertNotIn('objc_msgSend', src)
        host = read('Sources/Appearance/WGHostAppearanceStyler.m')
        self.assertIn('fallbackCandidates:', host)
        self.assertIn('WGPreferenceAutoClassMatch', host)
        self.assertIn('kWGTitleBackup', host)
        self.assertIn('restoreTitleItem:', host)
        self.assertIn('if (item.titleView != nil) return;', host)

    def test_morph_is_reversible_reduced_motion_safe(self):
        dock = read('Sources/Appearance/WGSegmentedDockView.m')
        tab = read('Sources/Appearance/WGTabBarStyler.m')
        self.assertIn('UIAccessibilityIsReduceMotionEnabled()', dock)
        self.assertIn('usingSpringWithDamping:', dock)
        self.assertIn('WGPreferenceMorphDock', tab)
        self.assertIn('restoreNativeTabButtons:', tab)
        self.assertIn('snapshots.count != bar.items.count', tab)

    def test_message_merge_card_has_no_host_access(self):
        card = read('Sources/Appearance/WGMessageMergeCardView.m')
        self.assertIn('initWithMessages:', card)
        self.assertIn('MIN(messages.count, 20)', card)
        for forbidden in ['CMessageMgr','messageDB','WCDB','MSHook','%hook']:
            self.assertNotIn(forbidden,card)

    def test_watermark_interactive_geometry_and_local_only(self):
        src = read('Sources/Utilities/WGWatermarkController.m')
        for token in ['UIPanGestureRecognizer', 'UIPinchGestureRecognizer', 'normalizedCenter',
                      'imageRectInPreview', 'renderWatermark', '4096.0', 'UIGraphicsImageRenderer',
                      'PHPickerViewController', 'UIActivityViewController']:
            self.assertIn(token, src)
        for token in ['uploadTask','NSURLSession','PHPhotoLibrary requestAuthorization']:
            self.assertNotIn(token,src)

    def test_interface_changes_are_aligned(self):
        settings = read('Sources/Settings/WGSettingsController.m')
        self.assertIn('section == 0 ? 9 : section == 1 ? 5', settings)
        self.assertIn('if (path.row == 4)', settings)
        self.assertIn('WeaveGlass 0.3.0 Alpha', settings)
        self.assertIn('Name: WeaveGlass', read('control'))
        self.assertIn('Version: 0.3.0', read('control'))
        self.assertIn('0.3.0', read('Sources/Core/WGEnvironment.m'))

if __name__ == '__main__': unittest.main()
