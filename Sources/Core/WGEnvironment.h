#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@interface WGEnvironment : NSObject
+ (BOOL)shouldActivate;
+ (NSString *)diagnosticSummary;
@end
NS_ASSUME_NONNULL_END
