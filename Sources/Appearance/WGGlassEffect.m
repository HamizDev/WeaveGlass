#import "WGGlassEffect.h"
#import <objc/message.h>
#import "WGEnvironment.h"

@implementation WGGlassEffect
+ (UIVisualEffectView *)newGlassViewClear:(BOOL)clear {
    if (![WGEnvironment shouldActivate]) return nil;
    // The method is dynamically resolved: the project can still parse with older SDKs.
    // UIGlassEffectStyleRegular=0; UIGlassEffectStyleClear=1 (iOS 26 UIKit).
    Class klass = NSClassFromString(@"UIGlassEffect");
    SEL factory = NSSelectorFromString(@"effectWithStyle:");
    if (!klass || ![klass respondsToSelector:factory]) return nil;
    typedef id (*EffectFactory)(id, SEL, NSInteger);
    id effect = ((EffectFactory)objc_msgSend)(klass, factory, clear ? 1 : 0);
    if (![effect isKindOfClass:UIVisualEffect.class]) return nil;
    UIVisualEffectView *view = [[UIVisualEffectView alloc] initWithEffect:effect];
    view.userInteractionEnabled = NO;
    view.accessibilityElementsHidden = YES;
    return view;
}
@end
