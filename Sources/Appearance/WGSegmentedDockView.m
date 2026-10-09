#import "WGSegmentedDockView.h"
#import "WGGlassEffect.h"
#import "WGGlassSupport.h"
#import "WGConfiguration.h"

@interface WGSegmentedDockView ()
@property (nonatomic, strong) UIVisualEffectView *material;
@property (nonatomic, strong) UIView *selectionPill;
@property (nonatomic, strong) UIStackView *stack;
@property (nonatomic, strong) NSMutableArray<UIButton *> *buttons;
@property (nonatomic, assign) NSInteger lastSelection;
@end

@implementation WGSegmentedDockView
- (instancetype)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.backgroundColor = UIColor.clearColor;
        self.accessibilityIdentifier = @"WeaveGlass.CapsuleDock";
        _buttons = NSMutableArray.array;
        _lastSelection = NSNotFound;
        _material = [WGGlassEffect newGlassViewClear:NO];
        if (_material) {
            _material.userInteractionEnabled = NO;
            [self addSubview:_material];
        } else {
            self.backgroundColor = UIColor.secondarySystemGroupedBackgroundColor;
        }
        _selectionPill = [UIView new];
        _selectionPill.backgroundColor = [WGGlassSupport.accentColor colorWithAlphaComponent:0.18];
        _selectionPill.userInteractionEnabled = NO;
        [self addSubview:_selectionPill];
        _stack = [[UIStackView alloc] initWithFrame:CGRectZero];
        _stack.axis = UILayoutConstraintAxisHorizontal;
        _stack.alignment = UIStackViewAlignmentFill;
        _stack.distribution = UIStackViewDistributionFillEqually;
        _stack.spacing = 0;
        [self addSubview:_stack];
        self.layer.borderColor = [UIColor.separatorColor colorWithAlphaComponent:0.25].CGColor;
        self.layer.borderWidth = 0.6;
        self.clipsToBounds = YES;
    }
    return self;
}
- (void)reloadFromController {
    if (!self.controller) return;
    NSArray<UITabBarItem *> *items = self.controller.tabBar.items ?: @[];
    if (items.count < 2 || items.count > 6) return;
    if (items.count != self.buttons.count) {
        for (UIView *v in self.stack.arrangedSubviews) { [self.stack removeArrangedSubview:v]; [v removeFromSuperview]; }
        [self.buttons removeAllObjects];
        for (NSUInteger i = 0; i < items.count; i++) {
            UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
            button.tag = (NSInteger)i;
            UIButtonConfiguration *cfg = UIButtonConfiguration.plainButtonConfiguration;
            cfg.imagePlacement = NSDirectionalRectEdgeTop;
            cfg.imagePadding = 1;
            cfg.contentInsets = NSDirectionalEdgeInsetsMake(3, 2, 3, 2);
            button.configuration = cfg;
            button.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption2];
            button.titleLabel.adjustsFontForContentSizeCategory = YES;
            [button addTarget:self action:@selector(selectTab:) forControlEvents:UIControlEventTouchUpInside];
            [self.stack addArrangedSubview:button];
            [self.buttons addObject:button];
        }
    }
    for (NSUInteger i = 0; i < items.count; i++) {
        UITabBarItem *item = items[i];
        UIButton *button = self.buttons[i];
        UIButtonConfiguration *cfg = button.configuration ?: UIButtonConfiguration.plainButtonConfiguration;
        cfg.title = item.title ?: @"";
        cfg.image = item.image;
        button.configuration = cfg;
        button.accessibilityLabel = item.accessibilityLabel ?: item.title ?: [NSString stringWithFormat:@"导航 %lu", (unsigned long)(i + 1)];
        button.accessibilityHint = @"切换微信标签页";
        button.accessibilityValue = item.badgeValue.length ? [NSString stringWithFormat:@"%@ 条未读",item.badgeValue] : nil;
        // Badge stays separate from button configuration, so tab selection never clears it.
        UILabel *badge = (UILabel *)[button viewWithTag:991];
        if (item.badgeValue.length) {
            if (!badge) {
                badge = [[UILabel alloc] initWithFrame:CGRectZero];
                badge.tag = 991;
                badge.font = [UIFont monospacedDigitSystemFontOfSize:10 weight:UIFontWeightSemibold];
                badge.textAlignment = NSTextAlignmentCenter;
                badge.textColor = UIColor.whiteColor;
                badge.backgroundColor = UIColor.systemRedColor;
                badge.translatesAutoresizingMaskIntoConstraints = NO;
                badge.userInteractionEnabled = NO;
                [button addSubview:badge];
                [NSLayoutConstraint activateConstraints:@[
                    [badge.trailingAnchor constraintEqualToAnchor:button.trailingAnchor constant:-4],
                    [badge.topAnchor constraintEqualToAnchor:button.topAnchor constant:0],
                    [badge.heightAnchor constraintGreaterThanOrEqualToConstant:16],
                    [badge.widthAnchor constraintGreaterThanOrEqualToConstant:16]]];
            }
            badge.hidden = NO;
            badge.text = item.badgeValue;
            badge.layer.cornerRadius = 8;
            badge.clipsToBounds = YES;
        } else badge.hidden = YES;
    }
    [self updateSelection];
}
- (void)selectTab:(UIButton *)button {
    if (button.tag < 0 || (NSUInteger)button.tag >= self.controller.viewControllers.count) return;
    self.controller.selectedIndex = (NSUInteger)button.tag;
    [self updateSelection];
}
- (void)updateSelection {
    NSUInteger selected = self.controller.selectedIndex;
    UIColor *accent = WGGlassSupport.accentColor;
    self.selectionPill.backgroundColor = [accent colorWithAlphaComponent:0.17];
    for (NSUInteger i = 0; i < self.buttons.count; i++) {
        UIButton *button = self.buttons[i];
        button.tintColor = i == selected ? accent : UIColor.secondaryLabelColor;
        button.accessibilityTraits = UIAccessibilityTraitButton | (i == selected ? UIAccessibilityTraitSelected : 0);
    }
    BOOL animate = [WGConfiguration.shared boolForKeyName:WGPreferenceMorphDock defaultValue:NO]
        && self.lastSelection != NSNotFound && self.lastSelection != (NSInteger)selected
        && !UIAccessibilityIsReduceMotionEnabled();
    self.lastSelection = (NSInteger)selected;
    [self setNeedsLayout];
    if (animate) {
        [UIView animateWithDuration:0.36 delay:0
             usingSpringWithDamping:0.74 initialSpringVelocity:0.35
                            options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction
                         animations:^{
            [self layoutIfNeeded];
        } completion:nil];
    }
}
- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat r = MIN(CGRectGetHeight(self.bounds) / 2, 28);
    self.layer.cornerRadius = r;
    self.material.frame = self.bounds;
    self.material.layer.cornerRadius = r;
    self.material.clipsToBounds = YES;
    self.stack.frame = CGRectInset(self.bounds, 5, 4);
    NSUInteger count = self.buttons.count;
    if (count) {
        CGRect rect = self.stack.frame;
        CGFloat width = CGRectGetWidth(rect) / count;
        CGRect pill = CGRectMake(CGRectGetMinX(rect) + MIN(self.controller.selectedIndex, count - 1) * width,
                                 CGRectGetMinY(rect), width, CGRectGetHeight(rect));
        self.selectionPill.frame = CGRectInset(pill, 2, 0);
        self.selectionPill.layer.cornerRadius = MIN(CGRectGetHeight(pill)/2, 24);
    }
}
@end
