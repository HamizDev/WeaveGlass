#import "WGChatTitleCapsuleView.h"
#import "WGGlassFactory.h"
#import "WGConfiguration.h"
@interface WGChatTitleCapsuleView ()
@property (nonatomic, strong) UIView *glass;
@property (nonatomic, strong) UILabel *label;
@property (nonatomic, strong) UIImageView *icon;
@end
@implementation WGChatTitleCapsuleView
- (instancetype)initWithTitle:(NSString *)title {
    if ((self = [super initWithFrame:CGRectMake(0, 0, 196, 38)])) {
        self.backgroundColor = UIColor.clearColor;
        self.userInteractionEnabled = NO;
        self.isAccessibilityElement = YES;
        self.accessibilityTraits = UIAccessibilityTraitStaticText;
        BOOL clear = [WGConfiguration.shared boolForKeyName:WGPreferenceClearGlass defaultValue:NO];
        _glass = [WGGlassFactory backplateClear:clear cornerRadius:19];
        _glass.frame = self.bounds;
        _glass.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self addSubview:_glass];
        _icon = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"bubble.left.and.bubble.right.fill"]];
        _icon.tintColor = UIColor.secondaryLabelColor;
        _icon.frame = CGRectMake(15, 11, 17, 17);
        _icon.contentMode = UIViewContentModeScaleAspectFit;
        _icon.accessibilityElementsHidden = YES;
        [self addSubview:_icon];
        _label = [[UILabel alloc] initWithFrame:CGRectMake(39, 5, 145, 28)];
        _label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
        _label.adjustsFontForContentSizeCategory = YES;
        _label.textColor = UIColor.labelColor;
        _label.lineBreakMode = NSLineBreakByTruncatingTail;
        [self addSubview:_label];
        [self updateTitle:title];
    }
    return self;
}
- (void)updateTitle:(NSString *)title {
    self.label.text = title;
    self.accessibilityLabel = title;
}
- (CGSize)intrinsicContentSize { return CGSizeMake(196, 38); }
@end
