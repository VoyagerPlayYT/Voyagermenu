#import <UIKit/UIKit.h>
@interface OverlayMenuController : UIViewController
+ (instancetype)shared;
- (void)show;
- (void)hide;
- (void)toggle;
@end
