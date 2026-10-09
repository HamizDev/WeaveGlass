#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN
@interface WGSegmentedDockView : UIView
@property (nonatomic, weak, nullable) UITabBarController *controller;
- (void)reloadFromController;
- (void)updateSelection;
@end
NS_ASSUME_NONNULL_END
