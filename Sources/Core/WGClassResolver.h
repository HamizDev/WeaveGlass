#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN
// Only compares Objective-C class names and superclasses. Never calls private selectors.
@interface WGClassResolver : NSObject
+ (NSArray<NSString *> *)chatCandidates;
+ (NSArray<NSString *> *)homeCandidates;
+ (NSArray<NSString *> *)tabCandidates;
+ (BOOL)controller:(UIViewController *)controller matchesCandidates:(NSArray<NSString *> *)candidates;
+ (BOOL)controller:(UIViewController *)controller matchesPreferredName:(nullable NSString *)preferred
           fallbackCandidates:(NSArray<NSString *> *)candidates;
+ (NSArray<NSString *> *)presentCandidates:(NSArray<NSString *> *)candidates;
+ (NSString *)diagnosticSummary;
@end
NS_ASSUME_NONNULL_END
