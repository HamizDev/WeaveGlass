#import "WGEnvironment.h"
#import <UIKit/UIKit.h>
@implementation WGEnvironment
+ (BOOL)shouldActivate {
    if (![[NSBundle mainBundle].bundleIdentifier isEqualToString:@"com.tencent.xin"]) return NO;
    return [NSProcessInfo processInfo].operatingSystemVersion.majorVersion >= 26;
}
+ (NSString *)diagnosticSummary {
    NSOperatingSystemVersion os = NSProcessInfo.processInfo.operatingSystemVersion;
    return [NSString stringWithFormat:@"WeaveGlass 0.3.0\nBundle: %@\niOS: %ld.%ld.%ld\nNative UIGlassEffect: %@\nActivated: %@",
            NSBundle.mainBundle.bundleIdentifier ?: @"(unknown)", (long)os.majorVersion,
            (long)os.minorVersion, (long)os.patchVersion,
            NSClassFromString(@"UIGlassEffect") ? @"YES" : @"NO",
            [self shouldActivate] ? @"YES" : @"NO"];
}
@end
