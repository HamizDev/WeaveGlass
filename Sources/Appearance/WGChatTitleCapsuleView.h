#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN
// Title-only capsule. Never fabricates contact avatars, contact status, or group size.
@interface WGChatTitleCapsuleView : UIView
- (instancetype)initWithTitle:(NSString *)title;
- (void)updateTitle:(NSString *)title;
@end
NS_ASSUME_NONNULL_END
