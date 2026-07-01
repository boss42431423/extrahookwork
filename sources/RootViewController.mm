//
//  RootViewController.mm
//  extrahook — injector
//

#import <notify.h>
#import "HUDHelper.h"
#import "MainApplication.h"
#import "RootViewController.h"
#import "UIApplication+Private.h"

@implementation RootViewController {
    UIView   *_statusDot;
    UILabel  *_statusLbl;
    UIButton *_mainBtn;
}

- (void)loadView {
    CGRect b = UIScreen.mainScreen.bounds;
    self.view = [[UIView alloc] initWithFrame:b];
    self.view.backgroundColor = [UIColor colorWithRed:0.05f green:0.05f blue:0.09f alpha:1.0f];

    self.backgroundView = [[UIView alloc] initWithFrame:b];
    self.backgroundView.autoresizingMask =
        UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.backgroundView.backgroundColor = UIColor.clearColor;
    [self.view addSubview:self.backgroundView];

    [self buildInjectUI];
}

- (void)buildInjectUI {
    CGRect  sc  = UIScreen.mainScreen.bounds;
    CGFloat W   = sc.size.width;
    CGFloat H   = sc.size.height;
    CGFloat cw  = MIN(W - 48.0f, 300.0f);
    CGFloat ch  = 264.0f;
    CGFloat cx  = (W - cw) * 0.5f;
    CGFloat cy  = (H - ch) * 0.5f;

    // Shadow wrapper (masksToBounds = NO so shadow shows)
    UIView *shadow = [[UIView alloc] initWithFrame:CGRectMake(cx, cy, cw, ch)];
    shadow.backgroundColor     = UIColor.clearColor;
    shadow.layer.shadowColor   = [UIColor colorWithRed:0.5f green:0.0f blue:1.0f alpha:0.45f].CGColor;
    shadow.layer.shadowOffset  = CGSizeMake(0, 10);
    shadow.layer.shadowRadius  = 24;
    shadow.layer.shadowOpacity = 1.0f;
    [self.view addSubview:shadow];

    // Card (clips contents)
    UIView *card = [[UIView alloc] initWithFrame:CGRectMake(0, 0, cw, ch)];
    card.backgroundColor     = [UIColor colorWithRed:0.10f green:0.10f blue:0.14f alpha:1.0f];
    card.layer.cornerRadius  = 18;
    card.layer.masksToBounds = YES;
    [shadow addSubview:card];

    // Purple top stripe
    UIView *stripe = [[UIView alloc] initWithFrame:CGRectMake(0, 0, cw, 3)];
    stripe.backgroundColor = [UIColor colorWithRed:0.62f green:0.12f blue:0.95f alpha:1.0f];
    [card addSubview:stripe];

    // App icon
    CGFloat iSz = 54;
    UIView *iconBg = [[UIView alloc] initWithFrame:CGRectMake((cw - iSz) * 0.5f, 22, iSz, iSz)];
    iconBg.backgroundColor    = [UIColor colorWithRed:0.62f green:0.12f blue:0.95f alpha:1.0f];
    iconBg.layer.cornerRadius = 14;
    [card addSubview:iconBg];

    UILabel *iconL = [[UILabel alloc] initWithFrame:iconBg.bounds];
    iconL.text          = @"⚡";   // ⚡
    iconL.font          = [UIFont systemFontOfSize:26];
    iconL.textAlignment = NSTextAlignmentCenter;
    [iconBg addSubview:iconL];

    // Title
    UILabel *titleL = [[UILabel alloc] initWithFrame:CGRectMake(0, 88, cw, 26)];
    titleL.text          = @"extrahook";
    titleL.font          = [UIFont systemFontOfSize:19 weight:UIFontWeightBold];
    titleL.textColor     = [UIColor colorWithRed:0.88f green:0.88f blue:0.92f alpha:1.0f];
    titleL.textAlignment = NSTextAlignmentCenter;
    [card addSubview:titleL];

    // Subtitle
    UILabel *subL = [[UILabel alloc] initWithFrame:CGRectMake(0, 116, cw, 18)];
    subL.text          = @"Standoff 2";
    subL.font          = [UIFont systemFontOfSize:12 weight:UIFontWeightRegular];
    subL.textColor     = [UIColor colorWithRed:0.48f green:0.48f blue:0.55f alpha:1.0f];
    subL.textAlignment = NSTextAlignmentCenter;
    [card addSubview:subL];

    // Divider
    UIView *div = [[UIView alloc] initWithFrame:CGRectMake(20, 142, cw - 40, 0.5f)];
    div.backgroundColor = [UIColor colorWithRed:0.22f green:0.22f blue:0.28f alpha:1.0f];
    [card addSubview:div];

    // Status row
    UIView *statusRow = [[UIView alloc] initWithFrame:CGRectMake(0, 150, cw, 22)];
    [card addSubview:statusRow];

    _statusDot = [[UIView alloc] initWithFrame:CGRectMake(0, 7, 8, 8)];
    _statusDot.layer.cornerRadius = 4;
    [statusRow addSubview:_statusDot];

    _statusLbl = [[UILabel alloc] initWithFrame:CGRectMake(12, 0, 90, 22)];
    _statusLbl.font = [UIFont systemFontOfSize:11 weight:UIFontWeightSemibold];
    [statusRow addSubview:_statusLbl];

    // Main button
    CGFloat bw = cw - 40;
    _mainBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    _mainBtn.frame               = CGRectMake(20, 186, bw, 50);
    _mainBtn.layer.cornerRadius  = 13;
    _mainBtn.layer.masksToBounds = YES;
    _mainBtn.titleLabel.font     = [UIFont systemFontOfSize:15 weight:UIFontWeightBold];
    [_mainBtn addTarget:self action:@selector(tapMain)
      forControlEvents:UIControlEventTouchUpInside];
    [_mainBtn setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    [card addSubview:_mainBtn];

    [self updateState];
}

- (void)applyVisualState:(BOOL)active {
    if (active) {
        _statusDot.backgroundColor = [UIColor colorWithRed:0.20f green:0.85f blue:0.40f alpha:1.0f];
        _statusLbl.textColor       = [UIColor colorWithRed:0.20f green:0.85f blue:0.40f alpha:1.0f];
        _statusLbl.text            = @"ACTIVE";
        _mainBtn.backgroundColor   = [UIColor colorWithRed:0.78f green:0.10f blue:0.22f alpha:1.0f];
        [_mainBtn setTitle:@"\u25fc  STOP" forState:UIControlStateNormal];
    } else {
        _statusDot.backgroundColor = [UIColor colorWithRed:0.35f green:0.35f blue:0.42f alpha:1.0f];
        _statusLbl.textColor       = [UIColor colorWithRed:0.48f green:0.48f blue:0.55f alpha:1.0f];
        _statusLbl.text            = @"INACTIVE";
        _mainBtn.backgroundColor   = [UIColor colorWithRed:0.62f green:0.12f blue:0.95f alpha:1.0f];
        [_mainBtn setTitle:@"\u25b6  INJECT" forState:UIControlStateNormal];
    }
    // Centre status row
    UIView  *row = _statusDot.superview;
    CGFloat  rw  = row ? row.frame.size.width : 280;
    CGSize   ts  = [_statusLbl.text sizeWithAttributes:@{NSFontAttributeName: _statusLbl.font}];
    CGFloat total  = 8 + 4 + ts.width;
    CGFloat startX = (rw - total) * 0.5f;
    _statusDot.frame = CGRectMake(startX,      7, 8,           8);
    _statusLbl.frame = CGRectMake(startX + 12, 0, ts.width+4, 22);
}

- (void)updateState {
    [self applyVisualState:IsHUDEnabled()];
}

- (void)reloadMainButtonState {
    [self applyVisualState:IsHUDEnabled()];
}

- (void)tapMain {
    UIImpactFeedbackGenerator *hap =
        [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium];
    [hap impactOccurred];
    // Read current state, flip it, apply UI immediately
    // (IsHUDEnabled reads PID file which may lag — don't re-read after set)
    BOOL nowActive = !IsHUDEnabled();
    SetHUDEnabled(nowActive);
    [self applyVisualState:nowActive];
}

@end
