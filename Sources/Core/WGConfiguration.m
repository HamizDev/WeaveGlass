#import "WGConfiguration.h"
#import "WGConfigCatalog.h"

NSString *const WGSettingsDidChangeNotification = @"com.weaveglass.settings.did-change";
NSString *const WGPreferenceEnabled = @"wg_enabled";
NSString *const WGPreferenceNativeGlass = @"wg_tabbar_native_glass";
NSString *const WGPreferenceClearGlass = @"wg_tabbar_clear_glass";
NSString *const WGPreferenceCapsuleDock = @"wg_capsule_dock";
NSString *const WGPreferenceChatComposer = @"wg_chat_composer_glass";
NSString *const WGPreferenceHomeSearch = @"wg_home_search_glass";
NSString *const WGPreferenceChatTitleCapsule = @"wg_chat_title_capsule";
NSString *const WGPreferenceMorphDock = @"wg_morph_dock";
NSString *const WGPreferenceAutoClassMatch = @"wg_auto_class_match";
NSString *const WGPreferenceNavigationTint = @"wg_navigation_tint";
NSString *const WGPreferenceAccentHex = @"wg_accent_hex";
NSString *const WGPreferenceChatHostClass = @"wg_chat_host_class";
NSString *const WGPreferenceHomeHostClass = @"wg_home_host_class";
static NSArray<NSString *> *WGActiveKeys(void) {
    return @[WGPreferenceEnabled, WGPreferenceNativeGlass, WGPreferenceClearGlass,
             WGPreferenceCapsuleDock, WGPreferenceMorphDock, WGPreferenceChatComposer, WGPreferenceHomeSearch,
             WGPreferenceChatTitleCapsule, WGPreferenceAutoClassMatch,
             WGPreferenceNavigationTint, WGPreferenceAccentHex,
             WGPreferenceChatHostClass, WGPreferenceHomeHostClass];
}

@interface WGConfiguration ()
@property (nonatomic, strong) NSUserDefaults *defaults;
@end

@implementation WGConfiguration
+ (instancetype)shared {
    static WGConfiguration *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ instance = [[self alloc] initPrivate]; });
    return instance;
}
- (instancetype)initPrivate {
    if ((self = [super init])) {
        _defaults = [[NSUserDefaults alloc] initWithSuiteName:@"com.weaveglass.settings"];
        // Features that need host runtime verification are disabled by default.
        [_defaults registerDefaults:@{WGPreferenceEnabled: @YES,
                                      WGPreferenceNativeGlass: @NO, // Standard iOS 26 tab bars already supply glass.
                                      WGPreferenceClearGlass: @NO,
                                      WGPreferenceCapsuleDock: @NO,
                                      WGPreferenceMorphDock: @NO,
                                      WGPreferenceChatTitleCapsule: @NO,
                                      WGPreferenceAutoClassMatch: @NO,
                                      WGPreferenceChatComposer: @NO,
                                      WGPreferenceHomeSearch: @NO,
                                      WGPreferenceNavigationTint: @NO,
                                      WGPreferenceAccentHex: @"#008F85",
                                      WGPreferenceChatHostClass: @"BaseMsgContentViewController",
                                      WGPreferenceHomeHostClass: @"NewMainFrameViewController"}];
    }
    return self;
}
- (BOOL)isAllowedKey:(NSString *)key {
    if (!key.length) return NO;
    return [WGActiveKeys() containsObject:key] || [WGConfigCatalog containsKey:key];
}
- (id)valueForKeyName:(NSString *)key {
    if (![self isAllowedKey:key]) return nil;
    return [self.defaults objectForKey:key];
}
- (BOOL)boolForKeyName:(NSString *)key defaultValue:(BOOL)fallback {
    id value = [self valueForKeyName:key];
    return [value respondsToSelector:@selector(boolValue)] ? [value boolValue] : fallback;
}
- (void)setValue:(id)value forKeyName:(NSString *)key {
    if (![self isAllowedKey:key]) return;
    if ([key isEqualToString:WGPreferenceAccentHex] && value &&
        (![value isKindOfClass:NSString.class] || ((NSString *)value).length > 16)) return;
    if (([key isEqualToString:WGPreferenceChatHostClass] || [key isEqualToString:WGPreferenceHomeHostClass]) && value &&
        (![value isKindOfClass:NSString.class] || ((NSString *)value).length > 100)) return;
    if (value && ![NSPropertyListSerialization propertyList:@{ @"value": value } isValidForFormat:NSPropertyListBinaryFormat_v1_0]) {
        return;
    }
    if (value) [self.defaults setObject:value forKey:key];
    else [self.defaults removeObjectForKey:key];
    // In-process notification; does not touch WeChat's business data.
    [[NSNotificationCenter defaultCenter] postNotificationName:WGSettingsDidChangeNotification object:nil userInfo:@{@"key": key}];
}
- (NSDictionary<NSString *,id> *)exportKnownValues {
    NSMutableDictionary *values = [NSMutableDictionary dictionary];
    NSMutableArray *keys = [[WGConfigCatalog allKeys] mutableCopy];
    [keys addObjectsFromArray:WGActiveKeys()];
    for (NSString *key in keys) {
        id value = [self.defaults objectForKey:key];
        if (value) values[key] = value;
    }
    return [values copy];
}
- (BOOL)importKnownValues:(NSDictionary<NSString *,id> *)values error:(NSError **)error {
    if (![values isKindOfClass:[NSDictionary class]]) {
        if (error) *error = [NSError errorWithDomain:@"WeaveGlass" code:1 userInfo:@{NSLocalizedDescriptionKey: @"备份格式不是字典"}];
        return NO;
    }
    // Validate entire payload before applying it, so an invalid plist cannot partially import.
    for (id key in values) {
        id value = values[key];
        if (![key isKindOfClass:NSString.class] || ![self isAllowedKey:key] ||
            ![NSPropertyListSerialization propertyList:@{ @"value": value } isValidForFormat:NSPropertyListBinaryFormat_v1_0] ||
            (([key isEqual:WGPreferenceChatHostClass] || [key isEqual:WGPreferenceHomeHostClass]) &&
             (![value isKindOfClass:NSString.class] || ((NSString *)value).length > 100)) ||
            ([key isEqual:WGPreferenceAccentHex] && (![value isKindOfClass:NSString.class] || ((NSString *)value).length > 16))) {
            if (error) *error = [NSError errorWithDomain:@"WeaveGlass" code:2 userInfo:@{NSLocalizedDescriptionKey: @"包含不支持的配置键或配置值"}];
            return NO;
        }
    }
    for (NSString *key in values) [self.defaults setObject:values[key] forKey:key];
    [[NSNotificationCenter defaultCenter] postNotificationName:WGSettingsDidChangeNotification object:nil userInfo:nil];
    return YES;
}
- (void)resetActiveAppearancePreferences {
    for (NSString *key in WGActiveKeys()) [self.defaults removeObjectForKey:key];
    [[NSNotificationCenter defaultCenter] postNotificationName:WGSettingsDidChangeNotification object:nil userInfo:nil];
}
@end
