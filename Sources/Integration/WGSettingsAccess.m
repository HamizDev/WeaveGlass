#import "WGSettingsAccess.h"
#import "WGSettingsController.h"
#import "WGEnvironment.h"
#import <objc/runtime.h>

static char kWGWindowGestureKey;
@implementation WGSettingsAccess
+ (instancetype)shared {
    static WGSettingsAccess *object;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ object = [WGSettingsAccess new]; });
    return object;
}
- (void)attachToWindow:(UIWindow *)window {
    if (![WGEnvironment shouldActivate] || !window || !NSThread.isMainThread) return;
    if (objc_getAssociatedObject(window, &kWGWindowGestureKey)) return;
    // Independently available when WeChat does not use a UITabBarController.
    // 3-finger triple tap deliberately avoids ordinary taps and scroll gestures.
    UITapGestureRecognizer *gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(openFromGesture:)];
    gesture.numberOfTouchesRequired = 3;
    gesture.numberOfTapsRequired = 3;
    gesture.cancelsTouchesInView = NO;
    [window addGestureRecognizer:gesture];
    objc_setAssociatedObject(window, &kWGWindowGestureKey, gesture, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (void)openFromGesture:(UIGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateRecognized && gesture.view) {
        [self presentFromView:gesture.view];
    }
}
- (void)presentFromView:(UIView *)view {
    if (!NSThread.isMainThread || !view.window || ![WGEnvironment shouldActivate]) return;
    UIViewController *presenter = view.window.rootViewController;
    if (!presenter) return;
    // Never stack multiple copies or present while a system alert is already visible.
    for (NSUInteger i = 0; i < 16; i++) {
        if ([presenter isKindOfClass:WGSettingsController.class]) return;
        if ([presenter isKindOfClass:UINavigationController.class] &&
            [((UINavigationController *)presenter).topViewController isKindOfClass:WGSettingsController.class]) return;
        if (!presenter.presentedViewController) break;
        presenter = presenter.presentedViewController;
    }
    if (presenter.isBeingDismissed || !presenter.view.window || [presenter isKindOfClass:UIAlertController.class]) return;
    WGSettingsController *settings = [[WGSettingsController alloc] initWithStyle:UITableViewStyleInsetGrouped];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:settings];
    nav.modalPresentationStyle = UIModalPresentationPageSheet;
    [presenter presentViewController:nav animated:YES completion:nil];
}
@end
