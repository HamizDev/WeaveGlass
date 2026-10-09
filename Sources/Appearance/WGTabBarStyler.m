#import "WGTabBarStyler.h"
#import "WGGlassEffect.h"
#import "WGConfiguration.h"
#import "WGSettingsAccess.h"
#import "WGSegmentedDockView.h"
#import "WGEnvironment.h"
#import <objc/runtime.h>

static char kWGGlassView;
static char kWGOriginalStandard;
static char kWGOriginalScrollEdge;
static char kWGOriginalTint;
static char kWGInstalledGesture;
static char kWGDock;
static char kWGHiddenBarButtons;
static char kWGCurrentMode;

@interface WGTabBarStyler ()
@property (nonatomic, strong) NSHashTable<UITabBarController *> *controllers;
@end

@implementation WGTabBarStyler
+ (instancetype)shared {
    static WGTabBarStyler *shared;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ shared = [[WGTabBarStyler alloc] initPrivate]; });
    return shared;
}
- (instancetype)initPrivate {
    if ((self = [super init])) {
        _controllers = NSHashTable.weakObjectsHashTable;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(settingsChanged:)
                                                     name:WGSettingsDidChangeNotification object:nil];
    }
    return self;
}
- (void)settingsChanged:(NSNotification *)note { (void)note; [self refreshVisibleTabBars]; }
- (void)attachToTabBarController:(UITabBarController *)controller {
    if (!NSThread.isMainThread || ![WGEnvironment shouldActivate] || !controller.isViewLoaded || !controller.view.window) return;
    UITabBar *bar = controller.tabBar;
    if (!bar) return;
    [self.controllers addObject:controller];
    if (!objc_getAssociatedObject(bar, &kWGInstalledGesture)) {
        UILongPressGestureRecognizer *press = [[UILongPressGestureRecognizer alloc]
                                              initWithTarget:self action:@selector(openSettingsFromGesture:)];
        press.minimumPressDuration = 0.85;
        press.cancelsTouchesInView = NO;
        [bar addGestureRecognizer:press];
        objc_setAssociatedObject(bar, &kWGInstalledGesture, press, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    [self applyToController:controller];
}
- (void)openSettingsFromGesture:(UILongPressGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateBegan && gesture.view) {
        [WGSettingsAccess.shared presentFromView:gesture.view];
    }
}
- (void)refreshVisibleTabBars {
    if (!NSThread.isMainThread) {
        dispatch_async(dispatch_get_main_queue(), ^{ [self refreshVisibleTabBars]; });
        return;
    }
    for (UITabBarController *controller in self.controllers.allObjects) {
        if (controller.isViewLoaded && controller.view.window) [self applyToController:controller];
    }
}
- (void)hideNativeTabButtons:(UITabBar *)bar {
    if (objc_getAssociatedObject(bar, &kWGHiddenBarButtons)) return;
    NSMutableArray<NSDictionary *> *snapshots = NSMutableArray.array;
    for (UIView *v in bar.subviews) {
        // UIKit-private view is discovered at runtime, never hooked or messaged.
        // Fail closed when a different implementation is used.
        if ([NSStringFromClass(v.class) isEqualToString:@"UITabBarButton"]) {
            [snapshots addObject:@{@"view": v, @"alpha": @(v.alpha), @"interaction": @(v.userInteractionEnabled)}];
        }
    }
    if (snapshots.count != bar.items.count) return;
    for (NSDictionary *item in snapshots) {
        UIView *view = item[@"view"];
        view.alpha = 0;
        view.userInteractionEnabled = NO;
    }
    objc_setAssociatedObject(bar, &kWGHiddenBarButtons, snapshots, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (void)restoreNativeTabButtons:(UITabBar *)bar {
    NSArray<NSDictionary *> *snapshots = objc_getAssociatedObject(bar, &kWGHiddenBarButtons);
    for (NSDictionary *item in snapshots) {
        UIView *view = item[@"view"];
        view.alpha = [item[@"alpha"] doubleValue];
        view.userInteractionEnabled = [item[@"interaction"] boolValue];
    }
    objc_setAssociatedObject(bar, &kWGHiddenBarButtons, nil, OBJC_ASSOCIATION_ASSIGN);
}
- (void)restoreBar:(UITabBar *)bar {
    UIVisualEffectView *glass = objc_getAssociatedObject(bar, &kWGGlassView);
    [glass removeFromSuperview];
    objc_setAssociatedObject(bar, &kWGGlassView, nil, OBJC_ASSOCIATION_ASSIGN);
    WGSegmentedDockView *dock = objc_getAssociatedObject(bar, &kWGDock);
    [dock removeFromSuperview];
    objc_setAssociatedObject(bar, &kWGDock, nil, OBJC_ASSOCIATION_ASSIGN);
    [self restoreNativeTabButtons:bar];
    UITabBarAppearance *standard = objc_getAssociatedObject(bar, &kWGOriginalStandard);
    if (standard) bar.standardAppearance = standard;
    if (@available(iOS 15.0, *)) {
        // NSNull marks the originally absent scrollEdgeAppearance.
        id old = objc_getAssociatedObject(bar, &kWGOriginalScrollEdge);
        if (old) bar.scrollEdgeAppearance = old == NSNull.null ? nil : old;
    }
    id tint = objc_getAssociatedObject(bar, &kWGOriginalTint);
    if (tint) bar.tintColor = tint == NSNull.null ? nil : tint;
    objc_setAssociatedObject(bar, &kWGOriginalStandard, nil, OBJC_ASSOCIATION_ASSIGN);
    objc_setAssociatedObject(bar, &kWGOriginalScrollEdge, nil, OBJC_ASSOCIATION_ASSIGN);
    objc_setAssociatedObject(bar, &kWGOriginalTint, nil, OBJC_ASSOCIATION_ASSIGN);
    objc_setAssociatedObject(bar, &kWGCurrentMode, nil, OBJC_ASSOCIATION_ASSIGN);
}
- (void)applyToController:(UITabBarController *)controller {
    UITabBar *bar = controller.tabBar;
    WGConfiguration *cfg = WGConfiguration.shared;
    BOOL enabled = [cfg boolForKeyName:WGPreferenceEnabled defaultValue:YES];
    BOOL morph = enabled && [cfg boolForKeyName:WGPreferenceMorphDock defaultValue:NO];
    BOOL capsule = enabled && ([cfg boolForKeyName:WGPreferenceCapsuleDock defaultValue:NO] || morph);
    BOOL nativeOverlay = enabled && !capsule && [cfg boolForKeyName:WGPreferenceNativeGlass defaultValue:NO];
    NSInteger mode = capsule ? 2 : nativeOverlay ? 1 : 0;
    BOOL clear = [cfg boolForKeyName:WGPreferenceClearGlass defaultValue:NO];
    NSString *stamp = [NSString stringWithFormat:@"%ld-%d-%d-%lu", (long)mode, clear, morph, (unsigned long)bar.items.count];
    NSString *current = objc_getAssociatedObject(bar, &kWGCurrentMode);
    if ([current isEqualToString:stamp]) {
        WGSegmentedDockView *dock = objc_getAssociatedObject(bar, &kWGDock);
        if (dock) {
            // UIKit may rebuild its internal tab buttons without changing bar.items.
            // Detect stale snapshots and rebuild our overlay rather than leaving
            // unknown native buttons visible underneath the capsule.
            NSArray<NSDictionary *> *snapshots = objc_getAssociatedObject(bar, &kWGHiddenBarButtons);
            NSUInteger matched = 0;
            for (UIView *child in bar.subviews) {
                if (![NSStringFromClass(child.class) isEqualToString:@"UITabBarButton"]) continue;
                BOOL known = NO;
                for (NSDictionary *snapshot in snapshots) {
                    if (snapshot[@"view"] == child) { known = YES; break; }
                }
                if (known) matched++;
            }
            if (matched == snapshots.count && matched == bar.items.count) {
                CGFloat height = MIN(52, MAX(38, bar.bounds.size.height - 10));
                dock.frame = CGRectMake(12, 3, MAX(0, bar.bounds.size.width - 24), height);
                [dock reloadFromController];
                return;
            }
            // Below, restore the previous state then fail closed or reapply.
        } else return;
    }
    [self restoreBar:bar];
    if (!mode) { objc_setAssociatedObject(bar, &kWGCurrentMode, stamp, OBJC_ASSOCIATION_COPY_NONATOMIC); return; }
    objc_setAssociatedObject(bar, &kWGOriginalStandard, [bar.standardAppearance copy], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (@available(iOS 15.0, *)) {
        objc_setAssociatedObject(bar, &kWGOriginalScrollEdge, [bar.scrollEdgeAppearance copy] ?: NSNull.null, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    objc_setAssociatedObject(bar, &kWGOriginalTint, bar.tintColor ?: NSNull.null, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (mode == 1) {
        UIVisualEffectView *glass = [WGGlassEffect newGlassViewClear:clear];
        if (glass) {
            glass.frame = bar.bounds;
            glass.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            [bar insertSubview:glass atIndex:0];
            objc_setAssociatedObject(bar, &kWGGlassView, glass, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            UITabBarAppearance *appearance = [bar.standardAppearance copy];
            [appearance configureWithTransparentBackground];
            bar.standardAppearance = appearance;
            if (@available(iOS 15.0, *)) bar.scrollEdgeAppearance = appearance;
        }
    } else if (mode == 2 && bar.items.count >= 2 && bar.items.count <= 6) {
        [self hideNativeTabButtons:bar];
        if (objc_getAssociatedObject(bar, &kWGHiddenBarButtons)) {
            CGFloat height = MIN(52, MAX(38, bar.bounds.size.height - 10));
            WGSegmentedDockView *dock = [[WGSegmentedDockView alloc] initWithFrame:CGRectMake(12, 3, MAX(0, bar.bounds.size.width - 24), height)];
            dock.autoresizingMask = UIViewAutoresizingFlexibleWidth;
            dock.controller = controller;
            [bar addSubview:dock];
            [dock reloadFromController];
            objc_setAssociatedObject(bar, &kWGDock, dock, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
    }
    objc_setAssociatedObject(bar, &kWGCurrentMode, stamp, OBJC_ASSOCIATION_COPY_NONATOMIC);
}
@end
