#import "FeatureManager.h"
@implementation FeatureManager
+ (instancetype)shared {
    static FeatureManager *i = nil;
    static dispatch_once_t t;
    dispatch_once(&t, ^{ i = [[FeatureManager alloc] init]; });
    return i;
}
- (instancetype)init {
    self = [super init];
    if (self) { _godModeEnabled = NO; _coinsEnabled = NO; _noAdsEnabled = NO; }
    return self;
}
@end
