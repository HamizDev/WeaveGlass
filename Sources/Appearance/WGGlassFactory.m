#import "WGGlassFactory.h"
#import "WGGlassEffect.h"
#import "WGGlassSupport.h"
@implementation WGGlassFactory
+ (UIView *)backplateClear:(BOOL)clear cornerRadius:(CGFloat)radius {
    UIView *view = [WGGlassSupport isGlassUsable] ? [WGGlassEffect newGlassViewClear:clear] : nil;
    if (!view) {
        view = [UIView new];
        view.backgroundColor = UIColor.secondarySystemGroupedBackgroundColor;
    }
    [self decorateBackplate:view radius:radius];
    view.userInteractionEnabled = NO;
    view.accessibilityElementsHidden = YES;
    return view;
}
+ (void)decorateBackplate:(UIView *)view radius:(CGFloat)radius {
    view.layer.cornerRadius = MAX(0, radius);
    view.clipsToBounds = YES;
    view.layer.borderWidth = 0.5;
    view.layer.borderColor = [UIColor.separatorColor colorWithAlphaComponent:0.28].CGColor;
}
@end
