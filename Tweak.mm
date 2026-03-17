#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <mach/mach.h>
#import <Foundation/Foundation.h>
#import "src/FeatureManager.h"
#import "src/OverlayMenuController.h"

// ── Ad URL blocking ──────────────────────────────────────
@interface VoyagerURLProtocol : NSURLProtocol @end
@implementation VoyagerURLProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    if (![FeatureManager shared].noAdsEnabled) return NO;
    NSString *url = request.URL.absoluteString.lowercaseString;
    NSArray *adDomains = @[
        @"admob", @"doubleclick", @"googleadservices",
        @"applovin", @"unity3d.com/ads", @"unityads",
        @"facebook.com/ads", @"fbcdn", @"mopub",
        @"vungle", @"ironsrc", @"appsflyer",
        @"adjust.com", @"tapjoy", @"chartboost",
        @"inmobi", @"adcolony", @"startapp",
        @"adtrace", @"singular.net"
    ];
    for (NSString *domain in adDomains)
        if ([url containsString:domain]) return YES;
    return NO;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)r { return r; }

- (void)startLoading {
    NSHTTPURLResponse *resp = [[NSHTTPURLResponse alloc]
        initWithURL:self.request.URL statusCode:200
        HTTPVersion:@"HTTP/1.1" headerFields:@{}];
    [self.client URLProtocol:self didReceiveResponse:resp
          cacheStoragePolicy:NSURLCacheStorageNotAllowed];
    [self.client URLProtocol:self didLoadData:[NSData data]];
    [self.client URLProtocolDidFinishLoading:self];
    NSLog(@"[VoyagerMenu] Blocked ad URL: %@", self.request.URL);
}
- (void)stopLoading {}
@end

// ── Coin freeze via NSUserDefaults hook ──────────────────
static NSInteger gFrozenCoins = -1;

@interface NSUserDefaults (VoyagerHook)
- (void)voy_setInteger:(NSInteger)value forKey:(NSString *)key;
- (NSInteger)voy_integerForKey:(NSString *)key;
@end
@implementation NSUserDefaults (VoyagerHook)
- (void)voy_setInteger:(NSInteger)value forKey:(NSString *)key {
    NSString *kl = key.lowercaseString;
    BOOL isCoin = [kl containsString:@"coin"] ||
                  [kl containsString:@"gold"] ||
                  [kl containsString:@"gem"]  ||
                  [kl containsString:@"star"] ||
                  [kl containsString:@"cash"] ||
                  [kl containsString:@"currency"] ||
                  [kl containsString:@"money"] ||
                  [kl containsString:@"credit"];
    if (isCoin && [FeatureManager shared].coinsEnabled) {
        if (gFrozenCoins < 0) gFrozenCoins = MAX(value, 999999);
        NSLog(@"[VoyagerMenu] Coin freeze: key=%@ frozen=%ld", key, (long)gFrozenCoins);
        [self voy_setInteger:gFrozenCoins forKey:key];
        return;
    }
    [self voy_setInteger:value forKey:key];
}
- (NSInteger)voy_integerForKey:(NSString *)key {
    NSString *kl = key.lowercaseString;
    BOOL isCoin = [kl containsString:@"coin"] ||
                  [kl containsString:@"gold"] ||
                  [kl containsString:@"gem"]  ||
                  [kl containsString:@"star"] ||
                  [kl containsString:@"cash"] ||
                  [kl containsString:@"currency"] ||
                  [kl containsString:@"money"] ||
                  [kl containsString:@"credit"];
    if (isCoin && [FeatureManager shared].coinsEnabled) {
        NSInteger orig = [self voy_integerForKey:key];
        if (gFrozenCoins < 0 && orig > 0) gFrozenCoins = orig;
        return gFrozenCoins > 0 ? gFrozenCoins : 999999;
    }
    return [self voy_integerForKey:key];
}
@end

// ── Drag button ──────────────────────────────────────────
static UIButton *gTriggerButton = nil;

@interface UIButton (GMDrag)
- (void)gm_handlePan:(UIPanGestureRecognizer *)g;
@end
@implementation UIButton (GMDrag)
- (void)gm_handlePan:(UIPanGestureRecognizer *)g {
    CGPoint d = [g translationInView:self.superview];
    CGRect f  = self.frame, s = [UIScreen mainScreen].bounds;
    self.frame = CGRectMake(
        MAX(0, MIN(f.origin.x+d.x, s.size.width -f.size.width)),
        MAX(44, MIN(f.origin.y+d.y, s.size.height-f.size.height-34)),
        f.size.width, f.size.height);
    [g setTranslation:CGPointZero inView:self.superview];
}
@end

static void InstallButton(UIWindow *win) {
    if (gTriggerButton || !win) return;
    CGFloat sw = win.bounds.size.width;
    gTriggerButton = [UIButton buttonWithType:UIButtonTypeCustom];
    gTriggerButton.frame = CGRectMake(sw-65, 130, 55, 55);
    gTriggerButton.backgroundColor =
        [UIColor colorWithRed:0.10f green:0.48f blue:1.f alpha:.92f];
    gTriggerButton.layer.cornerRadius  = 27.5f;
    gTriggerButton.layer.masksToBounds = YES;
    gTriggerButton.layer.zPosition     = 99999;
    gTriggerButton.layer.shadowOpacity = 0.4f;
    [gTriggerButton setTitle:@"🎮" forState:UIControlStateNormal];
    gTriggerButton.titleLabel.font = [UIFont systemFontOfSize:24];
    [gTriggerButton addTarget:[OverlayMenuController shared]
                       action:@selector(toggle)
             forControlEvents:UIControlEventTouchUpInside];
    [gTriggerButton addGestureRecognizer:
        [[UIPanGestureRecognizer alloc]
            initWithTarget:gTriggerButton action:@selector(gm_handlePan:)]];
    [win addSubview:gTriggerButton];
    NSLog(@"[VoyagerMenu] button installed ✓");
}

// ── UIViewController swizzle ─────────────────────────────
static void swizzle(Class c, SEL orig, SEL swiz) {
    Method o = class_getInstanceMethod(c, orig);
    Method s = class_getInstanceMethod(c, swiz);
    if (o && s) method_exchangeImplementations(o, s);
}

@interface UIViewController (VoyagerHook)
- (void)voy_viewDidAppear:(BOOL)animated;
@end
@implementation UIViewController (VoyagerHook)
- (void)voy_viewDidAppear:(BOOL)animated {
    [self voy_viewDidAppear:animated];
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
                       (int64_t)(.8*NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            UIWindow *win = nil;
            for (UIScene *sc in [UIApplication sharedApplication].connectedScenes)
                if ([sc isKindOfClass:[UIWindowScene class]])
                    for (UIWindow *w in ((UIWindowScene*)sc).windows)
                        if (w.isKeyWindow) { win = w; break; }
            InstallButton(win);
        });
    });
}
@end

// ── Constructor ──────────────────────────────────────────
__attribute__((constructor))
static void voyager_init(void) {
    @autoreleasepool {
        NSLog(@"[VoyagerMenu] v2 loading...");

        // Register ad blocker
        [NSURLProtocol registerClass:[VoyagerURLProtocol class]];

        // Swizzle NSUserDefaults for coin freeze
        swizzle([NSUserDefaults class],
                @selector(setInteger:forKey:),
                @selector(voy_setInteger:forKey:));
        swizzle([NSUserDefaults class],
                @selector(integerForKey:),
                @selector(voy_integerForKey:));

        // Swizzle UIViewController for button install
        swizzle([UIViewController class],
                @selector(viewDidAppear:),
                @selector(voy_viewDidAppear:));

        NSLog(@"[VoyagerMenu] v2 loaded ✓");
    }
}
