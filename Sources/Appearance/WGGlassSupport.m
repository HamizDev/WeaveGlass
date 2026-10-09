#import <math.h>
#import "WGGlassSupport.h"
#import "WGConfiguration.h"
@implementation WGGlassSupport
+ (BOOL)isGlassUsable {
    return !UIAccessibilityIsReduceTransparencyEnabled() && NSClassFromString(@"UIGlassEffect") != Nil;
}
+ (UIColor *)colorFromHex:(NSString *)hex {
    if (![hex isKindOfClass:NSString.class]) return nil;
    NSString *s = [[hex stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet] uppercaseString];
    if ([s hasPrefix:@"#"]) s = [s substringFromIndex:1];
    if (s.length != 6) return nil;
    for (NSUInteger i = 0; i < s.length; i++) {
        if (![[NSCharacterSet characterSetWithCharactersInString:@"0123456789ABCDEF"] characterIsMember:[s characterAtIndex:i]]) return nil;
    }
    unsigned value = 0;
    if (![[NSScanner scannerWithString:s] scanHexInt:&value]) return nil;
    return [UIColor colorWithRed:((value >> 16) & 255) / 255.0
                          green:((value >> 8) & 255) / 255.0
                           blue:(value & 255) / 255.0 alpha:1];
}
+ (UIColor *)accentColor {
    id stored = [WGConfiguration.shared valueForKeyName:WGPreferenceAccentHex];
    UIColor *parsed = [self colorFromHex:[stored isKindOfClass:NSString.class] ? stored : @""];
    return parsed ?: UIColor.systemTealColor;
}
+ (NSString *)hexFromColor:(UIColor *)color {
    UIColor *rgb = [color resolvedColorWithTraitCollection:UITraitCollection.currentTraitCollection];
    CGFloat r=0,g=0,b=0,a=0;
    if (![rgb getRed:&r green:&g blue:&b alpha:&a]) return @"#008F85";
    return [NSString stringWithFormat:@"#%02X%02X%02X", (unsigned)lround(r*255), (unsigned)lround(g*255), (unsigned)lround(b*255)];
}
@end
