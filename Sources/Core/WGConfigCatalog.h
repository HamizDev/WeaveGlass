#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN
@interface WGConfigCatalog : NSObject
+ (NSArray<NSString *> *)groupNames;
+ (NSArray<NSString *> *)keysForGroup:(NSString *)group;
+ (NSArray<NSString *> *)allKeys;
+ (BOOL)containsKey:(NSString *)key;
@end
NS_ASSUME_NONNULL_END
