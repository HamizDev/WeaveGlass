#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@interface WGTabBarStyler : NSObject
+ (instancetype)shared;
- (void)attachToTabBarController:(UITabBarController *)controller;
- (void)refreshVisibleTabBars;
@end
NS_ASSUME_NONNULL_END
