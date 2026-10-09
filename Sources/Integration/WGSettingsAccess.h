#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN
@interface WGSettingsAccess : NSObject
+ (instancetype)shared;
- (void)attachToWindow:(nullable UIWindow *)window;
- (void)presentFromView:(UIView *)view;
@end
NS_ASSUME_NONNULL_END
