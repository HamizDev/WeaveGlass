# WeaveGlass / 璃序 — iOS 26+ WeChat visual tweak.
# Requires a Theos toolchain with an iOS 26 or newer SDK.
TARGET = iphone:clang:latest:26.0
ARCHS = arm64
THEOS_PACKAGE_SCHEME = rootless
INSTALL_TARGET_PROCESSES = WeChat

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = WeaveGlass
WeaveGlass_FILES = Tweak.xm \
  Sources/Core/WGEnvironment.m \
  Sources/Core/WGClassResolver.m \
  Sources/Core/WGConfigCatalog.m \
  Sources/Core/WGConfiguration.m \
  Sources/Appearance/WGGlassEffect.m \
  Sources/Appearance/WGGlassFactory.m \
  Sources/Appearance/WGChatTitleCapsuleView.m \
  Sources/Appearance/WGMessageMergeCardView.m \
  Sources/Appearance/WGTabBarStyler.m \
  Sources/Appearance/WGSegmentedDockView.m \
  Sources/Appearance/WGGlassSupport.m \
  Sources/Appearance/WGHostAppearanceStyler.m \
  Sources/Integration/WGSettingsAccess.m \
  Sources/Settings/WGSettingsController.m \
  Sources/Settings/WGPreviewController.m \
  Sources/Settings/WGClassInspectorController.m \
  Sources/Settings/WGConfigBrowserController.m \
  Sources/Utilities/WGWatermarkController.m
WeaveGlass_CFLAGS = -fobjc-arc -fmodules -Wall -Wextra \
  -ISources/Core -ISources/Appearance -ISources/Settings -ISources/Integration -ISources/Utilities
WeaveGlass_FRAMEWORKS = UIKit Foundation QuartzCore UniformTypeIdentifiers PhotosUI

include $(THEOS_MAKE_PATH)/tweak.mk
