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
static UIColor *KBG(void)     { return [UIColor colorWithRed:0.09 green:0.09 blue:0.11 alpha:0.97]; }
static UIColor *KPanel(void)  { return [UIColor colorWithRed:0.13 green:0.13 blue:0.17 alpha:1.0]; }
static UIColor *KAccent(void) { return [UIColor colorWithRed:0.62 green:0.12 blue:0.95 alpha:1.0]; }
static UIColor *KAccent2(void){ return [UIColor colorWithRed:0.78 green:0.30 blue:1.00 alpha:1.0]; }
static UIColor *KTxt(void)    { return [UIColor colorWithRed:0.88 green:0.88 blue:0.92 alpha:1.0]; }
static UIColor *KSub(void)    { return [UIColor colorWithRed:0.48 green:0.48 blue:0.55 alpha:1.0]; }
static UIColor *KSep(void)    { return [UIColor colorWithRed:0.22 green:0.22 blue:0.28 alpha:1.0]; }

// ── Helpers ───────────────────────────────────────────────────────────────────
static UIView *Sep(void) {
    UIView *v = [UIView new];
    v.translatesAutoresizingMaskIntoConstraints = NO;
    v.backgroundColor = KSep();
    [v.heightAnchor constraintEqualToConstant:0.5].active = YES;
    return v;
}

static UIView *Spacer(CGFloat h) {
    UIView *v = [UIView new];
    v.translatesAutoresizingMaskIntoConstraints = NO;
    [v.heightAnchor constraintEqualToConstant:h].active = YES;
    return v;
}

// ── MRow (checkbox toggle) ────────────────────────────────────────────────────
@interface MRow : UIControl
@property (nonatomic, assign) BOOL isOn;
@property (nonatomic, copy)   void(^onChange)(BOOL);
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
    _box.layer.borderColor  = KAccent().CGColor;
    _box.backgroundColor    = on ? KAccent() : UIColor.clearColor;
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
    _lbl.textColor = on ? KAccent2() : KTxt();
    [self addSubview:_lbl];

    [NSLayoutConstraint activateConstraints:@[
        [_box.leadingAnchor   constraintEqualToAnchor:self.leadingAnchor constant:14],
        [_box.centerYAnchor   constraintEqualToAnchor:self.centerYAnchor],
        [_box.widthAnchor     constraintEqualToConstant:14],
        [_box.heightAnchor    constraintEqualToConstant:14],
        [_check.centerXAnchor constraintEqualToAnchor:_box.centerXAnchor],
        [_check.centerYAnchor constraintEqualToAnchor:_box.centerYAnchor],
        [_lbl.leadingAnchor   constraintEqualToAnchor:_box.trailingAnchor constant:9],
        [_lbl.centerYAnchor   constraintEqualToAnchor:self.centerYAnchor],
        [_lbl.trailingAnchor  constraintEqualToAnchor:self.trailingAnchor constant:-14],
    ]];
    [self addTarget:self action:@selector(tapped) forControlEvents:UIControlEventTouchUpInside];
    return self;
}
- (void)tapped {
    _isOn = !_isOn;
    [UIView animateWithDuration:0.12 animations:^{
        self->_box.backgroundColor = self->_isOn ? KAccent() : UIColor.clearColor;
        self->_check.alpha         = self->_isOn ? 1.0 : 0.0;
        self->_lbl.textColor       = self->_isOn ? KAccent2() : KTxt();
    }];
    if (self.onChange) self.onChange(_isOn);
}
- (void)setIsOn:(BOOL)v {
    _isOn = v;
    _box.backgroundColor = v ? KAccent() : UIColor.clearColor;
    _check.alpha         = v ? 1.0 : 0.0;
    _lbl.textColor       = v ? KAccent2() : KTxt();
}
@end

// ── MSlider ───────────────────────────────────────────────────────────────────
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
    lbl.font      = [UIFont systemFontOfSize:12];
    lbl.textColor = KTxt();
    [self addSubview:lbl];

    _valLbl = [UILabel new];
    _valLbl.translatesAutoresizingMaskIntoConstraints = NO;
    _valLbl.text          = [NSString stringWithFormat:fmt, v];
    _valLbl.font          = [UIFont monospacedDigitSystemFontOfSize:11 weight:UIFontWeightMedium];
    _valLbl.textColor     = KAccent2();
    _valLbl.textAlignment = NSTextAlignmentRight;
    [self addSubview:_valLbl];

    _sl = [UISlider new];
    _sl.translatesAutoresizingMaskIntoConstraints = NO;
    _sl.minimumValue          = mn;
    _sl.maximumValue          = mx;
    _sl.value                 = v;
    _sl.minimumTrackTintColor = KAccent();
    _sl.maximumTrackTintColor = KSep();
    _sl.thumbTintColor        = KAccent2();
    [_sl addTarget:self action:@selector(slChanged) forControlEvents:UIControlEventValueChanged];
    [self addSubview:_sl];

    [NSLayoutConstraint activateConstraints:@[
        [lbl.leadingAnchor      constraintEqualToAnchor:self.leadingAnchor constant:14],
        [lbl.topAnchor          constraintEqualToAnchor:self.topAnchor constant:6],
        [_valLbl.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-14],
        [_valLbl.centerYAnchor  constraintEqualToAnchor:lbl.centerYAnchor],
        [_valLbl.widthAnchor    constraintEqualToConstant:60],
        [_sl.leadingAnchor      constraintEqualToAnchor:self.leadingAnchor constant:14],
        [_sl.trailingAnchor     constraintEqualToAnchor:self.trailingAnchor constant:-14],
        [_sl.bottomAnchor       constraintEqualToAnchor:self.bottomAnchor constant:-4],
    ]];
    return self;
}
- (void)slChanged {
    _valLbl.text = [NSString stringWithFormat:_fmt, _sl.value];
    if (self.onChange) self.onChange(_sl.value);
}
@end

// ── TabButton ─────────────────────────────────────────────────────────────────
@interface TabButton : UIButton
@property (nonatomic, assign) NSInteger tabIdx;
@end
@implementation TabButton @end

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

- (BOOL)isHUDEnabled          { return IsHUDEnabled(); }
- (void)setHUDEnabled:(BOOL)e { SetHUDEnabled(e); }

- (void)loadView {
    CGRect bounds = UIScreen.mainScreen.bounds;
    self.view = [[UIView alloc] initWithFrame:bounds];
    self.view.backgroundColor = UIColor.clearColor;

    self.backgroundView = [[UIView alloc] initWithFrame:bounds];
    self.backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.backgroundView.backgroundColor = UIColor.clearColor;
    [self.view addSubview:self.backgroundView];

    [self buildPanel];
}

// ── Panel ─────────────────────────────────────────────────────────────────────
- (void)buildPanel {
    CGRect sc  = UIScreen.mainScreen.bounds;
    CGFloat pw = MIN(sc.size.width - 32, 370);
    CGFloat ph = MIN(sc.size.height - 80, 460);
    CGFloat px = (sc.size.width  - pw) / 2;
    CGFloat py = (sc.size.height - ph) / 2;

    _panel = [[UIView alloc] initWithFrame:CGRectMake(px, py, pw, ph)];
    _panel.backgroundColor    = UIColor.clearColor;
    _panel.layer.shadowColor  = [UIColor colorWithRed:0.6 green:0.1 blue:0.9 alpha:0.45].CGColor;
    _panel.layer.shadowOffset = CGSizeMake(0, 6);
    _panel.layer.shadowRadius = 18;
    _panel.layer.shadowOpacity = 1.0;
    [self.view addSubview:_panel];

    // Clip container
    UIView *clip = [[UIView alloc] initWithFrame:_panel.bounds];
    clip.backgroundColor    = KBG();
    clip.layer.cornerRadius = 12;
    clip.layer.masksToBounds = YES;
    clip.autoresizingMask   = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [_panel addSubview:clip];

    // ── Title bar ─────────────────────────────────────────────────────────
    UIView *bar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, pw, 44)];
    bar.backgroundColor = KPanel();
    [clip addSubview:bar];

    // Purple top line
    UIView *topLine = [[UIView alloc] initWithFrame:CGRectMake(0, 0, pw, 2)];
    topLine.backgroundColor = KAccent();
    [bar addSubview:topLine];

    UILabel *titleLbl = [[UILabel alloc] initWithFrame:CGRectMake(14, 0, 150, 44)];
    titleLbl.text      = @"extrahook";
    titleLbl.font      = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
    titleLbl.textColor = KTxt();
    [bar addSubview:titleLbl];

    _injectBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    _injectBtn.frame                = CGRectMake(pw - 92, 10, 80, 24);
    _injectBtn.layer.cornerRadius   = 12;
    _injectBtn.layer.masksToBounds  = YES;
    _injectBtn.titleLabel.font      = [UIFont systemFontOfSize:11 weight:UIFontWeightSemibold];
    [_injectBtn addTarget:self action:@selector(tapInject) forControlEvents:UIControlEventTouchUpInside];
    [bar addSubview:_injectBtn];
    [self updateInjectBtn];

    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGesture:)];
    [bar addGestureRecognizer:pan];

    // ── Sidebar ───────────────────────────────────────────────────────────
    CGFloat sw = 50;
    UIView *side = [[UIView alloc] initWithFrame:CGRectMake(0, 44, sw, ph - 44)];
    side.backgroundColor = KPanel();
    [clip addSubview:side];

    UIView *sideDiv = [[UIView alloc] initWithFrame:CGRectMake(sw, 44, 0.5, ph - 44)];
    sideDiv.backgroundColor = KSep();
    [clip addSubview:sideDiv];

    // SF Symbol names + labels for each tab
    NSArray *sfNames = @[@"eye.fill", @"scope", @"figure.run", @"bolt.fill", @"gearshape.fill"];
    NSArray *labels  = @[@"ESP",      @"AIM",   @"MOVE",       @"MISC",      @"CFG"];
    NSMutableArray *btns = [NSMutableArray new];
    CGFloat tabH = (ph - 44) / (CGFloat)sfNames.count;

    for (NSInteger i = 0; i < (NSInteger)sfNames.count; i++) {
        TabButton *btn = [TabButton buttonWithType:UIButtonTypeCustom];
        btn.frame  = CGRectMake(0, tabH * i, sw, tabH);
        btn.tabIdx = i;
        btn.tag    = i;

        // SF Symbol icon
        UIImageView *iv = [[UIImageView alloc] init];
        iv.translatesAutoresizingMaskIntoConstraints = NO;
        UIImage *sym = [UIImage systemImageNamed:sfNames[i]
                               withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:18 weight:UIImageSymbolWeightRegular]];
        iv.image               = sym;
        iv.tintColor           = KSub();
        iv.contentMode         = UIViewContentModeScaleAspectFit;
        iv.tag                 = 501;
        [btn addSubview:iv];

        // Tab label
        UILabel *nm = [UILabel new];
        nm.translatesAutoresizingMaskIntoConstraints = NO;
        nm.text          = labels[i];
        nm.font          = [UIFont systemFontOfSize:8 weight:UIFontWeightMedium];
        nm.textColor     = KSub();
        nm.textAlignment = NSTextAlignmentCenter;
        nm.tag           = 500;
        [btn addSubview:nm];

        [NSLayoutConstraint activateConstraints:@[
            [iv.centerXAnchor constraintEqualToAnchor:btn.centerXAnchor],
            [iv.topAnchor     constraintEqualToAnchor:btn.topAnchor constant:tabH * 0.18],
            [iv.widthAnchor   constraintEqualToConstant:22],
            [iv.heightAnchor  constraintEqualToConstant:22],
            [nm.centerXAnchor constraintEqualToAnchor:btn.centerXAnchor],
            [nm.topAnchor     constraintEqualToAnchor:iv.bottomAnchor constant:4],
        ]];

        [btn addTarget:self action:@selector(tabTap:) forControlEvents:UIControlEventTouchUpInside];
        [side addSubview:btn];
        [btns addObject:btn];
    }
    _tabBtns = [btns copy];

    // ── Content area ──────────────────────────────────────────────────────
    _contentScroll = [[UIScrollView alloc] initWithFrame:CGRectMake(sw, 44, pw - sw, ph - 44)];
    _contentScroll.backgroundColor = UIColor.clearColor;
    _contentScroll.showsVerticalScrollIndicator = NO;
    [clip addSubview:_contentScroll];

    _contentStack = [[UIStackView alloc] initWithFrame:CGRectMake(0, 0, pw - sw, 0)];
    _contentStack.axis             = UILayoutConstraintAxisVertical;
    _contentStack.spacing          = 0;
    _contentStack.translatesAutoresizingMaskIntoConstraints = NO;
    [_contentScroll addSubview:_contentStack];

    [NSLayoutConstraint activateConstraints:@[
        [_contentStack.topAnchor     constraintEqualToAnchor:_contentScroll.topAnchor],
        [_contentStack.leadingAnchor constraintEqualToAnchor:_contentScroll.leadingAnchor],
        [_contentStack.trailingAnchor constraintEqualToAnchor:_contentScroll.trailingAnchor],
        [_contentStack.bottomAnchor  constraintEqualToAnchor:_contentScroll.bottomAnchor],
        [_contentStack.widthAnchor   constraintEqualToAnchor:_contentScroll.widthAnchor],
    ]];

    _curTab = 0;
    [self loadTab:0];
    [self updateTabHighlight];
}

// ── Inject button ──────────────────────────────────────────────────────────────
- (void)updateInjectBtn {
    if (_isActive) {
        [_injectBtn setTitle:@"◼  STOP"  forState:UIControlStateNormal];
        _injectBtn.backgroundColor = [UIColor colorWithRed:0.80 green:0.10 blue:0.20 alpha:1.0];
    } else {
        [_injectBtn setTitle:@"▶  START" forState:UIControlStateNormal];
        _injectBtn.backgroundColor = KAccent();
    }
    [_injectBtn setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
}

- (void)tapInject {
    UIImpactFeedbackGenerator *hap = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium];
    [hap impactOccurred];
    _isActive = !_isActive;
    [self setHUDEnabled:_isActive];
    [self updateInjectBtn];
}

- (void)reloadMainButtonState {
    _isActive = [self isHUDEnabled];
    [self updateInjectBtn];
}

// ── Tabs ──────────────────────────────────────────────────────────────────────
- (void)tabTap:(TabButton *)btn {
    if (btn.tag == _curTab) return;
    _curTab = btn.tag;
    [self loadTab:_curTab];
    [self updateTabHighlight];
    [_contentScroll setContentOffset:CGPointZero animated:NO];
}

- (void)updateTabHighlight {
    for (TabButton *b in _tabBtns) {
        BOOL sel = (b.tag == _curTab);
        UIView *bar = [b viewWithTag:200];
        if (!bar) {
            bar = [[UIView alloc] initWithFrame:CGRectMake(0, 8, 3, b.frame.size.height - 16)];
            bar.backgroundColor    = KAccent();
            bar.layer.cornerRadius = 1.5;
            bar.tag = 200;
            [b addSubview:bar];
        }
        bar.hidden        = !sel;
        b.backgroundColor = sel ? [UIColor colorWithRed:0.62 green:0.12 blue:0.95 alpha:0.12] : UIColor.clearColor;
        UILabel *nm = (UILabel *)[b viewWithTag:500];
        if (nm) nm.textColor = sel ? KAccent2() : KSub();
        UIImageView *iv = (UIImageView *)[b viewWithTag:501];
        if (iv) iv.tintColor = sel ? KAccent2() : KSub();
    }
}

- (void)loadTab:(NSInteger)tab {
    for (UIView *v in _contentStack.arrangedSubviews) {
        [_contentStack removeArrangedSubview:v];
        [v removeFromSuperview];
    }
    switch (tab) {
        case 0: [self buildESP];      break;
        case 1: [self buildAimbot];   break;
        case 2: [self buildMovement]; break;
        case 3: [self buildMisc];     break;
        case 4: [self buildConfig];   break;
    }
}

// ── Section header ────────────────────────────────────────────────────────────
- (UIView *)sec:(NSString *)title {
    UIView *v = [UIView new];
    v.translatesAutoresizingMaskIntoConstraints = NO;
    [v.heightAnchor constraintEqualToConstant:28].active = YES;

    UIView *line = [UIView new];
    line.translatesAutoresizingMaskIntoConstraints = NO;
    line.backgroundColor    = KAccent();
    line.layer.cornerRadius = 1.5;
    [v addSubview:line];

    UILabel *lbl = [UILabel new];
    lbl.translatesAutoresizingMaskIntoConstraints = NO;
    lbl.text      = title;
    lbl.font      = [UIFont systemFontOfSize:10 weight:UIFontWeightSemibold];
    lbl.textColor = KAccent2();
    [v addSubview:lbl];

    [NSLayoutConstraint activateConstraints:@[
        [line.leadingAnchor constraintEqualToAnchor:v.leadingAnchor constant:14],
        [line.centerYAnchor constraintEqualToAnchor:v.centerYAnchor],
        [line.widthAnchor   constraintEqualToConstant:3],
        [line.heightAnchor  constraintEqualToConstant:12],
        [lbl.leadingAnchor  constraintEqualToAnchor:line.trailingAnchor constant:7],
        [lbl.centerYAnchor  constraintEqualToAnchor:v.centerYAnchor],
    ]];
    return v;
}

// ── Row builder ───────────────────────────────────────────────────────────────
- (MRow *)row:(NSString *)t on:(BOOL)on change:(void(^)(BOOL))cb {
    MRow *r = [[MRow alloc] initTitle:t on:on];
    r.onChange = cb;
    return r;
}

- (void)addV:(UIView *)v   { [_contentStack addArrangedSubview:v]; }
- (void)addSep              { [_contentStack addArrangedSubview:Sep()]; }
- (void)addSpc:(CGFloat)h   { [_contentStack addArrangedSubview:Spacer(h)]; }

// ── Slider builder ────────────────────────────────────────────────────────────
- (MSlider *)sl:(NSString *)t mn:(float)mn mx:(float)mx val:(float)v fmt:(NSString *)fmt change:(void(^)(float))cb {
    MSlider *s = [[MSlider alloc] initTitle:t min:mn max:mx val:v fmt:fmt];
    s.onChange  = cb;
    return s;
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB: ESP
// ─────────────────────────────────────────────────────────────────────────────
- (void)buildESP {
    [self addSpc:4];
    [self addV:[self sec:@"BOXES"]];
    [self addV:[self row:@"Box ESP"           on:(BOOL)esp_box_enabled     change:^(BOOL b){ esp_box_enabled     = b; }]];
    [self addSep];
    [self addV:[self row:@"Box Outline"       on:(BOOL)esp_box_outline     change:^(BOOL b){ esp_box_outline     = b; }]];
    [self addSep];
    [self addV:[self row:@"Box Fill"          on:(BOOL)esp_box_fill        change:^(BOOL b){ esp_box_fill        = b; }]];
    [self addSep];
    [self addV:[self row:@"Corner Box"        on:(BOOL)esp_box_corner      change:^(BOOL b){ esp_box_corner      = b; }]];
    [self addSep];
    [self addV:[self row:@"3D Box"            on:(BOOL)esp_box_3d          change:^(BOOL b){ esp_box_3d          = b; }]];
    [self addSep];
    [self addV:[self row:@"Lines to Players"  on:(BOOL)esp_line_enabled    change:^(BOOL b){ esp_line_enabled    = b; }]];
    [self addSep];
    [self addV:[self row:@"Line Outline"      on:(BOOL)esp_line_outline    change:^(BOOL b){ esp_line_outline    = b; }]];

    [self addSpc:4];
    [self addV:[self sec:@"INFO"]];
    [self addV:[self row:@"Names"             on:(BOOL)esp_name_enabled      change:^(BOOL b){ esp_name_enabled      = b; }]];
    [self addSep];
    [self addV:[self row:@"Name Outline"      on:(BOOL)esp_name_outline      change:^(BOOL b){ esp_name_outline      = b; }]];
    [self addSep];
    [self addV:[self row:@"Health Text"       on:(BOOL)esp_health_enabled    change:^(BOOL b){ esp_health_enabled    = b; }]];
    [self addSep];
    [self addV:[self row:@"Health Bar"        on:(BOOL)esp_health_bar_enabled change:^(BOOL b){ esp_health_bar_enabled = b; }]];
    [self addSep];
    [self addV:[self row:@"Health Bar Outline" on:(BOOL)esp_health_bar_outline change:^(BOOL b){ esp_health_bar_outline = b; }]];
    [self addSep];
    [self addV:[self row:@"Weapon Name"       on:(BOOL)esp_weapon_enabled    change:^(BOOL b){ esp_weapon_enabled    = b; }]];
    [self addSep];
    [self addV:[self row:@"Weapon Icon"       on:(BOOL)esp_weapon_icon_enabled change:^(BOOL b){ esp_weapon_icon_enabled = b; }]];
    [self addSep];
    [self addV:[self row:@"Platform Badge"    on:(BOOL)esp_platform_enabled  change:^(BOOL b){ esp_platform_enabled  = b; }]];
    [self addSep];
    [self addV:[self row:@"Avatar"            on:(BOOL)esp_avatar_enabled    change:^(BOOL b){ esp_avatar_enabled    = b; }]];
    [self addSep];
    [self addV:[self row:@"Team Check"        on:(BOOL)esp_team_check        change:^(BOOL b){ esp_team_check        = b; }]];
    [self addSpc:12];
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB: AIMBOT
// ─────────────────────────────────────────────────────────────────────────────
- (void)buildAimbot {
    [self addSpc:4];
    [self addV:[self sec:@"AIMBOT"]];
    [self addV:[self row:@"Enabled"       on:(BOOL)aimbot_enabled         change:^(BOOL b){ aimbot_enabled         = b; }]];
    [self addSep];
    [self addV:[self row:@"Visible Check" on:(BOOL)aimbot_visible_check   change:^(BOOL b){ aimbot_visible_check   = b; }]];
    [self addSep];
    [self addV:[self row:@"Shoot Check"   on:(BOOL)aimbot_shooting_check  change:^(BOOL b){ aimbot_shooting_check  = b; }]];
    [self addSep];
    [self addV:[self row:@"Knife Bot"     on:(BOOL)aimbot_knife_bot       change:^(BOOL b){ aimbot_knife_bot       = b; }]];
    [self addSep];
    [self addV:[self row:@"FOV Visible"   on:(BOOL)aimbot_fov_visible     change:^(BOOL b){ aimbot_fov_visible     = b; }]];
    [self addSep];
    [self addV:[self row:@"Team Check"    on:(BOOL)aimbot_team_check      change:^(BOOL b){ aimbot_team_check      = b; }]];
    [self addSep];

    [self addV:[self sl:@"FOV"    mn:0 mx:180 val:aimbot_fov      fmt:@"%.0f°" change:^(float v){ aimbot_fov    = v; }]];
    [self addV:[self sl:@"Smooth" mn:0 mx:20  val:aimbot_smooth   fmt:@"%.1f"  change:^(float v){ aimbot_smooth = v; }]];

    [self addSpc:4];
    [self addV:[self sec:@"TRIGGERBOT"]];
    [self addV:[self row:@"Triggerbot" on:(BOOL)aimbot_triggerbot change:^(BOOL b){ aimbot_triggerbot = b; }]];
    [self addSep];
    [self addV:[self sl:@"Trigger Delay" mn:0 mx:500 val:aimbot_trigger_delay fmt:@"%.0fms" change:^(float v){ aimbot_trigger_delay = v; }]];

    [self addSpc:4];
    [self addV:[self sec:@"ANTI-RECOIL (RCS)"]];
    [self addV:[self row:@"Anti-Recoil" on:(BOOL)esp_rcs_enabled change:^(BOOL b){ esp_rcs_enabled = b; }]];
    [self addSep];
    [self addV:[self sl:@"RCS Horizontal" mn:0 mx:2 val:esp_rcs_h fmt:@"%.2f" change:^(float v){ esp_rcs_h = v; }]];
    [self addV:[self sl:@"RCS Vertical"   mn:0 mx:2 val:esp_rcs_v fmt:@"%.2f" change:^(float v){ esp_rcs_v = v; }]];
    [self addSpc:12];
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB: MOVEMENT
// ─────────────────────────────────────────────────────────────────────────────
- (void)buildMovement {
    [self addSpc:4];
    [self addV:[self sec:@"MOVEMENT"]];
    [self addV:[self row:@"Bunny Hop"       on:(BOOL)esp_bunny_hop  change:^(BOOL b){ esp_bunny_hop  = b; }]];
    [self addSep];
    [self addV:[self row:@"Air Jump"        on:(BOOL)esp_air_jump   change:^(BOOL b){ esp_air_jump   = b; }]];
    [self addSep];
    [self addV:[self row:@"Fast Knife"      on:(BOOL)esp_fast_knife change:^(BOOL b){ esp_fast_knife = b; }]];

    [self addSpc:4];
    [self addV:[self sec:@"BHOP MODE"]];

    UISegmentedControl *seg = [[UISegmentedControl alloc] initWithItems:@[@"Off", @"Auto", @"Semi"]];
    seg.translatesAutoresizingMaskIntoConstraints = NO;
    seg.selectedSegmentIndex = esp_bhop_setting;
    [seg setTitleTextAttributes:@{NSForegroundColorAttributeName: KTxt()} forState:UIControlStateNormal];
    [seg setTitleTextAttributes:@{NSForegroundColorAttributeName: UIColor.whiteColor} forState:UIControlStateSelected];
    if (@available(iOS 13.0, *)) { seg.selectedSegmentTintColor = KAccent(); }
    [seg addTarget:self action:@selector(bhopSeg:) forControlEvents:UIControlEventValueChanged];

    UIView *segWrap = [UIView new];
    segWrap.translatesAutoresizingMaskIntoConstraints = NO;
    [segWrap.heightAnchor constraintEqualToConstant:50].active = YES;
    [segWrap addSubview:seg];
    [NSLayoutConstraint activateConstraints:@[
        [seg.leadingAnchor  constraintEqualToAnchor:segWrap.leadingAnchor  constant:14],
        [seg.trailingAnchor constraintEqualToAnchor:segWrap.trailingAnchor constant:-14],
        [seg.centerYAnchor  constraintEqualToAnchor:segWrap.centerYAnchor],
    ]];
    [self addV:segWrap];

    [self addSpc:4];
    [self addV:[self sec:@"VIEWMODEL"]];
    [self addV:[self row:@"Custom Viewmodel" on:(BOOL)viewmodel_enabled change:^(BOOL b){ viewmodel_enabled = b; }]];
    [self addSep];
    [self addV:[self sl:@"X Offset" mn:-10 mx:10 val:viewmodel_x fmt:@"%.1f" change:^(float v){ viewmodel_x = v; }]];
    [self addV:[self sl:@"Y Offset" mn:-10 mx:10 val:viewmodel_y fmt:@"%.1f" change:^(float v){ viewmodel_y = v; }]];
    [self addV:[self sl:@"Z Offset" mn:-10 mx:10 val:viewmodel_z fmt:@"%.1f" change:^(float v){ viewmodel_z = v; }]];
    [self addSpc:12];
}

- (void)bhopSeg:(UISegmentedControl *)s { esp_bhop_setting = (int)s.selectedSegmentIndex; }

// ─────────────────────────────────────────────────────────────────────────────
// TAB: MISC
// ─────────────────────────────────────────────────────────────────────────────
- (void)buildMisc {
    [self addSpc:4];
    [self addV:[self sec:@"PLAYER"]];
    [self addV:[self row:@"Invisible"      on:(BOOL)esp_invisible change:^(BOOL b){ esp_invisible = b; }]];
    [self addSep];
    [self addV:[self row:@"Add Score"      on:(BOOL)esp_addscore  change:^(BOOL b){ esp_addscore  = b; }]];

    [self addSpc:4];
    [self addV:[self sec:@"WEAPON"]];
    [self addV:[self row:@"Infinite Ammo"  on:(BOOL)esp_inf_ammo  change:^(BOOL b){ esp_inf_ammo  = b; }]];
    [self addSep];
    [self addV:[self row:@"No Spread"      on:(BOOL)esp_no_spread change:^(BOOL b){ esp_no_spread = b; }]];
    [self addSep];
    [self addV:[self row:@"Wallshot"       on:(BOOL)esp_wallshot  change:^(BOOL b){ esp_wallshot  = b; }]];
    [self addSep];
    [self addV:[self row:@"Fast Fire Rate" on:(BOOL)esp_fire_rate change:^(BOOL b){ esp_fire_rate = b; }]];
    [self addSpc:12];
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB: CONFIG
// ─────────────────────────────────────────────────────────────────────────────
- (void)buildConfig {
    [self addSpc:4];
    [self addV:[self sec:@"OPTIONS"]];
    [self addV:[self row:@"Auto Load Config"  on:(BOOL)esp_auto_load        change:^(BOOL b){ esp_auto_load        = b; }]];
    [self addSep];
    [self addV:[self row:@"Screenshot Safe"   on:(BOOL)esp_screenshot_safe  change:^(BOOL b){ esp_screenshot_safe  = b; }]];

    [self addSpc:4];
    [self addV:[self sec:@"CONFIGS"]];

    NSArray<NSString*> *cfgs = cfg_get_list();
    for (NSString *name in cfgs) {
        [self addV:[self cfgRow:name]];
        [self addSep];
    }

    // Save button
    UIButton *saveBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    saveBtn.translatesAutoresizingMaskIntoConstraints = NO;
    saveBtn.backgroundColor    = KAccent();
    saveBtn.layer.cornerRadius = 8;
    saveBtn.layer.masksToBounds = YES;
    [saveBtn setTitle:@"Save New Config" forState:UIControlStateNormal];
    [saveBtn setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    saveBtn.titleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightSemibold];
    [saveBtn addTarget:self action:@selector(saveNewConfig) forControlEvents:UIControlEventTouchUpInside];

    UIView *savWrap = [UIView new];
    savWrap.translatesAutoresizingMaskIntoConstraints = NO;
    [savWrap.heightAnchor constraintEqualToConstant:52].active = YES;
    [savWrap addSubview:saveBtn];
    [NSLayoutConstraint activateConstraints:@[
        [saveBtn.leadingAnchor  constraintEqualToAnchor:savWrap.leadingAnchor  constant:14],
        [saveBtn.trailingAnchor constraintEqualToAnchor:savWrap.trailingAnchor constant:-14],
        [saveBtn.centerYAnchor  constraintEqualToAnchor:savWrap.centerYAnchor],
        [saveBtn.heightAnchor   constraintEqualToConstant:34],
    ]];
    [self addV:savWrap];
    [self addSpc:12];
}

- (UIView *)cfgRow:(NSString *)name {
    UIView *row = [UIView new];
    row.translatesAutoresizingMaskIntoConstraints = NO;
    [row.heightAnchor constraintEqualToConstant:40].active = YES;

    UILabel *lbl = [UILabel new];
    lbl.translatesAutoresizingMaskIntoConstraints = NO;
    lbl.text      = name;
    lbl.font      = [UIFont systemFontOfSize:13];
    lbl.textColor = KTxt();
    [row addSubview:lbl];

    UIButton *loadBtn = [self miniBtn:@"Load" color:KAccent()];
    loadBtn.accessibilityLabel = name;
    [loadBtn addTarget:self action:@selector(loadCfg:) forControlEvents:UIControlEventTouchUpInside];
    [row addSubview:loadBtn];

    UIButton *delBtn = [self miniBtn:@"Del" color:[UIColor colorWithRed:0.80 green:0.10 blue:0.20 alpha:1.0]];
    delBtn.accessibilityLabel = name;
    [delBtn addTarget:self action:@selector(delCfg:) forControlEvents:UIControlEventTouchUpInside];
    [row addSubview:delBtn];

    [NSLayoutConstraint activateConstraints:@[
        [lbl.leadingAnchor     constraintEqualToAnchor:row.leadingAnchor constant:14],
        [lbl.centerYAnchor     constraintEqualToAnchor:row.centerYAnchor],
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

- (UIButton *)miniBtn:(NSString *)t color:(UIColor *)c {
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

- (void)saveNewConfig {
    UIAlertController *a = [UIAlertController alertControllerWithTitle:@"Save Config"
                                                               message:@"Enter config name:"
                                                        preferredStyle:UIAlertControllerStyleAlert];
    [a addTextFieldWithConfigurationHandler:^(UITextField *tf) {
        tf.placeholder = @"my_config";
        tf.clearButtonMode = UITextFieldViewModeWhileEditing;
    }];
    [a addAction:[UIAlertAction actionWithTitle:@"Save" style:UIAlertActionStyleDefault handler:^(UIAlertAction *_) {
        NSString *name = a.textFields.firstObject.text;
        if (name.length) { cfg_create(name); [self buildConfig]; }
    }]];
    [a addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:a animated:YES completion:nil];
}

- (void)loadCfg:(UIButton *)btn { cfg_load(btn.accessibilityLabel); [self loadTab:_curTab]; }
- (void)delCfg:(UIButton *)btn  { cfg_delete(btn.accessibilityLabel); [self buildConfig]; }

// ── Drag ──────────────────────────────────────────────────────────────────────
- (void)panGesture:(UIPanGestureRecognizer *)g {
    CGPoint pt = [g locationInView:self.view];
    if (g.state == UIGestureRecognizerStateBegan) {
        _dragOffset = CGPointMake(pt.x - _panel.frame.origin.x, pt.y - _panel.frame.origin.y);
    } else if (g.state == UIGestureRecognizerStateChanged) {
        CGRect f  = _panel.frame;
        CGRect sc = UIScreen.mainScreen.bounds;
        f.origin.x = MAX(0, MIN(pt.x - _dragOffset.x, sc.size.width  - f.size.width));
        f.origin.y = MAX(0, MIN(pt.y - _dragOffset.y, sc.size.height - f.size.height));
        _panel.frame = f;
    }
}

@end
