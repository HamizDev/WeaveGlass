#import <UIKit/UIKit.h>
#import "Sources/Core/WGEnvironment.h"
#import "Sources/Appearance/WGTabBarStyler.h"
#import "Sources/Appearance/WGHostAppearanceStyler.h"
#import "Sources/Integration/WGSettingsAccess.h"

// Public UIKit hook surfaces only. Private WeChat classes are matched at runtime,
// but never hooked by guessed selectors. All behavior is restricted to com.tencent.xin.
%hook UIViewController
- (void)viewDidAppear:(BOOL)animated {
    %orig;
    if (![WGEnvironment shouldActivate]) return;
    [[WGSettingsAccess shared] attachToWindow:self.view.window];
    [[WGHostAppearanceStyler shared] applyToController:self];
}
- (void)viewDidLayoutSubviews {
    %orig;
    if (![WGEnvironment shouldActivate]) return;
    // The styler ignores controllers that are not explicit chat/home matches.
    [[WGHostAppearanceStyler shared] applyToController:self];
}
%end

%hook UITabBarController
- (void)viewDidAppear:(BOOL)animated {
    %orig;
    if ([WGEnvironment shouldActivate]) [[WGTabBarStyler shared] attachToTabBarController:self];
}
- (void)viewDidLayoutSubviews {
    %orig;
    if ([WGEnvironment shouldActivate]) [[WGTabBarStyler shared] attachToTabBarController:self];
}
- (void)setSelectedIndex:(NSUInteger)index {
    %orig;
    if ([WGEnvironment shouldActivate]) [[WGTabBarStyler shared] attachToTabBarController:self];
}
- (void)setSelectedViewController:(UIViewController *)controller {
    %orig;
    if ([WGEnvironment shouldActivate]) [[WGTabBarStyler shared] attachToTabBarController:self];
}
%end

%ctor {
    @autoreleasepool {
        if (![WGEnvironment shouldActivate]) return;
        NSLog(@"[WeaveGlass] 0.3.0 active: iOS 26+ WeChat, UIKit safety gates enabled");
    }
}
