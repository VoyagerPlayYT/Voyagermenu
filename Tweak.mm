#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "src/FeatureManager.h"
#import "src/OverlayMenuController.h"
#import "src/RuntimeScanner.h"

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
    gTriggerButton.frame = CGRectMake(sw-60, 120, 50, 50);
    gTriggerButton.backgroundColor =
        [UIColor colorWithRed:0.12f green:0.55f blue:1.f alpha:.9f];
    gTriggerButton.layer.cornerRadius  = 25;
    gTriggerButton.layer.masksToBounds = YES;
    gTriggerButton.layer.zPosition     = 99999;
    [gTriggerButton setTitle:@"🎮" forState:UIControlStateNormal];
    gTriggerButton.titleLabel.font = [UIFont systemFontOfSize:22];
    [gTriggerButton addTarget:[OverlayMenuController shared]
                       action:@selector(toggle)
             forControlEvents:UIControlEventTouchUpInside];
    [gTriggerButton addGestureRecognizer:
        [[UIPanGestureRecognizer alloc]
            initWithTarget:gTriggerButton action:@selector(gm_handlePan:)]];
    [win addSubview:gTriggerButton];
    NSLog(@"[VoyagerMenu] button installed");
}

// ── Pure ObjC swizzle (no Substrate/Logos) ───────────────
static void swizzle(Class cls, SEL orig, SEL swiz) {
    Method o = class_getInstanceMethod(cls, orig);
    Method s = class_getInstanceMethod(cls, swiz);
    if (o && s) method_exchangeImplementations(o, s);
}

// UIViewController swizzle — install button on first appear
@interface UIViewController (VoyagerHook)
- (void)voy_viewDidAppear:(BOOL)animated;
@end
@implementation UIViewController (VoyagerHook)
- (void)voy_viewDidAppear:(BOOL)animated {
    [self voy_viewDidAppear:animated]; // calls original
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
                       (int64_t)(0.5*NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            UIWindow *win = nil;
            for (UIScene *sc in [UIApplication sharedApplication].connectedScenes)
                if ([sc isKindOfClass:[UIWindowScene class]])
                    for (UIWindow *w in ((UIWindowScene *)sc).windows)
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
        NSLog(@"[VoyagerMenu] constructor fired");

        // Swizzle UIViewController
        swizzle([UIViewController class],
                @selector(viewDidAppear:),
                @selector(voy_viewDidAppear:));

        // Feature hooks (only if class exists)
        NSLog(@"[VoyagerMenu] init done");
    }
}
