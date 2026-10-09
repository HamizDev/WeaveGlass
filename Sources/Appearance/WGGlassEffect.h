#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@interface WGGlassEffect : NSObject
/// Only native UIKit glass on iOS 26+. Never emulates glass with fake blur.
+ (nullable UIVisualEffectView *)newGlassViewClear:(BOOL)clear;
@end
NS_ASSUME_NONNULL_END
