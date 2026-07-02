//
//  HUDMainApplicationDelegate.mm
//  TrollSpeed
//
//  Created by Lessica on 2024/1/24.
//  Updated to force landscape window and embed only ESP view into container (2025).
//

#import <UIKit/UIKit.h>
#import <objc/runtime.h>

#import "HUDMainApplicationDelegate.h"
#import "HUDMainWindow.h"

#import "SBSAccessibilityWindowHostingController.h"
#import "UIWindow+Private.h"

#import "../esp/drawing_view/esp.h"
#import "UIView+SecureView.h"

// Pass-through view: forwards touches only to visible/interactive subviews;
// returns nil (not self) when no subview is hit, so touches fall through to the game.
@interface HUDPassthroughView : UIView
@end
@implementation HUDPassthroughView
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *hit = [super hitTest:point withEvent:event];
    return (hit == self) ? nil : hit;
}
@end


@interface HUDLandscapeContainerViewController : UIViewController
@property (nonatomic, strong) UIView *contentView;
@end

@implementation HUDLandscapeContainerViewController

- (void)loadView {
    // Use passthrough root view so the controller doesn't eat untargeted touches
    self.view = [[HUDPassthroughView alloc] initWithFrame:UIScreen.mainScreen.bounds];
    self.view.backgroundColor = [UIColor clearColor];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        // Создаем контейнер СРАЗУ в init, чтобы он не был nil при настройке делегата
        CGRect screenBounds = [UIScreen mainScreen].bounds;
        CGRect landscapeBounds = CGRectMake(0, 0, MAX(screenBounds.size.width, screenBounds.size.height), MIN(screenBounds.size.width, screenBounds.size.height));

        self.contentView = [[HUDPassthroughView alloc] initWithFrame:landscapeBounds];
        self.contentView.backgroundColor = [UIColor clearColor];
        self.contentView.transform = CGAffineTransformMakeRotation(M_PI_2);
        self.contentView.center = CGPointMake(screenBounds.size.width / 2, screenBounds.size.height / 2);
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];
    if (self.contentView) {
        [self.view addSubview:self.contentView];
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGRect screenBounds = [UIScreen mainScreen].bounds;
    self.contentView.center = CGPointMake(screenBounds.size.width / 2, screenBounds.size.height / 2);
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskLandscape;
}

- (BOOL)shouldAutorotate {
    return NO;
}
@end

#pragma mark - HUDMainApplicationDelegate

@implementation HUDMainApplicationDelegate {
    SBSAccessibilityWindowHostingController *_windowHostingController;
}

- (instancetype)init
{
    if (self = [super init])
    {
        //log_debug(OS_LOG_DEFAULT, "- [HUDMainApplicationDelegate init]");
    }
    return self;
}

- (UIInterfaceOrientation)currentInterfaceOrientation {
    if (@available(iOS 13.0, *)) {
        for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if ([scene isKindOfClass:[UIWindowScene class]]) {
                UIWindowScene *ws = (UIWindowScene *)scene;
                if (ws.activationState == UISceneActivationStateForegroundActive ||
                    ws.activationState == UISceneActivationStateForegroundInactive) {
                    return ws.interfaceOrientation;
                }
            }
        }
    }

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    UIInterfaceOrientation sb = [UIApplication sharedApplication].statusBarOrientation;
#pragma clang diagnostic pop
    if (sb != UIInterfaceOrientationUnknown) {
        return sb;
    }

    UIDeviceOrientation dev = [UIDevice currentDevice].orientation;
    if (UIDeviceOrientationIsLandscape(dev)) {
        return (dev == UIDeviceOrientationLandscapeLeft) ? UIInterfaceOrientationLandscapeRight : UIInterfaceOrientationLandscapeLeft;
    }
    return UIInterfaceOrientationLandscapeRight;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary <UIApplicationLaunchOptionsKey, id> *)launchOptions
{
    //log_debug(OS_LOG_DEFAULT, "- [HUDMainApplicationDelegate application:%{public}@ didFinishLaunchingWithOptions:%{public}@]", application, launchOptions);

    HUDLandscapeContainerViewController *container = [[HUDLandscapeContainerViewController alloc] init];

    ESP_View *espView = [[ESP_View alloc] initWithFrame:container.contentView.bounds];
    espView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [container.contentView addSubview:espView];
    espView.userInteractionEnabled = YES;
    [espView hideViewFromCapture:NO];



    self.window = [[HUDMainWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [self.window setRootViewController:container];
    NSLog(@"andrdevv [self.window] initWithFrame: %@", NSStringFromCGRect(self.window.frame));

    [self.window setWindowLevel:10000010.0];
    [self.window setHidden:NO];
    [self.window makeKeyAndVisible];

    [container.view setNeedsLayout];
    [container.view layoutIfNeeded];

    espView.frame = container.contentView.bounds;

    _windowHostingController = [[objc_getClass("SBSAccessibilityWindowHostingController") alloc] init];
    unsigned int _contextId = [self.window _contextId];
    double windowLevel = [self.window windowLevel];

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    NSMethodSignature *signature = [NSMethodSignature signatureWithObjCTypes:"v@:Id"];
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
    [invocation setTarget:_windowHostingController];
    [invocation setSelector:NSSelectorFromString(@"registerWindowWithContextID:atLevel:")];
    [invocation setArgument:&_contextId atIndex:2];
    [invocation setArgument:&windowLevel atIndex:3];
    [invocation invoke];
#pragma clang diagnostic pop

    return YES;
}

@end
