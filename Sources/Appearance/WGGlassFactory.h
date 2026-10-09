#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN
// Safe material creation shared by WeaveGlass components, never accepts untrusted style numbers.
@interface WGGlassFactory : NSObject
+ (UIView *)backplateClear:(BOOL)clear cornerRadius:(CGFloat)radius;
+ (void)decorateBackplate:(UIView *)view radius:(CGFloat)radius;
@end
NS_ASSUME_NONNULL_END
