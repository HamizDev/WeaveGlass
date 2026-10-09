#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN
@interface WGGlassSupport : NSObject
+ (UIColor *)accentColor;
+ (nullable UIColor *)colorFromHex:(NSString *)hex;
+ (NSString *)hexFromColor:(UIColor *)color;
+ (BOOL)isGlassUsable;
@end
NS_ASSUME_NONNULL_END
