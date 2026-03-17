#import "OverlayMenuController.h"
#import "FeatureManager.h"

@interface OverlayMenuController ()
@property (nonatomic, strong) UIVisualEffectView *container;
@property (nonatomic, strong) NSMutableArray     *buttons;
@property (nonatomic, assign) CGPoint             panOffset;
@end

@implementation OverlayMenuController

+ (instancetype)shared {
    static OverlayMenuController *i = nil;
    static dispatch_once_t t;
    dispatch_once(&t, ^{ i = [[OverlayMenuController alloc] init]; });
    return i;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];
    [self buildMenu];
}

- (void)buildMenu {
    NSArray *features = @[@"🪙 Unlimited Coins", @"🚫 No Ads", @"⚡ Speed Hack"];
    CGFloat w = 260, bh = 48, pad = 14, th = 44;
    CGFloat h = th + pad + features.count * (bh + 10) + pad;
    CGRect  scr = [UIScreen mainScreen].bounds;

    UIBlurEffect *blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    self.container = [[UIVisualEffectView alloc] initWithEffect:blur];
    self.container.frame = CGRectMake(scr.size.width-w-16,
                                      scr.size.height/2-h/2, w, h);
    self.container.layer.cornerRadius  = 18;
    self.container.layer.masksToBounds = YES;
    self.container.alpha = 0;
    [self.view addSubview:self.container];

    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc]
        initWithTarget:self action:@selector(handlePan:)];
    [self.container addGestureRecognizer:pan];

    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(pad, 0, w-2*pad-30, th)];
    title.text      = @"🎮 VoyagerMenu";
    title.textColor = [UIColor whiteColor];
    title.font      = [UIFont boldSystemFontOfSize:17];
    [self.container.contentView addSubview:title];

    UIButton *close = [UIButton buttonWithType:UIButtonTypeSystem];
    close.frame = CGRectMake(w-38, 8, 28, 28);
    [close setTitle:@"✕" forState:UIControlStateNormal];
    close.tintColor = [UIColor colorWithWhite:.7 alpha:1];
    [close addTarget:self action:@selector(hide)
    forControlEvents:UIControlEventTouchUpInside];
    [self.container.contentView addSubview:close];

    UIView *div = [[UIView alloc] initWithFrame:CGRectMake(0, th, w, .5)];
    div.backgroundColor = [UIColor colorWithWhite:.6 alpha:.3];
    [self.container.contentView addSubview:div];

    self.buttons = [NSMutableArray array];
    for (NSUInteger i = 0; i < features.count; i++) {
        CGFloat y = th + pad + i*(bh+10);
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.frame = CGRectMake(pad, y, w-2*pad, bh);
        btn.layer.cornerRadius  = 12;
        btn.layer.masksToBounds = YES;
        btn.backgroundColor = [UIColor colorWithWhite:.2 alpha:.7];
        btn.tag = i;
        [btn setTitle:features[i] forState:UIControlStateNormal];
        btn.titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
        [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(btnTap:)
      forControlEvents:UIControlEventTouchUpInside];
        [self.container.contentView addSubview:btn];
        [self.buttons addObject:btn];
    }
}

- (void)btnTap:(UIButton *)btn {
    FeatureManager *m = [FeatureManager shared];
    BOOL on = NO;
    switch (btn.tag) {
        case 0: m.coinsEnabled   = !m.coinsEnabled;   on = m.coinsEnabled;   break;
        case 1: m.noAdsEnabled   = !m.noAdsEnabled;   on = m.noAdsEnabled;   break;
        case 2: m.godModeEnabled = !m.godModeEnabled; on = m.godModeEnabled; break;
    }
    NSLog(@"[VoyagerMenu] Feature %ld -> %@", (long)btn.tag, on?@"ON":@"OFF");
    [UIView animateWithDuration:.2 animations:^{
        btn.backgroundColor = on
            ? [UIColor colorWithRed:.15 green:.7 blue:.35 alpha:.85]
            : [UIColor colorWithWhite:.2 alpha:.7];
        NSString *titles[] = {@"🪙 Unlimited Coins", @"🚫 No Ads", @"⚡ Speed Hack"};
        NSString *suffix   = on ? @" ✅" : @"";
        [btn setTitle:[titles[btn.tag] stringByAppendingString:suffix]
             forState:UIControlStateNormal];
    }];
}

- (void)handlePan:(UIPanGestureRecognizer *)g {
    CGPoint t = [g locationInView:self.view];
    UIView *c = self.container;
    if (g.state == UIGestureRecognizerStateBegan)
        self.panOffset = CGPointMake(t.x-c.frame.origin.x, t.y-c.frame.origin.y);
    else if (g.state == UIGestureRecognizerStateChanged) {
        CGRect s = [UIScreen mainScreen].bounds;
        CGFloat nx = MAX(0, MIN(t.x-self.panOffset.x, s.size.width -c.frame.size.width));
        CGFloat ny = MAX(0, MIN(t.y-self.panOffset.y, s.size.height-c.frame.size.height));
        c.frame = CGRectMake(nx, ny, c.frame.size.width, c.frame.size.height);
    }
}

- (void)show {
    UIWindow *win = nil;
    for (UIScene *sc in [UIApplication sharedApplication].connectedScenes)
        if ([sc isKindOfClass:[UIWindowScene class]])
            for (UIWindow *w in ((UIWindowScene*)sc).windows)
                if (w.isKeyWindow) { win = w; break; }
    if (!win) return;
    self.view.frame = win.bounds;
    [win addSubview:self.view];
    [UIView animateWithDuration:.3 delay:0
         usingSpringWithDamping:.8 initialSpringVelocity:.5
                        options:0
                     animations:^{ self.container.alpha = 1; }
                     completion:nil];
}

- (void)hide {
    [UIView animateWithDuration:.2 animations:^{
        self.container.alpha = 0;
        self.container.transform = CGAffineTransformMakeScale(.95, .95);
    } completion:^(BOOL d) {
        [self.view removeFromSuperview];
        self.container.transform = CGAffineTransformIdentity;
    }];
}

- (void)toggle {
    self.view.superview ? [self hide] : [self show];
}
@end
