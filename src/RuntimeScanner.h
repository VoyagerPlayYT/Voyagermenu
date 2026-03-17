#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, GameFeature) {
    GameFeatureGodMode        = 1 << 0,
    GameFeatureUnlimitedCoins = 1 << 1,
    GameFeatureNoAds          = 1 << 2,
};

@interface RuntimeScanner : NSObject

+ (NSArray<NSNumber *> *)detectAvailableFeatures;
+ (BOOL)classExistsWithPrefix:(NSString *)prefix;

@end
