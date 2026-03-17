#import "FeatureManager.h"

@implementation FeatureManager

+ (instancetype)shared {
    static FeatureManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[FeatureManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _godModeEnabled = NO;
        _coinsEnabled   = NO;
        _noAdsEnabled   = NO;
    }
    return self;
}

@end
