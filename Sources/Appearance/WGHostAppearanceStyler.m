#import "WGHostAppearanceStyler.h"
#import "WGConfiguration.h"
#import "WGGlassSupport.h"
#import "WGGlassEffect.h"
#import "WGEnvironment.h"
#import "WGClassResolver.h"
#import "WGChatTitleCapsuleView.h"
#import <objc/runtime.h>

static char kWGBackup;
static char kWGOverlay;
static char kWGNavBackup;
static char kWGTitleBackup;
static char kWGTitleOwned;


@interface WGHostAppearanceStyler ()
@property (nonatomic, strong) NSHashTable<UIViewController *> *controllers;
@property (nonatomic, strong) NSHashTable<UIView *> *styledViews;
@property (nonatomic, strong) NSHashTable<UINavigationBar *> *styledBars;
@property (nonatomic, strong) NSHashTable<UINavigationItem *> *styledTitles;
@end

@implementation WGHostAppearanceStyler
+ (instancetype)shared {
    static WGHostAppearanceStyler *value;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ value = [WGHostAppearanceStyler new]; });
    return value;
}
- (instancetype)init {
    if ((self = [super init])) {
        _controllers = NSHashTable.weakObjectsHashTable;
        _styledViews = NSHashTable.weakObjectsHashTable;
        _styledBars = NSHashTable.weakObjectsHashTable;
        _styledTitles = NSHashTable.weakObjectsHashTable;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(settingsChanged:)
                                                     name:WGSettingsDidChangeNotification object:nil];
    }
    return self;
}
- (void)settingsChanged:(NSNotification *)note { (void)note; [self refresh]; }
- (void)refresh {
    if (!NSThread.isMainThread) {
        dispatch_async(dispatch_get_main_queue(), ^{ [self refresh]; });
        return;
    }
    // Restore BEFORE applying current modes; prevents stacked overlays after toggles.
    for (UIView *view in self.styledViews.allObjects) [self restoreView:view];
    for (UINavigationBar *bar in self.styledBars.allObjects) [self restoreBar:bar];
    for (UINavigationItem *item in self.styledTitles.allObjects) [self restoreTitleItem:item];
    for (UIViewController *vc in self.controllers.allObjects) {
        if (vc.isViewLoaded && vc.view.window) [self applyToController:vc];
    }
}
- (void)restoreView:(UIView *)view {
    NSDictionary *state = objc_getAssociatedObject(view, &kWGBackup);
    if (!state) return;
    UIVisualEffectView *overlay = objc_getAssociatedObject(view, &kWGOverlay);
    [overlay removeFromSuperview];
    objc_setAssociatedObject(view, &kWGOverlay, nil, OBJC_ASSOCIATION_ASSIGN);
    id background = state[@"background"];
    view.backgroundColor = background == NSNull.null ? nil : background;
    view.layer.cornerRadius = [state[@"radius"] doubleValue];
    view.layer.borderWidth = [state[@"borderWidth"] doubleValue];
    view.layer.borderColor = state[@"borderColor"] == NSNull.null ? NULL : ((UIColor *)state[@"borderColor"]).CGColor;
    view.clipsToBounds = [state[@"clips"] boolValue];
    objc_setAssociatedObject(view, &kWGBackup, nil, OBJC_ASSOCIATION_ASSIGN);
}
- (void)styleView:(UIView *)view radius:(CGFloat)radius {
    if (!view.superview || CGRectIsEmpty(view.frame)) return;
    if (!objc_getAssociatedObject(view, &kWGBackup)) {
        // Preserve CGColor as an Objective-C UIColor; a raw CGColor cast is not an object.
        UIColor *border = view.layer.borderColor ? [UIColor colorWithCGColor:view.layer.borderColor] : nil;
        NSDictionary *backup = @{@"background": view.backgroundColor ?: NSNull.null,
                                 @"radius": @(view.layer.cornerRadius),
                                 @"borderWidth": @(view.layer.borderWidth),
                                 @"borderColor": border ?: NSNull.null,
                                 @"clips": @(view.clipsToBounds)};
        objc_setAssociatedObject(view, &kWGBackup, backup, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    [self.styledViews addObject:view];
    UIVisualEffectView *overlay = objc_getAssociatedObject(view, &kWGOverlay);
    BOOL clear = [WGConfiguration.shared boolForKeyName:WGPreferenceClearGlass defaultValue:NO];
    if (!overlay && [WGGlassSupport isGlassUsable]) {
        overlay = [WGGlassEffect newGlassViewClear:clear];
        if (overlay) {
            overlay.userInteractionEnabled = NO;
            overlay.accessibilityElementsHidden = YES;
            [view.superview insertSubview:overlay belowSubview:view];
            objc_setAssociatedObject(view, &kWGOverlay, overlay, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
    }
    if (overlay.superview != view.superview) {
        [overlay removeFromSuperview];
        if (overlay && view.superview) [view.superview insertSubview:overlay belowSubview:view];
    }
    overlay.frame = view.frame;
    overlay.layer.cornerRadius = radius;
    overlay.clipsToBounds = YES;
    // Accessibility fallbacks use solid system colors to preserve contrast.
    view.backgroundColor = overlay ? UIColor.clearColor : UIColor.secondarySystemGroupedBackgroundColor;
    view.layer.cornerRadius = radius;
    view.layer.borderWidth = 0.6;
    view.layer.borderColor = [UIColor.separatorColor colorWithAlphaComponent:0.45].CGColor;
    view.clipsToBounds = YES;
}
- (void)restoreBar:(UINavigationBar *)bar {
    id original = objc_getAssociatedObject(bar, &kWGNavBackup);
    if (!original) return;
    bar.tintColor = original == NSNull.null ? nil : original;
    objc_setAssociatedObject(bar, &kWGNavBackup, nil, OBJC_ASSOCIATION_ASSIGN);
}
- (void)restoreTitleItem:(UINavigationItem *)item {
    id saved = objc_getAssociatedObject(item, &kWGTitleBackup);
    UIView *owned = objc_getAssociatedObject(item, &kWGTitleOwned);
    if (!saved) return;
    // If WeChat has replaced titleView since our change, keep its new view.
    if (item.titleView == owned) item.titleView = saved == NSNull.null ? nil : saved;
    objc_setAssociatedObject(item, &kWGTitleBackup, nil, OBJC_ASSOCIATION_ASSIGN);
    objc_setAssociatedObject(item, &kWGTitleOwned, nil, OBJC_ASSOCIATION_ASSIGN);
}
- (void)styleChatTitleInController:(UIViewController *)controller {
    UINavigationItem *item = controller.navigationItem;
    NSString *title = item.title.length ? item.title : controller.title;
    if (!title.length || !controller.navigationController) return;
    WGChatTitleCapsuleView *owned = objc_getAssociatedObject(item, &kWGTitleOwned);
    if (owned && item.titleView == owned) { [owned updateTitle:title]; return; }
    // Do not cover custom contact controls used by some WeChat builds.
    if (item.titleView != nil) return;
    objc_setAssociatedObject(item, &kWGTitleBackup, NSNull.null, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    owned = [[WGChatTitleCapsuleView alloc] initWithTitle:title];
    item.titleView = owned;
    objc_setAssociatedObject(item, &kWGTitleOwned, owned, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self.styledTitles addObject:item];
}
- (void)applyToController:(UIViewController *)controller {
    if (!NSThread.isMainThread || ![WGEnvironment shouldActivate] || !controller.isViewLoaded || !controller.view.window) return;
    [self.controllers addObject:controller];
    WGConfiguration *prefs = WGConfiguration.shared;
    BOOL enabled = [prefs boolForKeyName:WGPreferenceEnabled defaultValue:YES];
    if (!enabled) return;
    BOOL autoMatch = [prefs boolForKeyName:WGPreferenceAutoClassMatch defaultValue:NO];
    NSString *chatName = autoMatch ? @"auto" : [prefs valueForKeyName:WGPreferenceChatHostClass];
    NSString *homeName = autoMatch ? @"auto" : [prefs valueForKeyName:WGPreferenceHomeHostClass];
    BOOL chat = [WGClassResolver controller:controller matchesPreferredName:chatName fallbackCandidates:WGClassResolver.chatCandidates];
    BOOL home = [WGClassResolver controller:controller matchesPreferredName:homeName fallbackCandidates:WGClassResolver.homeCandidates];
    if (!chat && !home) return;
    if (chat && [prefs boolForKeyName:WGPreferenceChatTitleCapsule defaultValue:NO]) {
        [self styleChatTitleInController:controller];
    }

    if ([prefs boolForKeyName:WGPreferenceNavigationTint defaultValue:NO]) {
        UINavigationBar *bar = controller.navigationController.navigationBar;
        if (bar) {
            if (!objc_getAssociatedObject(bar, &kWGNavBackup)) {
                objc_setAssociatedObject(bar, &kWGNavBackup, bar.tintColor ?: NSNull.null, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            }
            [self.styledBars addObject:bar];
            bar.tintColor = WGGlassSupport.accentColor;
        }
    }
    BOOL composer = chat && [prefs boolForKeyName:WGPreferenceChatComposer defaultValue:NO];
    BOOL search = home && [prefs boolForKeyName:WGPreferenceHomeSearch defaultValue:NO];
    if (!composer && !search) return;
    NSMutableArray<UIView *> *queue = [NSMutableArray arrayWithObject:controller.view];
    // Bounded traversal: never recursively scan arbitrary large message histories.
    for (NSUInteger i = 0; i < queue.count && i < 350; i++) {
        UIView *v = queue[i];
        if (composer && [v isKindOfClass:UITextView.class]) {
            UITextView *textView = (UITextView *)v;
            CGRect rect = [textView.superview convertRect:textView.frame toView:controller.view];
            CGFloat fraction = controller.view.bounds.size.height > 0 ? CGRectGetMidY(rect) / controller.view.bounds.size.height : 0;
            if (textView.editable && fraction > 0.55 && textView.bounds.size.height > 28 && textView.bounds.size.height < 230) {
                [self styleView:textView radius:MIN(20, textView.bounds.size.height / 2)];
            }
        }
        if (search && [v isKindOfClass:UISearchBar.class]) {
            UISearchTextField *field = ((UISearchBar *)v).searchTextField;
            if (field) [self styleView:field radius:MIN(22, field.bounds.size.height / 2)];
        }
        if (v.subviews.count && queue.count < 350) [queue addObjectsFromArray:v.subviews];
    }
}
@end
