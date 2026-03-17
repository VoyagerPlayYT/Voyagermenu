#import "OverlayMenuController.h"
#import "FeatureManager.h"
#import "RuntimeScanner.h"

static const CGFloat kMenuWidth    = 260.0f;
static const CGFloat kButtonHeight = 50.0f;
static const CGFloat kSpacing      = 10.0f;
static const CGFloat kPadding      = 16.0f;
static const CGFloat kTitleHeight  = 44.0f;
static const CGFloat kCornerRadius = 16.0f;

@interface OverlayMenuController ()
@property (nonatomic, strong) UIVisualEffectView *blurContainer;
@property (nonatomic, strong) UILabel            *titleLabel;
@property (nonatomic, strong) UIButton           *closeButton;
@property (nonatomic, strong) NSMutableArray     *featureButtons;
@property (nonatomic, strong) NSArray<NSNumber *> *detectedFeatures;
@property (nonatomic, strong) UIPanGestureRecognizer *panGesture;
@property (nonatomic, assign) CGPoint             panOffset;
@end

@implementation OverlayMenuController

+ (instancetype)shared {
    static OverlayMenuController *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[OverlayMenuController alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _featureButtons   = [NSMutableArray array];
        _detectedFeatures = [RuntimeScanner detectAvailableFeatures];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];
    [self buildMenu];
}

- (void)buildMenu {
    NSUInteger count   = self.detectedFeatures.count;
    CGFloat menuHeight = kTitleHeight + kPadding
                       + count * (kButtonHeight + kSpacing)
                       + kPadding;

    CGRect  screen  = [UIScreen mainScreen].bounds;
    CGFloat originX = screen.size.width  - kMenuWidth  - 20.0f;
    CGFloat originY = screen.size.height / 2.0f - menuHeight / 2.0f;

    UIBlurEffect *blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    self.blurContainer = [[UIVisualEffectView alloc] initWithEffect:blur];
    self.blurContainer.frame = CGRectMake(originX, originY, kMenuWidth, menuHeight);
    self.blurContainer.layer.cornerRadius  = kCornerRadius;
    self.blurContainer.layer.masksToBounds = YES;
    self.blurContainer.alpha = 0.0f;
    [self.view addSubview:self.blurContainer];

    self.panGesture = [[UIPanGestureRecognizer alloc]
                        initWithTarget:self action:@selector(handlePan:)];
    [self.blurContainer addGestureRecognizer:self.panGesture];

    self.titleLabel = [[UILabel alloc] initWithFrame:
        CGRectMake(kPadding, 0, kMenuWidth - 2*kPadding - 30, kTitleHeight)];
    self.titleLabel.text          = @"🎮 Game Menu";
    self.titleLabel.textColor     = [UIColor whiteColor];
    self.titleLabel.font          = [UIFont boldSystemFontOfSize:17.0f];
    [self.blurContainer.contentView addSubview:self.titleLabel];

    self.closeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.closeButton.frame = CGRectMake(kMenuWidth - 38, 7, 30, 30);
    [self.closeButton setTitle:@"✕" forState:UIControlStateNormal];
    self.closeButton.tintColor = [UIColor colorWithWhite:0.7f alpha:1.0f];
    [self.closeButton addTarget:self action:@selector(closeButtonTapped)
               forControlEvents:UIControlEventTouchUpInside];
    [self.blurContainer.contentView addSubview:self.closeButton];

    UIView *divider = [[UIView alloc] initWithFrame:
        CGRectMake(0, kTitleHeight, kMenuWidth, 1.0f / [UIScreen mainScreen].scale)];
    divider.backgroundColor = [UIColor colorWithWhite:0.6f alpha:0.3f];
    [self.blurContainer.contentView addSubview:divider];

    [self.featureButtons removeAllObjects];
    for (NSUInteger idx = 0; idx < count; idx++) {
        GameFeature feat = (GameFeature)[self.detectedFeatures[idx] unsignedIntegerValue];
        UIButton *btn = [self makeButtonForFeature:feat atIndex:idx];
        [self.blurContainer.contentView addSubview:btn];
        [self.featureButtons addObject:btn];
    }
}

- (UIButton *)makeButtonForFeature:(GameFeature)feature atIndex:(NSUInteger)idx {
    CGFloat y  = kTitleHeight + kPadding + idx * (kButtonHeight + kSpacing);
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = CGRectMake(kPadding, y, kMenuWidth - 2*kPadding, kButtonHeight);
    btn.layer.cornerRadius  = 10.0f;
    btn.layer.masksToBounds = YES;
    btn.tag = (NSInteger)feature;
    [self updateButton:btn forFeature:feature active:NO];
    [btn addTarget:self action:@selector(featureButtonTapped:)
  forControlEvents:UIControlEventTouchUpInside];
    return btn;
}

- (void)updateButton:(UIButton *)btn forFeature:(GameFeature)feature active:(BOOL)active {
    NSString *base  = [self titleForFeature:feature];
    NSString *icon  = active ? @"✅ " : @"⬜ ";
    NSString *state = active ? @" Activated" : @" Disabled";
    [btn setTitle:[NSString stringWithFormat:@"%@%@%@", icon, base, state]
         forState:UIControlStateNormal];
    btn.titleLabel.font = [UIFont systemFontOfSize:14.0f weight:UIFontWeightMedium];
    btn.titleLabel.adjustsFontSizeToFitWidth = YES;
    btn.backgroundColor = active
        ? [UIColor colorWithRed:0.18f green:0.72f blue:0.33f alpha:0.85f]
        : [UIColor colorWithWhite:0.2f alpha:0.7f];
    [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    btn.layer.borderWidth = active ? 1.5f : 0.0f;
    btn.layer.borderColor = [UIColor colorWithRed:0.3f green:0.9f blue:0.5f alpha:0.6f].CGColor;
}

- (NSString *)titleForFeature:(GameFeature)feature {
    switch (feature) {
        case GameFeatureGodMode:        return @"God Mode";
        case GameFeatureUnlimitedCoins: return @"Unlimited Coins";
        case GameFeatureNoAds:          return @"No Ads";
        default:                        return @"Unknown Feature";
    }
}

- (void)featureButtonTapped:(UIButton *)sender {
    GameFeature feat = (GameFeature)sender.tag;
    FeatureManager *mgr = [FeatureManager shared];
    BOOL newState = NO;
    switch (feat) {
        case GameFeatureGodMode:
            mgr.godModeEnabled = !mgr.godModeEnabled;
            newState = mgr.godModeEnabled;
            NSLog(@"God Mode %@", newState ? @"Activated" : @"Deactivated");
            break;
        case GameFeatureUnlimitedCoins:
            mgr.coinsEnabled = !mgr.coinsEnabled;
            newState = mgr.coinsEnabled;
            NSLog(@"Unlimited Coins %@", newState ? @"Activated" : @"Deactivated");
            break;
        case GameFeatureNoAds:
            mgr.noAdsEnabled = !mgr.noAdsEnabled;
            newState = mgr.noAdsEnabled;
            NSLog(@"No Ads %@", newState ? @"Activated" : @"Deactivated");
            break;
    }
    [UIView animateWithDuration:0.2f animations:^{
        [self updateButton:sender forFeature:feat active:newState];
    }];
}

- (void)closeButtonTapped { [self hide]; }

- (void)handlePan:(UIPanGestureRecognizer *)gesture {
    UIView *menu  = self.blurContainer;
    CGPoint touch = [gesture locationInView:self.view];
    if (gesture.state == UIGestureRecognizerStateBegan) {
        self.panOffset = CGPointMake(touch.x - menu.frame.origin.x,
                                     touch.y - menu.frame.origin.y);
    } else if (gesture.state == UIGestureRecognizerStateChanged) {
        CGRect  screen = [UIScreen mainScreen].bounds;
        CGFloat nx = MAX(0, MIN(touch.x - self.panOffset.x,
                                screen.size.width  - menu.frame.size.width));
        CGFloat ny = MAX(0, MIN(touch.y - self.panOffset.y,
                                screen.size.height - menu.frame.size.height));
        menu.frame = CGRectMake(nx, ny, menu.frame.size.width, menu.frame.size.height);
    }
}

- (void)show {
    UIWindow *keyWindow = nil;
    for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
        if ([scene isKindOfClass:[UIWindowScene class]]) {
            for (UIWindow *w in ((UIWindowScene *)scene).windows)
                if (w.isKeyWindow) { keyWindow = w; break; }
        }
    }
    if (!keyWindow) return;
    self.view.frame = keyWindow.bounds;
    [keyWindow addSubview:self.view];
    [UIView animateWithDuration:0.35f delay:0
         usingSpringWithDamping:0.75f initialSpringVelocity:0.5f
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{ self.blurContainer.alpha = 1.0f; }
                     completion:nil];
}

- (void)hide {
    [UIView animateWithDuration:0.25f animations:^{
        self.blurContainer.alpha = 0.0f;
        self.blurContainer.transform = CGAffineTransformMakeScale(0.92f, 0.92f);
    } completion:^(BOOL d) {
        [self.view removeFromSuperview];
        self.blurContainer.transform = CGAffineTransformIdentity;
    }];
}

- (void)toggle {
    self.view.superview ? [self hide] : [self show];
}

@end
