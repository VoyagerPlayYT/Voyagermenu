#import <Foundation/Foundation.h>

@interface FeatureManager : NSObject

@property (nonatomic, assign) BOOL godModeEnabled;
@property (nonatomic, assign) BOOL coinsEnabled;
@property (nonatomic, assign) BOOL noAdsEnabled;

+ (instancetype)shared;

@end
