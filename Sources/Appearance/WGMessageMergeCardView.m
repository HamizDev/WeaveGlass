#import "WGMessageMergeCardView.h"
#import "WGGlassFactory.h"
#import "WGConfiguration.h"
@interface WGMessageMergeCardView ()
@property (nonatomic, strong) UIStackView *vertical;
@end
@implementation WGMessageMergeCardView
- (instancetype)initWithMessages:(NSArray<NSDictionary<NSString *,NSString *> *> *)messages {
    if ((self = [super initWithFrame:CGRectZero])) {
        self.backgroundColor = UIColor.clearColor;
        UIView *background = [WGGlassFactory backplateClear:NO cornerRadius:20];
        background.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:background];
        _vertical = [[UIStackView alloc] init];
        _vertical.axis = UILayoutConstraintAxisVertical;
        _vertical.distribution = UIStackViewDistributionFill;
        _vertical.alignment = UIStackViewAlignmentFill;
        _vertical.spacing = 8;
        _vertical.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:_vertical];
        [NSLayoutConstraint activateConstraints:@[
            [background.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
            [background.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
            [background.topAnchor constraintEqualToAnchor:self.topAnchor],
            [background.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
            [_vertical.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:16],
            [_vertical.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-16],
            [_vertical.topAnchor constraintEqualToAnchor:self.topAnchor constant:14],
            [_vertical.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-14],
        ]];
        NSUInteger count = MIN(messages.count, 20); // bounded host-safe rendering
        for (NSUInteger i = 0; i < count; i++) {
            NSDictionary *message = messages[i];
            if (![message isKindOfClass:NSDictionary.class]) continue;
            NSString *sender = [message[@"sender"] isKindOfClass:NSString.class] ? message[@"sender"] : @"";
            NSString *body = [message[@"body"] isKindOfClass:NSString.class] ? message[@"body"] : @"";
            NSString *time = [message[@"time"] isKindOfClass:NSString.class] ? message[@"time"] : @"";
            if (i) {
                UIView *divider = [UIView new];
                divider.backgroundColor = [UIColor.separatorColor colorWithAlphaComponent:0.42];
                [divider.heightAnchor constraintEqualToConstant:0.5].active = YES;
                [_vertical addArrangedSubview:divider];
            }
            UILabel *heading = [UILabel new];
            heading.numberOfLines = 1;
            heading.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
            heading.textColor = UIColor.secondaryLabelColor;
            heading.text = time.length ? [NSString stringWithFormat:@"%@  ·  %@", sender, time] : sender;
            [_vertical addArrangedSubview:heading];
            UILabel *content = [UILabel new];
            content.numberOfLines = 0;
            content.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
            content.textColor = UIColor.labelColor;
            content.text = body.length > 800 ? [body substringToIndex:800] : body;
            [_vertical addArrangedSubview:content];
        }
    }
    return self;
}
@end
