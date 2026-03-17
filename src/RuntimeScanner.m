#import "RuntimeScanner.h"
#import <objc/runtime.h>

@implementation RuntimeScanner

+ (NSArray<NSNumber *> *)detectAvailableFeatures {
    NSMutableArray<NSNumber *> *features = [NSMutableArray array];

    int classCount = objc_getClassList(NULL, 0);
    if (classCount <= 0) return features;

    Class *classes = (Class *)malloc(sizeof(Class) * classCount);
    if (!classes) return features;

    classCount = objc_getClassList(classes, classCount);

    BOOL foundPlayer = NO;
    BOOL foundCoin   = NO;
    BOOL foundAd     = NO;

    for (int i = 0; i < classCount; i++) {
        Class cls = classes[i];
        if (!cls) continue;
        const char *rawName = class_getName(cls);
        if (!rawName) continue;
        NSString *name = [[NSString stringWithUTF8String:rawName] uppercaseString];

        if (!foundPlayer && [name containsString:@"PLAYER"])   foundPlayer = YES;
        if (!foundCoin   && ([name containsString:@"COIN"] ||
                              [name containsString:@"CURRENCY"])) foundCoin = YES;
        if (!foundAd     && ([name containsString:@"ADMANAGER"] ||
                              [name containsString:@"ADVIEW"]    ||
                              [name containsString:@"ADMOB"]     ||
                              ([name hasPrefix:@"AD"] && name.length <= 12))) foundAd = YES;
    }

    free(classes);

    if (foundPlayer) [features addObject:@(GameFeatureGodMode)];
    if (foundCoin)   [features addObject:@(GameFeatureUnlimitedCoins)];
    if (foundAd)     [features addObject:@(GameFeatureNoAds)];

    return [features copy];
}

+ (BOOL)classExistsWithPrefix:(NSString *)prefix {
    int classCount = objc_getClassList(NULL, 0);
    if (classCount <= 0) return NO;

    Class *classes = (Class *)malloc(sizeof(Class) * classCount);
    if (!classes) return NO;

    classCount = objc_getClassList(classes, classCount);
    BOOL found = NO;

    for (int i = 0; i < classCount && !found; i++) {
        Class cls = classes[i];
        if (!cls) continue;
        const char *rawName = class_getName(cls);
        if (!rawName) continue;
        NSString *name = [[NSString stringWithUTF8String:rawName] uppercaseString];
        if ([name containsString:prefix.uppercaseString]) found = YES;
    }

    free(classes);
    return found;
}

@end
