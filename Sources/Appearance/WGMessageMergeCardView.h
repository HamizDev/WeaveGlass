#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN
// Presentation-only component. Entries are supplied by caller: no host database access.
@interface WGMessageMergeCardView : UIView
- (instancetype)initWithMessages:(NSArray<NSDictionary<NSString *,NSString *> *> *)messages;
@end
NS_ASSUME_NONNULL_END
