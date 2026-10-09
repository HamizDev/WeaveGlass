#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN
FOUNDATION_EXPORT NSString *const WGSettingsDidChangeNotification;
FOUNDATION_EXPORT NSString *const WGPreferenceEnabled;
FOUNDATION_EXPORT NSString *const WGPreferenceNativeGlass;
FOUNDATION_EXPORT NSString *const WGPreferenceClearGlass;
FOUNDATION_EXPORT NSString *const WGPreferenceCapsuleDock;
FOUNDATION_EXPORT NSString *const WGPreferenceChatComposer;
FOUNDATION_EXPORT NSString *const WGPreferenceHomeSearch;
FOUNDATION_EXPORT NSString *const WGPreferenceChatTitleCapsule;
FOUNDATION_EXPORT NSString *const WGPreferenceMorphDock;
FOUNDATION_EXPORT NSString *const WGPreferenceAutoClassMatch;
FOUNDATION_EXPORT NSString *const WGPreferenceNavigationTint;
FOUNDATION_EXPORT NSString *const WGPreferenceAccentHex;
FOUNDATION_EXPORT NSString *const WGPreferenceChatHostClass;
FOUNDATION_EXPORT NSString *const WGPreferenceHomeHostClass;

@interface WGConfiguration : NSObject
+ (instancetype)shared;
- (nullable id)valueForKeyName:(NSString *)key;
- (BOOL)boolForKeyName:(NSString *)key defaultValue:(BOOL)fallback;
- (void)setValue:(nullable id)value forKeyName:(NSString *)key;
- (NSDictionary<NSString *,id> *)exportKnownValues;
- (void)resetActiveAppearancePreferences;
- (BOOL)importKnownValues:(NSDictionary<NSString *, id> *)values error:(NSError **)error;
@end
NS_ASSUME_NONNULL_END
