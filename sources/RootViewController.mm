//
//  RootViewController.mm
//  extrahook — multi-tab menu

#import <notify.h>
#import "HUDHelper.h"
#import "MainApplication.h"
#import "RootViewController.h"
#import "UIApplication+Private.h"
#import "../esp/drawing_view/obfusheader.h"
#import "../esp/drawing_view/tt.h"
#import "../esp/drawing_view/cfg.h"

// ── Palette ──────────────────────────────────────────────────────────────────
#define kBG      [UIColor colorWithRed:0.09 green:0.09 blue:0.11 alpha:0.97]
#define kPanel   [UIColor colorWithRed:0.13 green:0.13 blue:0.17 alpha:1.0]
#define kCard    [UIColor colorWithRed:0.17 green:0.17 blue:0.21 alpha:1.0]
#define kAccent  [UIColor colorWithRed:0.62 green:0.12 blue:0.95 alpha:1.0]
#define kAccent2 [UIColor colorWithRed:0.75 green:0.25 blue:1.00 alpha:1.0]
#define kTxt     [UIColor colorWithRed:0.88 green:0.88 blue:0.92 alpha:1.0]
#define kSub     [UIColor colorWithRed:0.48 green:0.48 blue:0.55 alpha:1.0]
#define kSep     [UIColor colorWithRed:0.22 green:0.22 blue:0.28 alpha:1.0]

// ─────────────────────────────────────────────────────────────────────────────
// MRow — checkbox toggle row
// ─────────────────────────────────────────────────────────────────────────────
@interface MRow : UIControl
@property (nonatomic, assign) BOOL isOn;
@property (nonatomic, copy) void(^onChange)(BOOL);
- (instancetype)initTitle:(NSString *)t on:(BOOL)on;
@end

@implementation MRow {
    UIView  *_box;
    UILabel *_check;
    UILabel *_lbl;
}
- (instancetype)initTitle:(NSString *)t on:(BOOL)on {
    self = [super init];
    if (!self) return nil;
    _isOn = on;
    self.translatesAutoresizingMaskIntoConstraints = NO;
    [self.heightAnchor constraintEqualToConstant:36].active = YES;

    _box = [UIView new];
    _box.translatesAutoresizingMaskIntoConstraints = NO;
    _box.layer.cornerRadius = 3;
    _box.layer.borderWidth  = 1.5;
    _box.layer.borderColor  = kAccent.CGColor;
    _box.backgroundColor    = on ? kAccent : UIColor.clearColor;
    [self addSubview:_box];

    _check = [UILabel new];
    _check.translatesAutoresizingMaskIntoConstraints = NO;
    _check.text          = @"✓";
    _check.font          = [UIFont boldSystemFontOfSize:9];
    _check.textColor     = UIColor.whiteColor;
    _check.textAlignment = NSTextAlignmentCenter;
    _check.alpha         = on ? 1.0 : 0.0;
    [_box addSubview:_check];

    _lbl = [UILabel new];
    _lbl.translatesAutoresizingMaskIntoConstraints = NO;
    _lbl.text      = t;
    _lbl.font      = [UIFont systemFontOfSize:13 weight:UIFontWeightRegular];
    _lbl.textColor = kTxt;
    [self addSubview:_lbl];

    [NSLayoutConstraint activateConstraints:@[
        [_box.leadingAnchor  constraintEqualToAnchor:self.leadingAnchor constant:14],
        [_box.centerYAnchor  constraintEqualToAnchor:self.centerYAnchor],
        [_box.widthAnchor    constraintEqualToConstant:14],
        [_box.heightAnchor   constraintEqualToConstant:14],
        [_check.centerXAnchor constraintEqualToAnchor:_box.centerXAnchor],
        [_check.centerYAnchor constraintEqualToAnchor:_box.centerYAnchor],
        [_lbl.leadingAnchor  constraintEqualToAnchor:_box.trailingAnchor constant:9],
        [_lbl.centerYAnchor  constraintEqualToAnchor:self.centerYAnchor],
        [_lbl.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-14],
    ]];

    [self addTarget:self action:@selector(_tap) forControlEvents:UIControlEventTouchUpInside];
    return self;
}
- (void)_tap {
    [UIImpactFeedbackGenerator new]; // lightweight feedback
    self.isOn = !self.isOn;
    [UIView animateWithDuration:0.12 animations:^{
        self->_box.backgroundColor = self.isOn ? kAccent : UIColor.clearColor;
        self->_check.alpha = self.isOn ? 1.0 : 0.0;
        self->_lbl.textColor = self.isOn ? kAccent2 : kTxt;
    }];
    if (self.onChange) self.onChange(self.isOn);
}
- (void)setIsOn:(BOOL)v {
    _isOn = v;
    _box.backgroundColor = v ? kAccent : UIColor.clearColor;
    _check.alpha         = v ? 1.0 : 0.0;
    _lbl.textColor       = v ? kAccent2 : kTxt;
}
@end

// ─────────────────────────────────────────────────────────────────────────────
// MSlider — labeled slider row
// ─────────────────────────────────────────────────────────────────────────────
@interface MSlider : UIView
@property (nonatomic, copy) void(^onChange)(float);
- (instancetype)initTitle:(NSString *)t min:(float)mn max:(float)mx val:(float)v fmt:(NSString *)fmt;
@end

@implementation MSlider {
    UISlider *_sl;
    UILabel  *_valLbl;
    NSString *_fmt;
}
- (instancetype)initTitle:(NSString *)t min:(float)mn max:(float)mx val:(float)v fmt:(NSString *)fmt {
    self = [super init];
    if (!self) return nil;
    _fmt = fmt;
    self.translatesAutoresizingMaskIntoConstraints = NO;
    [self.heightAnchor constraintEqualToConstant:48].active = YES;

    UILabel *lbl = [UILabel new];
    lbl.translatesAutoresizingMaskIntoConstraints = NO;
    lbl.text      = t;
    lbl.font      = [UIFont systemFontOfSize:12 weight:UIFontWeightRegular];
    lbl.textColor = kTxt;
    [self addSubview:lbl];

    _valLbl = [UILabel new];
    _valLbl.translatesAutoresizingMaskIntoConstraints = NO;
    _valLbl.text          = [NSString stringWithFormat:fmt, v];
    _valLbl.font          = [UIFont monospacedDigitSystemFontOfSize:11 weight:UIFontWeightMedium];
    _valLbl.textColor     = kAccent2;
    _valLbl.textAlignment = NSTextAlignmentRight;
    [self addSubview:_valLbl];

    _sl = [UISlider new];
    _sl.translatesAutoresizingMaskIntoConstraints = NO;
    _sl.minimumValue           = mn;
    _sl.maximumValue           = mx;
    _sl.value                  = v;
    _sl.minimumTrackTintColor  = kAccent;
    _sl.maximumTrackTintColor  = kSep;
    _sl.thumbTintColor         = kAccent2;
    [_sl addTarget:self action:@selector(_changed) forControlEvents:UIControlEventValueChanged];
    [self addSubview:_sl];

    [NSLayoutConstraint activateConstraints:@[
        [lbl.leadingAnchor   constraintEqualToAnchor:self.leadingAnchor constant:14],
        [lbl.topAnchor       constraintEqualToAnchor:self.topAnchor constant:6],
        [_valLbl.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-14],
        [_valLbl.centerYAnchor  constraintEqualToAnchor:lbl.centerYAnchor],
        [_valLbl.widthAnchor    constraintEqualToConstant:55],
        [_sl.leadingAnchor   constraintEqualToAnchor:self.leadingAnchor constant:14],
        [_sl.trailingAnchor  constraintEqualToAnchor:self.trailingAnchor constant:-14],
        [_sl.bottomAnchor    constraintEqualToAnchor:self.bottomAnchor constant:-6],
    ]];
    return self;
}
- (void)_changed {
    _valLbl.text = [NSString stringWithFormat:_fmt, _sl.value];
    if (self.onChange) self.onChange(_sl.value);
}
@end

// ─────────────────────────────────────────────────────────────────────────────
// MSep — thin separator
// ─────────────────────────────────────────────────────────────────────────────
static UIView *MSep(void) {
    UIView *v = [UIView new];
    v.translatesAutoresizingMaskIntoConstraints = NO;
    v.backgroundColor = kSep;
    [v.heightAnchor constraintEqualToConstant:0.5].active = YES;
    return v;
}

// ─────────────────────────────────────────────────────────────────────────────
// TabButton
// ─────────────────────────────────────────────────────────────────────────────
@interface TabButton : UIButton
@property (nonatomic, assign) NSInteger tabIndex;
@end
@implementation TabButton
@end

// ─────────────────────────────────────────────────────────────────────────────
// RootViewController
// ─────────────────────────────────────────────────────────────────────────────
@implementation RootViewController {
    UIView       *_panel;
    UIButton     *_injectBtn;
    UIScrollView *_contentScroll;
    UIStackView  *_contentStack;
    NSArray      *_tabBtns;
    NSInteger     _curTab;
    BOOL          _isActive;
    CGPoint       _dragOffset;
}

// ── HUD helpers ───────────────────────────────────────────────────────────────
- (BOOL)isHUDEnabled        { return IsHUDEnabled(); }
- (void)setHUDEnabled:(BOOL)e { SetHUDEnabled(e); }

// ── loadView ──────────────────────────────────────────────────────────────────
- (void)loadView {
    CGRect bounds = UIScreen.mainScreen.bounds;
    self.view = [[UIView alloc] initWithFrame:bounds];
    self.view.backgroundColor = UIColor.clearColor;

    self.backgroundView = [[UIView alloc] initWithFrame:bounds];
    self.backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.backgroundView.backgroundColor = UIColor.clearColor;
    [self.view addSubview:self.backgroundView];

    [self _buildPanel];
}

- (void)_buildPanel {
    CGRect sc    = UIScreen.mainScreen.bounds;
    CGFloat pw   = MIN(sc.size.width - 32, 370);
    CGFloat ph   = MIN(sc.size.height - 100, 460);
    CGFloat px   = (sc.size.width  - pw) / 2;
    CGFloat py   = (sc.size.height - ph) / 2;

    // ── Main panel ────────────────────────────────────────────────────────
    _panel = [[UIView alloc] initWithFrame:CGRectMake(px, py, pw, ph)];
    _panel.backgroundColor    = kBG;
    _panel.layer.cornerRadius = 12;
    _panel.layer.masksToBounds = YES;
    _panel.layer.borderWidth  = 0.5;
    _panel.layer.borderColor  = [UIColor colorWithWhite:1.0 alpha:0.08].CGColor;
    [self.view addSubview:_panel];

    // Shadow
    _panel.layer.masksToBounds = NO;
    _panel.layer.shadowColor   = [UIColor colorWithRed:0.6 green:0.1 blue:0.9 alpha:0.4].CGColor;
    _panel.layer.shadowOffset  = CGSizeMake(0, 4);
    _panel.layer.shadowRadius  = 16;
    _panel.layer.shadowOpacity = 1.0;

    // Clip inner content separately
    UIView *clip = [[UIView alloc] initWithFrame:_panel.bounds];
    clip.backgroundColor     = kBG;
    clip.layer.cornerRadius  = 12;
    clip.layer.masksToBounds = YES;
    clip.autoresizingMask    = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [_panel addSubview:clip];

    // ── Title bar (top, 44px) ─────────────────────────────────────────────
    UIView *titleBar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, pw, 44)];
    titleBar.backgroundColor = kPanel;
    [clip addSubview:titleBar];

    // Accent top line
    UIView *accentLine = [[UIView alloc] initWithFrame:CGRectMake(0, 0, pw, 2)];
    accentLine.backgroundColor = kAccent;
    [titleBar addSubview:accentLine];

    // Title label
    UILabel *titleLbl = [[UILabel alloc] initWithFrame:CGRectMake(14, 0, 150, 44)];
    titleLbl.text      = @"extrahook";
    titleLbl.font      = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
    titleLbl.textColor = kTxt;
    [titleBar addSubview:titleLbl];

    // Version label
    UILabel *verLbl = [[UILabel alloc] initWithFrame:CGRectMake(14, 0, 200, 44)];
    verLbl.text      = @"v2.0  ·  standoff2";
    verLbl.font      = [UIFont systemFontOfSize:10];
    verLbl.textColor = kSub;
    // position right of titleLbl
    verLbl.frame = CGRectMake(titleLbl.frame.size.width + 20, 0, 130, 44);
    [titleBar addSubview:verLbl];

    // Inject button (right side of title bar)
    _injectBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    _injectBtn.frame = CGRectMake(pw - 90, 10, 78, 24);
    _injectBtn.layer.cornerRadius = 12;
    _injectBtn.layer.masksToBounds = YES;
    [_injectBtn addTarget:self action:@selector(_tapInject) forControlEvents:UIControlEventTouchUpInside];
    [titleBar addSubview:_injectBtn];
    [self _updateInjectBtn];

    // Drag gesture on title bar
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(_pan:)];
    [titleBar addGestureRecognizer:pan];

    // ── Left tab sidebar (50px) ───────────────────────────────────────────
    CGFloat tabW = 50;
    UIView *sidebar = [[UIView alloc] initWithFrame:CGRectMake(0, 44, tabW, ph - 44)];
    sidebar.backgroundColor = kPanel;
    [clip addSubview:sidebar];

    UIView *sideRight = [[UIView alloc] initWithFrame:CGRectMake(tabW - 0.5, 44, 0.5, ph - 44)];
    sideRight.backgroundColor = kSep;
    [clip addSubview:sideRight];

    NSArray *icons  = @[@"👁", @"🎯", @"🏃", @"⚡", @"⚙️"];
    NSArray *labels = @[@"ESP", @"AIM", @"MOVE", @"MISC", @"CFG"];
    NSMutableArray *btns = [NSMutableArray new];
    CGFloat tabH = (ph - 44) / icons.count;

    for (NSInteger i = 0; i < (NSInteger)icons.count; i++) {
        TabButton *btn = [TabButton buttonWithType:UIButtonTypeCustom];
        btn.frame     = CGRectMake(0, tabH * i, tabW, tabH);
        btn.tabIndex  = i;
        btn.tag       = i;

        UILabel *iconLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, tabW, tabH * 0.55)];
        iconLbl.text          = icons[i];
        iconLbl.font          = [UIFont systemFontOfSize:20];
        iconLbl.textAlignment = NSTextAlignmentCenter;
        [btn addSubview:iconLbl];

        UILabel *nameLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, tabH * 0.55, tabW, tabH * 0.35)];
        nameLbl.text          = labels[i];
        nameLbl.font          = [UIFont systemFontOfSize:8 weight:UIFontWeightMedium];
        nameLbl.textColor     = kSub;
        nameLbl.textAlignment = NSTextAlignmentCenter;
        [btn addSubview:nameLbl];

        [btn addTarget:self action:@selector(_tabTap:) forControlEvents:UIControlEventTouchUpInside];
        [sidebar addSubview:btn];
        [btns addObject:btn];
    }
    _tabBtns = btns;

    // ── Content area ─────────────────────────────────────────────────────
    CGFloat cx = tabW;
    _contentScroll = [[UIScrollView alloc] initWithFrame:CGRectMake(cx, 44, pw - cx, ph - 44)];
    _contentScroll.backgroundColor = UIColor.clearColor;
    _contentScroll.showsVerticalScrollIndicator = NO;
    [clip addSubview:_contentScroll];

    _contentStack = [[UIStackView alloc] init];
    _contentStack.axis      = UILayoutConstraintAxisVertical;
    _contentStack.spacing   = 0;
    _contentStack.translatesAutoresizingMaskIntoConstraints = NO;
    [_contentScroll addSubview:_contentStack];

    [NSLayoutConstraint activateConstraints:@[
        [_contentStack.topAnchor    constraintEqualToAnchor:_contentScroll.topAnchor],
        [_contentStack.leadingAnchor constraintEqualToAnchor:_contentScroll.leadingAnchor],
        [_contentStack.trailingAnchor constraintEqualToAnchor:_contentScroll.trailingAnchor],
        [_contentStack.bottomAnchor constraintEqualToAnchor:_contentScroll.bottomAnchor],
        [_contentStack.widthAnchor  constraintEqualToAnchor:_contentScroll.widthAnchor],
    ]];

    _curTab = 0;
    [self _loadTab:0];
    [self _updateTabHighlight];
}

// ── Inject button ──────────────────────────────────────────────────────────────
- (void)_updateInjectBtn {
    if (_isActive) {
        [_injectBtn setTitle:@"◼  STOP" forState:UIControlStateNormal];
        _injectBtn.backgroundColor = [UIColor colorWithRed:0.8 green:0.1 blue:0.2 alpha:1.0];
    } else {
        [_injectBtn setTitle:@"▶  START" forState:UIControlStateNormal];
        _injectBtn.backgroundColor = kAccent;
    }
    [_injectBtn setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    _injectBtn.titleLabel.font = [UIFont systemFontOfSize:11 weight:UIFontWeightSemibold];
}

- (void)_tapInject {
    UIImpactFeedbackGenerator *hap = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium];
    [hap impactOccurred];
    _isActive = !_isActive;
    [self setHUDEnabled:_isActive];
    [self _updateInjectBtn];
}

- (void)reloadMainButtonState {
    _isActive = [self isHUDEnabled];
    [self _updateInjectBtn];
}

// ── Tab switching ──────────────────────────────────────────────────────────────
- (void)_tabTap:(TabButton *)btn {
    if (btn.tag == _curTab) return;
    _curTab = btn.tag;
    [self _loadTab:_curTab];
    [self _updateTabHighlight];
    [_contentScroll setContentOffset:CGPointZero animated:NO];
}

- (void)_updateTabHighlight {
    for (TabButton *b in _tabBtns) {
        BOOL sel = (b.tag == _curTab);
        // Left accent bar
        UIView *bar = [b viewWithTag:200];
        if (!bar) {
            bar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 3, b.frame.size.height)];
            bar.backgroundColor = kAccent;
            bar.tag = 200;
            [b addSubview:bar];
        }
        bar.hidden = !sel;
        b.backgroundColor = sel
            ? [UIColor colorWithRed:0.62 green:0.12 blue:0.95 alpha:0.12]
            : UIColor.clearColor;
        // Update name label color
        for (UIView *sv in b.subviews) {
            if ([sv isKindOfClass:[UILabel class]]) {
                UILabel *lbl = (UILabel *)sv;
                if (lbl.font.pointSize <= 9) {
                    lbl.textColor = sel ? kAccent2 : kSub;
                }
            }
        }
    }
}

// ── Build tab content ──────────────────────────────────────────────────────────
- (void)_loadTab:(NSInteger)tab {
    // Remove existing arranged subviews
    for (UIView *v in _contentStack.arrangedSubviews) {
        [_contentStack removeArrangedSubview:v];
        [v removeFromSuperview];
    }

    switch (tab) {
        case 0: [self _buildESP];      break;
        case 1: [self _buildAimbot];   break;
        case 2: [self _buildMovement]; break;
        case 3: [self _buildMisc];     break;
        case 4: [self _buildConfig];   break;
    }
}

- (void)_add:(UIView *)v { [_contentStack addArrangedSubview:v]; }

- (MRow *)_row:(NSString *)t val:(BOOL)val setter:(void(^)(BOOL))setter {
    MRow *r = [[MRow alloc] initTitle:t on:val];
    r.onChange = setter;
    return r;
}

// Convenience macro helper — used below via a wrapper method
- (MRow *)_rowBool:(NSString *)t ptr:(void *)ptr {
    volatile bool *vp = (volatile bool *)ptr;
    MRow *r = [[MRow alloc] initTitle:t on:(BOOL)(*vp)];
    r.onChange = ^(BOOL on){ *vp = on; };
    return r;
}

// ── ESP tab ───────────────────────────────────────────────────────────────────
- (void)_buildESP {
    UIView *sp4 = [UIView new]; sp4.translatesAutoresizingMaskIntoConstraints = NO;
    [sp4.heightAnchor constraintEqualToConstant:4].active = YES;
    [self _add:sp4];
    [self _add:[self _sectionHeader:@"BOXES"]];
    [self _add:[self _rowBool:@"Box ESP"           ptr:&esp_box_enabled]];
    [self _add:[MSep() ]];
    [self _add:[self _rowBool:@"Box Outline"       ptr:&esp_box_outline]];
    [self _add:[MSep() ]];
    [self _add:[self _rowBool:@"Box Fill"          ptr:&esp_box_fill]];
    [self _add:[MSep() ]];
    [self _add:[self _rowBool:@"Corner Box"        ptr:&esp_box_corner]];
    [self _add:[MSep() ]];
    [self _add:[self _rowBool:@"3D Box"            ptr:&esp_box_3d]];
    [self _add:[MSep() ]];
    [self _add:[self _rowBool:@"Lines to Players"  ptr:&esp_line_enabled]];
    [self _add:[MSep() ]];
    [self _add:[self _rowBool:@"Line Outline"      ptr:&esp_line_outline]];
    UIView *sp6 = [UIView new]; sp6.translatesAutoresizingMaskIntoConstraints = NO;
    [sp6.heightAnchor constraintEqualToConstant:4].active = YES;
    [self _add:sp6];
    [self _add:[self _sectionHeader:@"INFO"]];
    [self _add:[self _rowBool:@"Names"             ptr:&esp_name_enabled]];
    [self _add:[MSep() ]];
    [self _add:[self _rowBool:@"Name Outline"      ptr:&esp_name_outline]];
    [self _add:[MSep() ]];
    [self _add:[self _rowBool:@"Health Text"       ptr:&esp_health_enabled]];
    [self _add:[MSep() ]];
    [self _add:[self _rowBool:@"Health Bar"        ptr:&esp_health_bar_enabled]];
    [self _add:[MSep() ]];
    [self _add:[self _rowBool:@"Health Bar Outline" ptr:&esp_health_bar_outline]];
    [self _add:[MSep() ]];
    [self _add:[self _rowBool:@"Weapon Name"       ptr:&esp_weapon_enabled]];
    [self _add:[MSep() ]];
    [self _add:[self _rowBool:@"Weapon Icon"       ptr:&esp_weapon_icon_enabled]];
    [self _add:[MSep() ]];
    [self _add:[self _rowBool:@"Platform Badge"    ptr:&esp_platform_enabled]];
    [self _add:[MSep() ]];
    [self _add:[self _rowBool:@"Avatar"            ptr:&esp_avatar_enabled]];
    [self _add:[MSep() ]];
    [self _add:[self _rowBool:@"Team Check"        ptr:&esp_team_check]];
    UIView *bot = [UIView new]; bot.translatesAutoresizingMaskIntoConstraints = NO;
    [bot.heightAnchor constraintEqualToConstant:12].active = YES;
    [self _add:bot];
}

// ── Aimbot tab ────────────────────────────────────────────────────────────────
- (void)_buildAimbot {
    UIView *sp = [UIView new]; sp.translatesAutoresizingMaskIntoConstraints = NO;
    [sp.heightAnchor constraintEqualToConstant:4].active = YES;
    [self _add:sp];
    [self _add:[self _sectionHeader:@"AIMBOT"]];
    [self _add:[self _rowBool:@"Enabled"           ptr:&aimbot_enabled]];
    [self _add:[MSep() ]];
    [self _add:[self _rowBool:@"Visible Check"     ptr:&aimbot_visible_check]];
    [self _add:[MSep() ]];
    [self _add:[self _rowBool:@"Shoot Check"       ptr:&aimbot_shooting_check]];
    [self _add:[MSep() ]];
    [self _add:[self _rowBool:@"Knife Bot"         ptr:&aimbot_knife_bot]];
    [self _add:[MSep() ]];
    [self _add:[self _rowBool:@"FOV Visible"       ptr:&aimbot_fov_visible]];
    [self _add:[MSep() ]];
    [self _add:[self _rowBool:@"Team Check"        ptr:&aimbot_team_check]];

    MSlider *fovSl = [[MSlider alloc] initTitle:@"FOV" min:0 max:180 val:aimbot_fov fmt:@"%.0f°"];
    fovSl.onChange = ^(float v){ aimbot_fov = v; };
    [self _add:fovSl];

    MSlider *smSl = [[MSlider alloc] initTitle:@"Smooth" min:0 max:20 val:aimbot_smooth fmt:@"%.1f"];
    smSl.onChange = ^(float v){ aimbot_smooth = v; };
    [self _add:smSl];

    UIView *sp2 = [UIView new]; sp2.translatesAutoresizingMaskIntoConstraints = NO;
    [sp2.heightAnchor constraintEqualToConstant:4].active = YES;
    [self _add:sp2];
    [self _add:[self _sectionHeader:@"TRIGGERBOT"]];
    [self _add:[self _rowBool:@"Triggerbot"        ptr:&aimbot_triggerbot]];
    [self _add:[MSep() ]];

    MSlider *dlSl = [[MSlider alloc] initTitle:@"Trigger Delay" min:0 max:500 val:aimbot_trigger_delay fmt:@"%.0fms"];
    dlSl.onChange = ^(float v){ aimbot_trigger_delay = v; };
    [self _add:dlSl];

    UIView *sp3 = [UIView new]; sp3.translatesAutoresizingMaskIntoConstraints = NO;
    [sp3.heightAnchor constraintEqualToConstant:4].active = YES;
    [self _add:sp3];
    [self _add:[self _sectionHeader:@"RCS (RECOIL)"]];

    MRow *rcsRow = [self _rowBool:@"Anti-Recoil" ptr:&esp_rcs_enabled];
    [self _add:rcsRow];
    [self _add:[MSep() ]];

    MSlider *rcsh = [[MSlider alloc] initTitle:@"RCS Horizontal" min:0 max:2 val:esp_rcs_h fmt:@"%.2f"];
    rcsh.onChange = ^(float v){ esp_rcs_h = v; };
    [self _add:rcsh];

    MSlider *rcsv = [[MSlider alloc] initTitle:@"RCS Vertical" min:0 max:2 val:esp_rcs_v fmt:@"%.2f"];
    rcsv.onChange = ^(float v){ esp_rcs_v = v; };
    [self _add:rcsv];

    UIView *bot = [UIView new]; bot.translatesAutoresizingMaskIntoConstraints = NO;
    [bot.heightAnchor constraintEqualToConstant:12].active = YES;
    [self _add:bot];
}

// ── Movement tab ──────────────────────────────────────────────────────────────
- (void)_buildMovement {
    UIView *sp = [UIView new]; sp.translatesAutoresizingMaskIntoConstraints = NO;
    [sp.heightAnchor constraintEqualToConstant:4].active = YES;
    [self _add:sp];
    [self _add:[self _sectionHeader:@"MOVEMENT"]];
    [self _add:[self _rowBool:@"Bunny Hop"         ptr:&esp_bunny_hop]];
    [self _add:[MSep() ]];
    [self _add:[self _rowBool:@"Air Jump"          ptr:&esp_air_jump]];
    [self _add:[MSep() ]];
    [self _add:[self _rowBool:@"Fast Knife"        ptr:&esp_fast_knife]];

    UIView *sp2 = [UIView new]; sp2.translatesAutoresizingMaskIntoConstraints = NO;
    [sp2.heightAnchor constraintEqualToConstant:4].active = YES;
    [self _add:sp2];
    [self _add:[self _sectionHeader:@"BHOP MODE"]];

    // Bhop segmented
    UISegmentedControl *seg = [[UISegmentedControl alloc] initWithItems:@[@"Off", @"Auto", @"Semi"]];
    seg.translatesAutoresizingMaskIntoConstraints = NO;
    seg.selectedSegmentIndex = esp_bhop_setting;
    [seg setTitleTextAttributes:@{NSForegroundColorAttributeName: kTxt} forState:UIControlStateNormal];
    [seg setTitleTextAttributes:@{NSForegroundColorAttributeName: UIColor.whiteColor} forState:UIControlStateSelected];
    if (@available(iOS 13.0, *)) {
        seg.selectedSegmentTintColor = kAccent;
    }
    [seg addTarget:self action:@selector(_bhopSeg:) forControlEvents:UIControlEventValueChanged];

    UIView *segWrap = [UIView new];
    segWrap.translatesAutoresizingMaskIntoConstraints = NO;
    [segWrap.heightAnchor constraintEqualToConstant:50].active = YES;
    [segWrap addSubview:seg];
    [NSLayoutConstraint activateConstraints:@[
        [seg.leadingAnchor  constraintEqualToAnchor:segWrap.leadingAnchor constant:14],
        [seg.trailingAnchor constraintEqualToAnchor:segWrap.trailingAnchor constant:-14],
        [seg.centerYAnchor  constraintEqualToAnchor:segWrap.centerYAnchor],
    ]];
    [self _add:segWrap];

    UIView *sp3 = [UIView new]; sp3.translatesAutoresizingMaskIntoConstraints = NO;
    [sp3.heightAnchor constraintEqualToConstant:4].active = YES;
    [self _add:sp3];
    [self _add:[self _sectionHeader:@"VIEWMODEL"]];
    [self _add:[self _rowBool:@"Custom Viewmodel"  ptr:&viewmodel_enabled]];
    [self _add:[MSep() ]];

    MSlider *vmx = [[MSlider alloc] initTitle:@"X offset" min:-10 max:10 val:viewmodel_x fmt:@"%.1f"];
    vmx.onChange = ^(float v){ viewmodel_x = v; };
    [self _add:vmx];

    MSlider *vmy = [[MSlider alloc] initTitle:@"Y offset" min:-10 max:10 val:viewmodel_y fmt:@"%.1f"];
    vmy.onChange = ^(float v){ viewmodel_y = v; };
    [self _add:vmy];

    MSlider *vmz = [[MSlider alloc] initTitle:@"Z offset" min:-10 max:10 val:viewmodel_z fmt:@"%.1f"];
    vmz.onChange = ^(float v){ viewmodel_z = v; };
    [self _add:vmz];

    UIView *bot = [UIView new]; bot.translatesAutoresizingMaskIntoConstraints = NO;
    [bot.heightAnchor constraintEqualToConstant:12].active = YES;
    [self _add:bot];
}

// ── Misc tab ──────────────────────────────────────────────────────────────────
- (void)_buildMisc {
    UIView *sp = [UIView new]; sp.translatesAutoresizingMaskIntoConstraints = NO;
    [sp.heightAnchor constraintEqualToConstant:4].active = YES;
    [self _add:sp];
    [self _add:[self _sectionHeader:@"PLAYER"]];
    [self _add:[self _rowBool:@"Invisible"         ptr:&esp_invisible]];
    [self _add:[MSep() ]];
    [self _add:[self _rowBool:@"Add Score"         ptr:&esp_addscore]];

    UIView *sp2 = [UIView new]; sp2.translatesAutoresizingMaskIntoConstraints = NO;
    [sp2.heightAnchor constraintEqualToConstant:4].active = YES;
    [self _add:sp2];
    [self _add:[self _sectionHeader:@"WEAPON"]];
    [self _add:[self _rowBool:@"Infinite Ammo"     ptr:&esp_inf_ammo]];
    [self _add:[MSep() ]];
    [self _add:[self _rowBool:@"No Spread"         ptr:&esp_no_spread]];
    [self _add:[MSep() ]];
    [self _add:[self _rowBool:@"Wallshot"          ptr:&esp_wallshot]];
    [self _add:[MSep() ]];
    [self _add:[self _rowBool:@"Fast Fire Rate"    ptr:&esp_fire_rate]];

    UIView *bot = [UIView new]; bot.translatesAutoresizingMaskIntoConstraints = NO;
    [bot.heightAnchor constraintEqualToConstant:12].active = YES;
    [self _add:bot];
}

// ── Config tab ────────────────────────────────────────────────────────────────
- (void)_buildConfig {
    UIView *sp = [UIView new]; sp.translatesAutoresizingMaskIntoConstraints = NO;
    [sp.heightAnchor constraintEqualToConstant:4].active = YES;
    [self _add:sp];
    [self _add:[self _sectionHeader:@"OPTIONS"]];
    [self _add:[self _rowBool:@"Auto Load Config"  ptr:&esp_auto_load]];
    [self _add:[MSep() ]];
    [self _add:[self _rowBool:@"Screenshot Safe"   ptr:&esp_screenshot_safe]];

    UIView *sp2 = [UIView new]; sp2.translatesAutoresizingMaskIntoConstraints = NO;
    [sp2.heightAnchor constraintEqualToConstant:4].active = YES;
    [self _add:sp2];
    [self _add:[self _sectionHeader:@"CONFIGS"]];

    // Config list
    NSArray<NSString*> *cfgs = cfg_get_list();
    for (NSString *name in cfgs) {
        UIView *row = [self _cfgRow:name];
        [self _add:row];
        [self _add:[MSep()]];
    }

    // Save new config button
    UIButton *saveBtn = [self _actionButton:@"Save New Config" color:kAccent];
    [saveBtn addTarget:self action:@selector(_saveNewConfig) forControlEvents:UIControlEventTouchUpInside];
    UIView *savWrap = [UIView new]; savWrap.translatesAutoresizingMaskIntoConstraints = NO;
    [savWrap.heightAnchor constraintEqualToConstant:52].active = YES;
    [savWrap addSubview:saveBtn];
    [NSLayoutConstraint activateConstraints:@[
        [saveBtn.leadingAnchor  constraintEqualToAnchor:savWrap.leadingAnchor constant:14],
        [saveBtn.trailingAnchor constraintEqualToAnchor:savWrap.trailingAnchor constant:-14],
        [saveBtn.centerYAnchor  constraintEqualToAnchor:savWrap.centerYAnchor],
        [saveBtn.heightAnchor   constraintEqualToConstant:34],
    ]];
    [self _add:savWrap];

    UIView *bot = [UIView new]; bot.translatesAutoresizingMaskIntoConstraints = NO;
    [bot.heightAnchor constraintEqualToConstant:12].active = YES;
    [self _add:bot];
}

- (UIView *)_cfgRow:(NSString *)name {
    UIView *row = [UIView new];
    row.translatesAutoresizingMaskIntoConstraints = NO;
    [row.heightAnchor constraintEqualToConstant:40].active = YES;

    UILabel *lbl = [UILabel new];
    lbl.translatesAutoresizingMaskIntoConstraints = NO;
    lbl.text      = name;
    lbl.font      = [UIFont systemFontOfSize:13];
    lbl.textColor = kTxt;
    [row addSubview:lbl];

    UIButton *loadBtn = [self _smallButton:@"Load" color:kAccent];
    [loadBtn addTarget:self action:@selector(_loadCfg:) forControlEvents:UIControlEventTouchUpInside];
    loadBtn.accessibilityLabel = name;
    [row addSubview:loadBtn];

    UIButton *delBtn = [self _smallButton:@"Del" color:[UIColor colorWithRed:0.8 green:0.1 blue:0.2 alpha:1.0]];
    [delBtn addTarget:self action:@selector(_delCfg:) forControlEvents:UIControlEventTouchUpInside];
    delBtn.accessibilityLabel = name;
    [row addSubview:delBtn];

    [NSLayoutConstraint activateConstraints:@[
        [lbl.leadingAnchor  constraintEqualToAnchor:row.leadingAnchor constant:14],
        [lbl.centerYAnchor  constraintEqualToAnchor:row.centerYAnchor],
        [delBtn.trailingAnchor constraintEqualToAnchor:row.trailingAnchor constant:-10],
        [delBtn.centerYAnchor  constraintEqualToAnchor:row.centerYAnchor],
        [delBtn.widthAnchor    constraintEqualToConstant:38],
        [delBtn.heightAnchor   constraintEqualToConstant:24],
        [loadBtn.trailingAnchor constraintEqualToAnchor:delBtn.leadingAnchor constant:-6],
        [loadBtn.centerYAnchor  constraintEqualToAnchor:row.centerYAnchor],
        [loadBtn.widthAnchor    constraintEqualToConstant:44],
        [loadBtn.heightAnchor   constraintEqualToConstant:24],
    ]];
    return row;
}

- (UIButton *)_smallButton:(NSString *)t color:(UIColor *)c {
    UIButton *b = [UIButton buttonWithType:UIButtonTypeCustom];
    b.translatesAutoresizingMaskIntoConstraints = NO;
    b.backgroundColor    = c;
    b.layer.cornerRadius = 5;
    b.layer.masksToBounds = YES;
    [b setTitle:t forState:UIControlStateNormal];
    [b setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    b.titleLabel.font = [UIFont systemFontOfSize:11 weight:UIFontWeightSemibold];
    return b;
}

- (UIButton *)_actionButton:(NSString *)t color:(UIColor *)c {
    UIButton *b = [UIButton buttonWithType:UIButtonTypeCustom];
    b.translatesAutoresizingMaskIntoConstraints = NO;
    b.backgroundColor     = c;
    b.layer.cornerRadius  = 8;
    b.layer.masksToBounds = YES;
    [b setTitle:t forState:UIControlStateNormal];
    [b setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    b.titleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightSemibold];
    return b;
}

- (void)_saveNewConfig {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Save Config"
                                                                   message:@"Enter a name:"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *tf) {
        tf.placeholder = @"config name";
        tf.clearButtonMode = UITextFieldViewModeWhileEditing;
    }];
    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"Save" style:UIAlertActionStyleDefault handler:^(UIAlertAction *_) {
        NSString *name = alert.textFields.firstObject.text;
        if (name.length) {
            cfg_create(name);
            [self _loadTab:4]; // refresh
        }
    }];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:ok];
    [alert addAction:cancel];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)_loadCfg:(UIButton *)btn {
    cfg_load(btn.accessibilityLabel);
    [self _loadTab:_curTab]; // refresh toggles
}

- (void)_delCfg:(UIButton *)btn {
    cfg_delete(btn.accessibilityLabel);
    [self _loadTab:4];
}

- (void)_bhopSeg:(UISegmentedControl *)seg {
    esp_bhop_setting = (int)seg.selectedSegmentIndex;
}

// ── Section header helper ──────────────────────────────────────────────────────
- (UIView *)_sectionHeader:(NSString *)title {
    UIView *v = [UIView new];
    v.translatesAutoresizingMaskIntoConstraints = NO;
    [v.heightAnchor constraintEqualToConstant:28].active = YES;

    UIView *line = [UIView new];
    line.translatesAutoresizingMaskIntoConstraints = NO;
    line.backgroundColor    = kAccent;
    line.layer.cornerRadius = 1.5;
    [v addSubview:line];

    UILabel *lbl = [UILabel new];
    lbl.translatesAutoresizingMaskIntoConstraints = NO;
    lbl.text      = title;
    lbl.font      = [UIFont systemFontOfSize:10 weight:UIFontWeightSemibold];
    lbl.textColor = kAccent2;
    [v addSubview:lbl];

    [NSLayoutConstraint activateConstraints:@[
        [line.leadingAnchor  constraintEqualToAnchor:v.leadingAnchor constant:14],
        [line.centerYAnchor  constraintEqualToAnchor:v.centerYAnchor],
        [line.widthAnchor    constraintEqualToConstant:3],
        [line.heightAnchor   constraintEqualToConstant:12],
        [lbl.leadingAnchor   constraintEqualToAnchor:line.trailingAnchor constant:7],
        [lbl.centerYAnchor   constraintEqualToAnchor:v.centerYAnchor],
    ]];
    return v;
}

// ── Drag panel ────────────────────────────────────────────────────────────────
- (void)_pan:(UIPanGestureRecognizer *)g {
    CGPoint pt = [g locationInView:self.view];
    if (g.state == UIGestureRecognizerStateBegan) {
        _dragOffset = CGPointMake(pt.x - _panel.frame.origin.x,
                                  pt.y - _panel.frame.origin.y);
    } else if (g.state == UIGestureRecognizerStateChanged) {
        CGRect f = _panel.frame;
        f.origin.x = pt.x - _dragOffset.x;
        f.origin.y = pt.y - _dragOffset.y;
        // Clamp
        CGRect sc = UIScreen.mainScreen.bounds;
        f.origin.x = MAX(0, MIN(f.origin.x, sc.size.width  - f.size.width));
        f.origin.y = MAX(0, MIN(f.origin.y, sc.size.height - f.size.height));
        _panel.frame = f;
    }
}

@end
