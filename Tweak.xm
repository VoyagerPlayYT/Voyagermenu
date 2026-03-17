#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "src/FeatureManager.h"
#import "src/OverlayMenuController.h"
#import "src/RuntimeScanner.h"

static UIButton *gTriggerButton = nil;

static void InstallTriggerButton(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (gTriggerButton) return;
        UIWindow *keyWindow = nil;
        for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if ([scene isKindOfClass:[UIWindowScene class]])
                for (UIWindow *w in ((UIWindowScene *)scene).windows)
                    if (w.isKeyWindow) { keyWindow = w; break; }
        }
        if (!keyWindow) return;

        gTriggerButton = [UIButton buttonWithType:UIButtonTypeCustom];
        gTriggerButton.frame = CGRectMake(
            [UIScreen mainScreen].bounds.size.width - 60, 120, 50, 50);
        gTriggerButton.backgroundColor =
            [UIColor colorWithRed:0.12f green:0.55f blue:1.0f alpha:0.9f];
        gTriggerButton.layer.cornerRadius  = 25;
        gTriggerButton.layer.masksToBounds = YES;
        [gTriggerButton setTitle:@"🎮" forState:UIControlStateNormal];
        gTriggerButton.titleLabel.font = [UIFont systemFontOfSize:22.0f];
        [gTriggerButton addTarget:[OverlayMenuController shared]
                           action:@selector(toggle)
                 forControlEvents:UIControlEventTouchUpInside];
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc]
            initWithTarget:gTriggerButton action:@selector(gm_handlePan:)];
        [gTriggerButton addGestureRecognizer:pan];
        [keyWindow addSubview:gTriggerButton];
    });
}

@interface UIButton (GMDrag)
- (void)gm_handlePan:(UIPanGestureRecognizer *)g;
@end
@implementation UIButton (GMDrag)
- (void)gm_handlePan:(UIPanGestureRecognizer *)g {
    CGPoint delta  = [g translationInView:self.superview];
    CGRect  frame  = self.frame;
    CGRect  screen = [UIScreen mainScreen].bounds;
    CGFloat nx = MAX(0, MIN(frame.origin.x + delta.x, screen.size.width  - frame.size.width));
    CGFloat ny = MAX(44, MIN(frame.origin.y + delta.y, screen.size.height - frame.size.height - 34));
    self.frame = CGRectMake(nx, ny, frame.size.width, frame.size.height);
    [g setTranslation:CGPointZero inView:self.superview];
}
@end

%hook UIApplication
- (void)applicationDidBecomeActive:(UIApplication *)app {
    %orig;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ InstallTriggerButton(); });
}
%end

%group GodMode
%hook Player
- (void)setHealth:(int)v {
    [FeatureManager shared].godModeEnabled ? %orig(9999) : %orig(v);
}
- (int)health {
    return [FeatureManager shared].godModeEnabled ? 9999 : %orig;
}
- (void)takeDamage:(int)d {
    if (![FeatureManager shared].godModeEnabled) %orig(d);
}
%end
%end

%group UnlimitedCoins
%hook Coin
- (int)amount {
    return [FeatureManager shared].coinsEnabled ? INT_MAX : %orig;
}
- (void)setAmount:(int)a {
    [FeatureManager shared].coinsEnabled ? %orig(INT_MAX) : %orig(a);
}
%end
%hook Currency
- (long long)balance {
    return [FeatureManager shared].coinsEnabled ? LLONG_MAX : %orig;
}
- (void)setBalance:(long long)b {
    [FeatureManager shared].coinsEnabled ? %orig(LLONG_MAX) : %orig(b);
}
- (void)deductAmount:(long long)a {
    if (![FeatureManager shared].coinsEnabled) %orig(a);
}
%end
%end

%group NoAds
%hook AdManager
- (BOOL)shouldShowAd {
    if ([FeatureManager shared].noAdsEnabled) { NSLog(@"No Ads Activated"); return NO; }
    return %orig;
}
- (void)showInterstitialAd { if (![FeatureManager shared].noAdsEnabled) %orig; }
- (void)showBannerAd       { if (![FeatureManager shared].noAdsEnabled) %orig; }
- (void)showRewardedAd     { if (![FeatureManager shared].noAdsEnabled) %orig; }
%end
%end

%ctor {
    @autoreleasepool {
        NSLog(@"[OverlayMenu] Loaded — scanning classes...");
        if (objc_getClass("Player"))    { NSLog(@"[OverlayMenu] Player found");    %init(GodMode); }
        if (objc_getClass("Coin") ||
            objc_getClass("Currency"))  { NSLog(@"[OverlayMenu] Coin found");      %init(UnlimitedCoins); }
        if (objc_getClass("AdManager")) { NSLog(@"[OverlayMenu] AdManager found"); %init(NoAds); }
        %init(_ungrouped);
    }
}
