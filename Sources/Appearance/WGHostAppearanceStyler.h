#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN
@interface WGHostAppearanceStyler : NSObject
+ (instancetype)shared;
- (void)applyToController:(UIViewController *)controller;
- (void)refresh;
@end
NS_ASSUME_NONNULL_END
