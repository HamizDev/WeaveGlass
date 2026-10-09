#import "WGClassResolver.h"
#import <objc/runtime.h>
@implementation WGClassResolver
+ (NSArray<NSString *> *)chatCandidates {
    return @[@"BaseMsgContentViewController", @"WCBaseMsgContentViewController", @"ChatRoomViewController"];
}
+ (NSArray<NSString *> *)homeCandidates {
    return @[@"NewMainFrameViewController", @"NewMainFrameViewControllerLite",
             @"WCNewMainFrameViewController", @"HomeViewController"];
}
+ (NSArray<NSString *> *)tabCandidates {
    return @[@"MMTabBarController", @"MMTabBarControllerLite", @"MainTabBarController"];
}
+ (BOOL)controller:(UIViewController *)controller matchesCandidates:(NSArray<NSString *> *)candidates {
    if (!controller || !candidates.count) return NO;
    NSSet<NSString *> *names = [NSSet setWithArray:candidates];
    for (Class klass = object_getClass(controller); klass && klass != NSObject.class;
         klass = class_getSuperclass(klass)) {
        if ([names containsObject:NSStringFromClass(klass)]) return YES;
    }
    return NO;
}
+ (BOOL)controller:(UIViewController *)controller matchesPreferredName:(NSString *)preferred
           fallbackCandidates:(NSArray<NSString *> *)candidates {
    // Explicit user choice takes precedence and disables automatic fallback.
    if ([preferred isKindOfClass:NSString.class] && preferred.length > 0 &&
        ![preferred isEqualToString:@"auto"]) {
        return [self controller:controller matchesCandidates:@[preferred]];
    }
    // Auto-detection is opt-in: an unknown class never inherits an appearance change.
    return [self controller:controller matchesCandidates:candidates];
}
+ (NSArray<NSString *> *)presentCandidates:(NSArray<NSString *> *)candidates {
    NSMutableArray<NSString *> *found = [NSMutableArray array];
    for (NSString *name in candidates) if (NSClassFromString(name)) [found addObject:name];
    return found;
}
+ (NSString *)diagnosticSummary {
    return [NSString stringWithFormat:@"聊天候选（已加载）：%@\n首页候选（已加载）：%@\n标签栏候选（已加载）：%@",
            [[self presentCandidates:self.chatCandidates] componentsJoinedByString:@", "] ?: @"",
            [[self presentCandidates:self.homeCandidates] componentsJoinedByString:@", "] ?: @"",
            [[self presentCandidates:self.tabCandidates] componentsJoinedByString:@", "] ?: @""];
}
@end
