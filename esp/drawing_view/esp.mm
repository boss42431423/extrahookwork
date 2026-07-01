#import "esp.h"
#import "tt.h"
#import <UIKit/UIGestureRecognizerSubclass.h>
#import <AVFoundation/AVFoundation.h>
#import <objc/runtime.h>
#import <sys/sysctl.h>
#include "obfusheader.h"
#import "UIView+SecureView.h"
#include <atomic>
// Rifles
#import "assets/rifles/akr.h"
#import "assets/rifles/akr12.h"
#import "assets/rifles/famas.h"
#import "assets/rifles/fnfal.h"
#import "assets/rifles/m16.h"
#import "assets/rifles/m4.h"
#import "assets/rifles/val.h"
// Pistols
#import "assets/pistols/berettas.h"
#import "assets/pistols/desert_eagle.h"
#import "assets/pistols/five_seven.h"
#import "assets/pistols/g22.h"
#import "assets/pistols/p350.h"
#import "assets/pistols/tec9.h"
#import "assets/pistols/usp.h"
// SMGs
#import "assets/smgs/mac10.h"
#import "assets/smgs/mp5.h"
#import "assets/smgs/mp7.h"
#import "assets/smgs/p90.h"
#import "assets/smgs/ump45.h"
#import "assets/smgs/uzi.h"
// Heavy
#import "assets/heavy/fabm.h"
#import "assets/heavy/m60.h"
#import "assets/heavy/sm1014.h"
#import "assets/heavy/spas.h"
// Snipers
#import "assets/snipers/awm.h"
#import "assets/snipers/m110.h"
#import "assets/snipers/m40.h"
#import "assets/snipers/mallard.h"
// Knives
#import "assets/knives/butterfly.h"
#import "assets/knives/dual_daggers.h"
#import "assets/knives/fang.h"
#import "assets/knives/flipknife.h"
#import "assets/knives/jkommando.h"
#import "assets/knives/kabar.h"
#import "assets/knives/karambit.h"
#import "assets/knives/kukri.h"
#import "assets/knives/kunai.h"
#import "assets/knives/m9bayonet.h"
#import "assets/knives/mantis.h"
#import "assets/knives/scorpion.h"
#import "assets/knives/stiletto.h"
#import "assets/knives/sting.h"
#import "assets/knives/tanto.h"
// Grenades
#import "assets/grenades/flash.h"
#import "assets/grenades/he.h"
#import "assets/grenades/molotov.h"
#import "assets/grenades/smoke.h"
#import "assets/grenades/thermite.h"
// Other
#import "assets/other/bomb.h"

volatile bool esp_box_enabled = true;
volatile bool esp_box_outline = false;
volatile bool esp_box_fill = false;
volatile bool esp_box_corner = false;
volatile bool esp_box_3d = false;
volatile bool esp_line_enabled = false;
volatile bool esp_line_outline = false;
volatile bool esp_invisible = false;
volatile bool esp_addscore = false;
volatile bool esp_inf_ammo = false;
volatile bool esp_no_spread = false;
volatile bool esp_air_jump = false;
volatile bool esp_fast_knife = false;
volatile bool esp_bunny_hop = false;
volatile bool esp_wallshot = false;
volatile bool esp_fire_rate = false;
volatile bool esp_team_check = true;
volatile bool esp_screenshot_safe = false;

volatile bool aimbot_enabled        = false;
volatile bool aimbot_visible_check  = false;
volatile bool aimbot_shooting_check = false;
volatile bool aimbot_knife_bot      = false;
volatile float aimbot_smooth        = 5.0f;
volatile float aimbot_trigger_delay = 0.1f;
volatile int   aimbot_bone_index    = 0;   

volatile bool  esp_rcs_enabled   = false;
volatile float esp_rcs_h         = 0.0f;
volatile float esp_rcs_v         = 0.0f;

volatile int   esp_bhop_setting  = 5;
volatile bool aimbot_triggerbot   = false;
volatile bool aimbot_fov_visible  = true;
volatile float aimbot_fov         = 120.0f;
volatile bool aimbot_team_check   = true;
volatile bool esp_name_enabled = false;
volatile bool esp_name_outline = false;
volatile bool esp_health_enabled = false;
volatile bool esp_health_bar_enabled = false;
volatile bool esp_health_bar_outline = false;
volatile bool esp_weapon_enabled     = false;
volatile bool esp_weapon_icon_enabled = false;
volatile bool esp_platform_enabled = false;
volatile bool esp_avatar_enabled   = false;

volatile bool  viewmodel_enabled  = false;
volatile float viewmodel_x        = 0.0f;
volatile float viewmodel_y        = 0.0f;
volatile float viewmodel_z        = 0.0f;

volatile bool esp_auto_load = false;
NSString *esp_selected_config = nil;

@interface UIWindow (Private)
- (void)_setSecure:(BOOL)secure;
- (unsigned int)_contextId;
@end

@interface LSApplicationWorkspace : NSObject
+ (instancetype)defaultWorkspace;
- (BOOL)openApplicationWithBundleID:(NSString *)bundleID;
@end

@interface SBSAccessibilityWindowHostingController : NSObject
- (void)registerWindowWithContextID:(unsigned int)contextID atLevel:(double)level;
@end

struct ESPBoxData {
    CGRect rect;
};

@interface ESP_View ()
@property (nonatomic, strong) CADisplayLink     *displayLinkData;
@property (nonatomic, strong) UILabel           *playerCountLabel;
@property (nonatomic, strong) UILabel           *noPlayersLabel;
@property (nonatomic, strong) AVPlayer          *backgroundPlayer;
@property (nonatomic, assign) BOOL              hasAttemptedLaunch;
@property (nonatomic, strong) CAShapeLayer      *espBoxLayer;
@property (nonatomic, strong) CAShapeLayer      *espBoxFillLayer;
@property (nonatomic, strong) NSMutableArray<UILabel *> *nameLabelPool;
@property (nonatomic, strong) NSMutableArray<UILabel *> *healthLabelPool;
@property (nonatomic, strong) NSMutableArray<UILabel *> *weaponLabelPool;
@property (nonatomic, strong) NSMutableArray<UIImageView *> *weaponIconPool;
@property (nonatomic, strong) NSMutableArray<UILabel *> *platformLabelPool;
@property (nonatomic, strong) NSMutableArray<UIImageView *> *avatarPool;
@property (nonatomic, strong) CAShapeLayer      *espLineLayer;
@property (nonatomic, strong) CAShapeLayer      *espBoxOutlineLayer;
@property (nonatomic, strong) CAShapeLayer      *espHealthBarLayer;
@property (nonatomic, strong) CAShapeLayer      *espHealthBarOutlineLayer;
@property (nonatomic, strong) CAShapeLayer      *espLineOutlineLayer;
@property (nonatomic, strong) UILabel           *watermarkLabel;
@property (nonatomic, strong) CAShapeLayer      *fovCircleLayer;
@property (nonatomic, strong) CAShapeLayer      *fovCircleOutlineLayer;
@property (nonatomic, assign) uint64_t          aimbotCurrentTarget;
@property (nonatomic, assign) double            aimbotLastWriteTime;
@property (nonatomic, assign) BOOL              triggerbotShooting;
@property (nonatomic, assign) double            triggerbotLastShotTime;
@property (nonatomic, assign) BOOL              isESPCountEnabled;
@end

// ─────────────────────────────────────────────────────────────────────────────
// In-game menu: helpers + MenuView
// ─────────────────────────────────────────────────────────────────────────────

static UIColor *MC_BG(void)   { return [UIColor colorWithRed:0.09f green:0.09f blue:0.12f alpha:0.97f]; }
static UIColor *MC_PNL(void)  { return [UIColor colorWithRed:0.13f green:0.13f blue:0.17f alpha:1.0f]; }
static UIColor *MC_ACC(void)  { return [UIColor colorWithRed:0.62f green:0.12f blue:0.95f alpha:1.0f]; }
static UIColor *MC_ACC2(void) { return [UIColor colorWithRed:0.78f green:0.30f blue:1.00f alpha:1.0f]; }
static UIColor *MC_TXT(void)  { return [UIColor colorWithRed:0.88f green:0.88f blue:0.92f alpha:1.0f]; }
static UIColor *MC_SUB(void)  { return [UIColor colorWithRed:0.48f green:0.48f blue:0.55f alpha:1.0f]; }
static UIColor *MC_SEP(void)  { return [UIColor colorWithRed:0.22f green:0.22f blue:0.28f alpha:1.0f]; }

// ── Toggle row ────────────────────────────────────────────────────────────────
@interface MC_Row : UIControl
@property (nonatomic, assign) BOOL isOn;
@property (nonatomic, copy)   void(^onChange)(BOOL);
- (instancetype)initWithTitle:(NSString *)t on:(BOOL)on;
@end

@implementation MC_Row {
    UIView  *_box;
    UILabel *_check;
    UILabel *_lbl;
}
- (instancetype)initWithTitle:(NSString *)t on:(BOOL)on {
    self = [super init];
    if (!self) return nil;
    _isOn = on;
    self.translatesAutoresizingMaskIntoConstraints = NO;
    [self.heightAnchor constraintEqualToConstant:34].active = YES;

    _box = [UIView new];
    _box.translatesAutoresizingMaskIntoConstraints = NO;
    _box.layer.cornerRadius = 3;
    _box.layer.borderWidth  = 1.5f;
    _box.layer.borderColor  = MC_ACC().CGColor;
    _box.backgroundColor    = on ? MC_ACC() : UIColor.clearColor;
    [self addSubview:_box];

    _check = [UILabel new];
    _check.translatesAutoresizingMaskIntoConstraints = NO;
    _check.text          = @"✓";
    _check.font          = [UIFont boldSystemFontOfSize:8];
    _check.textColor     = UIColor.whiteColor;
    _check.textAlignment = NSTextAlignmentCenter;
    _check.alpha         = on ? 1.0f : 0.0f;
    [_box addSubview:_check];

    _lbl = [UILabel new];
    _lbl.translatesAutoresizingMaskIntoConstraints = NO;
    _lbl.text      = t;
    _lbl.font      = [UIFont systemFontOfSize:12 weight:UIFontWeightRegular];
    _lbl.textColor = on ? MC_ACC2() : MC_TXT();
    [self addSubview:_lbl];

    [NSLayoutConstraint activateConstraints:@[
        [_box.leadingAnchor   constraintEqualToAnchor:self.leadingAnchor constant:12],
        [_box.centerYAnchor   constraintEqualToAnchor:self.centerYAnchor],
        [_box.widthAnchor     constraintEqualToConstant:13],
        [_box.heightAnchor    constraintEqualToConstant:13],
        [_check.centerXAnchor constraintEqualToAnchor:_box.centerXAnchor],
        [_check.centerYAnchor constraintEqualToAnchor:_box.centerYAnchor],
        [_lbl.leadingAnchor   constraintEqualToAnchor:_box.trailingAnchor constant:8],
        [_lbl.centerYAnchor   constraintEqualToAnchor:self.centerYAnchor],
        [_lbl.trailingAnchor  constraintEqualToAnchor:self.trailingAnchor constant:-10],
    ]];
    [self addTarget:self action:@selector(mc_tap) forControlEvents:UIControlEventTouchUpInside];
    return self;
}
- (void)mc_tap {
    _isOn = !_isOn;
    [UIView animateWithDuration:0.1 animations:^{
        self->_box.backgroundColor = self->_isOn ? MC_ACC() : UIColor.clearColor;
        self->_check.alpha         = self->_isOn ? 1.0f : 0.0f;
        self->_lbl.textColor       = self->_isOn ? MC_ACC2() : MC_TXT();
    }];
    if (self.onChange) self.onChange(_isOn);
}
- (void)setIsOn:(BOOL)v {
    _isOn = v;
    _box.backgroundColor = v ? MC_ACC() : UIColor.clearColor;
    _check.alpha         = v ? 1.0f : 0.0f;
    _lbl.textColor       = v ? MC_ACC2() : MC_TXT();
}
@end

// ── Slider row ────────────────────────────────────────────────────────────────
@interface MC_Slider : UIView
@property (nonatomic, copy) void(^onChange)(float);
- (instancetype)initWithTitle:(NSString *)t min:(float)mn max:(float)mx val:(float)v fmt:(NSString *)fmt;
@end

@implementation MC_Slider {
    UISlider *_sl;
    UILabel  *_valLbl;
    NSString *_fmt;
}
- (instancetype)initWithTitle:(NSString *)t min:(float)mn max:(float)mx val:(float)v fmt:(NSString *)fmt {
    self = [super init];
    if (!self) return nil;
    _fmt = fmt;
    self.translatesAutoresizingMaskIntoConstraints = NO;
    [self.heightAnchor constraintEqualToConstant:44].active = YES;

    UILabel *lbl = [UILabel new];
    lbl.translatesAutoresizingMaskIntoConstraints = NO;
    lbl.text      = t;
    lbl.font      = [UIFont systemFontOfSize:11];
    lbl.textColor = MC_TXT();
    [self addSubview:lbl];

    _valLbl = [UILabel new];
    _valLbl.translatesAutoresizingMaskIntoConstraints = NO;
    _valLbl.text          = [NSString stringWithFormat:fmt, v];
    _valLbl.font          = [UIFont monospacedDigitSystemFontOfSize:10 weight:UIFontWeightMedium];
    _valLbl.textColor     = MC_ACC2();
    _valLbl.textAlignment = NSTextAlignmentRight;
    [self addSubview:_valLbl];

    _sl = [UISlider new];
    _sl.translatesAutoresizingMaskIntoConstraints = NO;
    _sl.minimumValue          = mn;
    _sl.maximumValue          = mx;
    _sl.value                 = v;
    _sl.minimumTrackTintColor = MC_ACC();
    _sl.maximumTrackTintColor = MC_SEP();
    _sl.thumbTintColor        = MC_ACC2();
    [_sl addTarget:self action:@selector(mc_slChanged) forControlEvents:UIControlEventValueChanged];
    [self addSubview:_sl];

    [NSLayoutConstraint activateConstraints:@[
        [lbl.leadingAnchor      constraintEqualToAnchor:self.leadingAnchor constant:12],
        [lbl.topAnchor          constraintEqualToAnchor:self.topAnchor constant:4],
        [_valLbl.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-12],
        [_valLbl.centerYAnchor  constraintEqualToAnchor:lbl.centerYAnchor],
        [_valLbl.widthAnchor    constraintEqualToConstant:56],
        [_sl.leadingAnchor      constraintEqualToAnchor:self.leadingAnchor constant:12],
        [_sl.trailingAnchor     constraintEqualToAnchor:self.trailingAnchor constant:-12],
        [_sl.bottomAnchor       constraintEqualToAnchor:self.bottomAnchor constant:-4],
    ]];
    return self;
}
- (void)mc_slChanged {
    _valLbl.text = [NSString stringWithFormat:_fmt, _sl.value];
    if (self.onChange) self.onChange(_sl.value);
}
@end

// ── Tab button ─────────────────────────────────────────────────────────────────
@interface MC_TabBtn : UIButton
@property (nonatomic, assign) NSInteger tabIdx;
@end
@implementation MC_TabBtn @end

// ─────────────────────────────────────────────────────────────────────────────
// @implementation MenuView
// ─────────────────────────────────────────────────────────────────────────────
@implementation MenuView {
    UIScrollView *_scroll;
    UIStackView  *_stack;
    NSArray      *_tabBtns;
    NSInteger     _curTab;
    CGPoint       _dragOff;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (!self) return nil;
    [self mc_build];
    return self;
}

- (void)mc_build {
    CGFloat W = self.bounds.size.width;
    CGFloat H = self.bounds.size.height;

    self.backgroundColor     = UIColor.clearColor;
    self.layer.shadowColor   = [UIColor colorWithRed:0.5f green:0.0f blue:1.0f alpha:0.4f].CGColor;
    self.layer.shadowOffset  = CGSizeMake(0, 6);
    self.layer.shadowRadius  = 16;
    self.layer.shadowOpacity = 1.0f;

    // Clip container
    UIView *clip = [[UIView alloc] initWithFrame:self.bounds];
    clip.backgroundColor     = MC_BG();
    clip.layer.cornerRadius  = 10;
    clip.layer.masksToBounds = YES;
    clip.autoresizingMask    = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addSubview:clip];

    // Title bar
    CGFloat tbH = 34;
    UIView *bar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, W, tbH)];
    bar.backgroundColor = MC_PNL();
    [clip addSubview:bar];

    UIView *topLine = [[UIView alloc] initWithFrame:CGRectMake(0, 0, W, 2)];
    topLine.backgroundColor = MC_ACC();
    [bar addSubview:topLine];

    UILabel *titleL = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, W - 44, tbH)];
    titleL.text      = @"extrahook";
    titleL.font      = [UIFont systemFontOfSize:12 weight:UIFontWeightSemibold];
    titleL.textColor = MC_TXT();
    [bar addSubview:titleL];

    UIButton *minBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    minBtn.frame              = CGRectMake(W - 30, 8, 20, 18);
    minBtn.backgroundColor    = [UIColor colorWithRed:0.28f green:0.28f blue:0.34f alpha:1.0f];
    minBtn.layer.cornerRadius = 4;
    [minBtn setTitle:@"—" forState:UIControlStateNormal];
    [minBtn setTitleColor:MC_TXT() forState:UIControlStateNormal];
    minBtn.titleLabel.font = [UIFont systemFontOfSize:11 weight:UIFontWeightBold];
    [minBtn addTarget:self action:@selector(mc_hide) forControlEvents:UIControlEventTouchUpInside];
    [bar addSubview:minBtn];

    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc]
        initWithTarget:self action:@selector(handlePan:)];
    [bar addGestureRecognizer:pan];

    // Sidebar
    CGFloat sw = 44;
    UIView *side = [[UIView alloc] initWithFrame:CGRectMake(0, tbH, sw, H - tbH)];
    side.backgroundColor = MC_PNL();
    [clip addSubview:side];

    UIView *sDiv = [[UIView alloc] initWithFrame:CGRectMake(sw, tbH, 0.5f, H - tbH)];
    sDiv.backgroundColor = MC_SEP();
    [clip addSubview:sDiv];

    NSArray *labels = @[@"ESP", @"AIM", @"MOVE", @"MISC", @"CFG"];
    NSMutableArray *btns = [NSMutableArray new];
    CGFloat tabH = (H - tbH) / (CGFloat)labels.count;

    for (NSInteger i = 0; i < (NSInteger)labels.count; i++) {
        MC_TabBtn *btn = [MC_TabBtn buttonWithType:UIButtonTypeCustom];
        btn.frame  = CGRectMake(0, tabH * i, sw, tabH);
        btn.tabIdx = i;
        btn.tag    = i;

        UILabel *nm = [UILabel new];
        nm.translatesAutoresizingMaskIntoConstraints = NO;
        nm.text          = labels[i];
        nm.font          = [UIFont systemFontOfSize:9 weight:UIFontWeightSemibold];
        nm.textColor     = MC_SUB();
        nm.textAlignment = NSTextAlignmentCenter;
        nm.tag           = 100;
        [btn addSubview:nm];
        [NSLayoutConstraint activateConstraints:@[
            [nm.centerXAnchor constraintEqualToAnchor:btn.centerXAnchor],
            [nm.centerYAnchor constraintEqualToAnchor:btn.centerYAnchor],
        ]];

        [btn addTarget:self action:@selector(mc_tabTap:) forControlEvents:UIControlEventTouchUpInside];
        [side addSubview:btn];
        [btns addObject:btn];
    }
    _tabBtns = [btns copy];

    // Content scroll
    _scroll = [[UIScrollView alloc] initWithFrame:CGRectMake(sw, tbH, W - sw, H - tbH)];
    _scroll.backgroundColor = UIColor.clearColor;
    _scroll.showsVerticalScrollIndicator = NO;
    [clip addSubview:_scroll];

    _stack = [[UIStackView alloc] initWithFrame:CGRectMake(0, 0, W - sw, 0)];
    _stack.axis    = UILayoutConstraintAxisVertical;
    _stack.spacing = 0;
    _stack.translatesAutoresizingMaskIntoConstraints = NO;
    [_scroll addSubview:_stack];

    [NSLayoutConstraint activateConstraints:@[
        [_stack.topAnchor      constraintEqualToAnchor:_scroll.topAnchor],
        [_stack.leadingAnchor  constraintEqualToAnchor:_scroll.leadingAnchor],
        [_stack.trailingAnchor constraintEqualToAnchor:_scroll.trailingAnchor],
        [_stack.bottomAnchor   constraintEqualToAnchor:_scroll.bottomAnchor],
        [_stack.widthAnchor    constraintEqualToAnchor:_scroll.widthAnchor],
    ]];

    _curTab = 0;
    [self mc_loadTab:0];
    [self mc_updateTabs];
}

// ── Visibility ─────────────────────────────────────────────────────────────────
- (void)mc_hide { self.hidden = YES; }

- (void)centerMenu {
    UIView *p = self.superview;
    if (!p) return;
    self.center = CGPointMake(p.bounds.size.width * 0.5f, p.bounds.size.height * 0.5f);
}

// ── Legacy stubs ───────────────────────────────────────────────────────────────
- (void)boxTapped  { esp_box_enabled  = !esp_box_enabled; }
- (void)lineTapped { esp_line_enabled = !esp_line_enabled; }

// ── Drag ───────────────────────────────────────────────────────────────────────
- (void)handlePan:(UIPanGestureRecognizer *)g {
    CGPoint pt = [g locationInView:self.superview];
    if (g.state == UIGestureRecognizerStateBegan) {
        _dragOff = CGPointMake(pt.x - self.frame.origin.x, pt.y - self.frame.origin.y);
    } else if (g.state == UIGestureRecognizerStateChanged) {
        CGRect f  = self.frame;
        CGRect sc = self.superview.bounds;
        f.origin.x = MAX(0, MIN(pt.x - _dragOff.x, sc.size.width  - f.size.width));
        f.origin.y = MAX(0, MIN(pt.y - _dragOff.y, sc.size.height - f.size.height));
        self.frame = f;
    }
}

// ── Tabs ───────────────────────────────────────────────────────────────────────
- (void)mc_tabTap:(MC_TabBtn *)btn {
    if (btn.tag == _curTab) return;
    _curTab = btn.tag;
    [self mc_loadTab:_curTab];
    [self mc_updateTabs];
    [_scroll setContentOffset:CGPointZero animated:NO];
}

- (void)mc_updateTabs {
    for (MC_TabBtn *b in _tabBtns) {
        BOOL sel = (b.tag == _curTab);
        UIView *bar = [b viewWithTag:200];
        if (!bar) {
            bar = [[UIView alloc] initWithFrame:CGRectMake(0, 5, 2, b.frame.size.height - 10)];
            bar.backgroundColor    = MC_ACC();
            bar.layer.cornerRadius = 1;
            bar.tag = 200;
            [b addSubview:bar];
        }
        bar.hidden        = !sel;
        b.backgroundColor = sel
            ? [UIColor colorWithRed:0.62f green:0.12f blue:0.95f alpha:0.12f]
            : UIColor.clearColor;
        UILabel *nm = (UILabel *)[b viewWithTag:100];
        if (nm) nm.textColor = sel ? MC_ACC2() : MC_SUB();
    }
}

- (void)mc_loadTab:(NSInteger)tab {
    for (UIView *v in _stack.arrangedSubviews) {
        [_stack removeArrangedSubview:v]; [v removeFromSuperview];
    }
    switch (tab) {
        case 0: [self mc_buildESP];      break;
        case 1: [self mc_buildAim];      break;
        case 2: [self mc_buildMove];     break;
        case 3: [self mc_buildMisc];     break;
        case 4: [self mc_buildCfg];      break;
    }
}

// ── Helpers ────────────────────────────────────────────────────────────────────
- (UIView *)mc_sep {
    UIView *v = [UIView new];
    v.translatesAutoresizingMaskIntoConstraints = NO;
    v.backgroundColor = MC_SEP();
    [v.heightAnchor constraintEqualToConstant:0.5f].active = YES;
    return v;
}
- (UIView *)mc_spc:(CGFloat)h {
    UIView *v = [UIView new];
    v.translatesAutoresizingMaskIntoConstraints = NO;
    [v.heightAnchor constraintEqualToConstant:h].active = YES;
    return v;
}
- (UIView *)mc_sec:(NSString *)t {
    UIView *v = [UIView new];
    v.translatesAutoresizingMaskIntoConstraints = NO;
    [v.heightAnchor constraintEqualToConstant:24].active = YES;

    UIView *line = [UIView new]; line.translatesAutoresizingMaskIntoConstraints = NO;
    line.backgroundColor = MC_ACC(); line.layer.cornerRadius = 1;
    [v addSubview:line];

    UILabel *l = [UILabel new]; l.translatesAutoresizingMaskIntoConstraints = NO;
    l.text = t; l.font = [UIFont systemFontOfSize:9 weight:UIFontWeightSemibold];
    l.textColor = MC_ACC2();
    [v addSubview:l];

    [NSLayoutConstraint activateConstraints:@[
        [line.leadingAnchor constraintEqualToAnchor:v.leadingAnchor constant:12],
        [line.centerYAnchor constraintEqualToAnchor:v.centerYAnchor],
        [line.widthAnchor   constraintEqualToConstant:2],
        [line.heightAnchor  constraintEqualToConstant:10],
        [l.leadingAnchor    constraintEqualToAnchor:line.trailingAnchor constant:6],
        [l.centerYAnchor    constraintEqualToAnchor:v.centerYAnchor],
    ]];
    return v;
}
- (MC_Row *)mc_row:(NSString *)t on:(BOOL)on cb:(void(^)(BOOL))cb {
    MC_Row *r = [[MC_Row alloc] initWithTitle:t on:on];
    r.onChange = cb;
    return r;
}
- (MC_Slider *)mc_sl:(NSString *)t mn:(float)mn mx:(float)mx v:(float)v fmt:(NSString *)fmt cb:(void(^)(float))cb {
    MC_Slider *s = [[MC_Slider alloc] initWithTitle:t min:mn max:mx val:v fmt:fmt];
    s.onChange = cb;
    return s;
}
- (void)mc_add:(UIView *)v { [_stack addArrangedSubview:v]; }

// ── ESP tab ───────────────────────────────────────────────────────────────────
- (void)mc_buildESP {
    [self mc_add:[self mc_spc:4]];
    [self mc_add:[self mc_sec:@"BOXES"]];
    [self mc_add:[self mc_row:@"Box ESP"        on:(BOOL)esp_box_enabled     cb:^(BOOL b){ esp_box_enabled     = b; }]];
    [self mc_add:[self mc_sep]];
    [self mc_add:[self mc_row:@"Box Outline"    on:(BOOL)esp_box_outline     cb:^(BOOL b){ esp_box_outline     = b; }]];
    [self mc_add:[self mc_sep]];
    [self mc_add:[self mc_row:@"Box Fill"       on:(BOOL)esp_box_fill        cb:^(BOOL b){ esp_box_fill        = b; }]];
    [self mc_add:[self mc_sep]];
    [self mc_add:[self mc_row:@"Corner Box"     on:(BOOL)esp_box_corner      cb:^(BOOL b){ esp_box_corner      = b; }]];
    [self mc_add:[self mc_sep]];
    [self mc_add:[self mc_row:@"3D Box"         on:(BOOL)esp_box_3d          cb:^(BOOL b){ esp_box_3d          = b; }]];
    [self mc_add:[self mc_sep]];
    [self mc_add:[self mc_row:@"Lines"          on:(BOOL)esp_line_enabled    cb:^(BOOL b){ esp_line_enabled    = b; }]];
    [self mc_add:[self mc_sep]];
    [self mc_add:[self mc_row:@"Line Outline"   on:(BOOL)esp_line_outline    cb:^(BOOL b){ esp_line_outline    = b; }]];
    [self mc_add:[self mc_spc:4]];
    [self mc_add:[self mc_sec:@"INFO"]];
    [self mc_add:[self mc_row:@"Names"          on:(BOOL)esp_name_enabled        cb:^(BOOL b){ esp_name_enabled        = b; }]];
    [self mc_add:[self mc_sep]];
    [self mc_add:[self mc_row:@"Name Outline"   on:(BOOL)esp_name_outline        cb:^(BOOL b){ esp_name_outline        = b; }]];
    [self mc_add:[self mc_sep]];
    [self mc_add:[self mc_row:@"Health"         on:(BOOL)esp_health_enabled      cb:^(BOOL b){ esp_health_enabled      = b; }]];
    [self mc_add:[self mc_sep]];
    [self mc_add:[self mc_row:@"Health Bar"     on:(BOOL)esp_health_bar_enabled  cb:^(BOOL b){ esp_health_bar_enabled  = b; }]];
    [self mc_add:[self mc_sep]];
    [self mc_add:[self mc_row:@"Weapon"         on:(BOOL)esp_weapon_enabled      cb:^(BOOL b){ esp_weapon_enabled      = b; }]];
    [self mc_add:[self mc_sep]];
    [self mc_add:[self mc_row:@"Weapon Icon"    on:(BOOL)esp_weapon_icon_enabled cb:^(BOOL b){ esp_weapon_icon_enabled = b; }]];
    [self mc_add:[self mc_sep]];
    [self mc_add:[self mc_row:@"Platform"       on:(BOOL)esp_platform_enabled    cb:^(BOOL b){ esp_platform_enabled    = b; }]];
    [self mc_add:[self mc_sep]];
    [self mc_add:[self mc_row:@"Avatar"         on:(BOOL)esp_avatar_enabled      cb:^(BOOL b){ esp_avatar_enabled      = b; }]];
    [self mc_add:[self mc_sep]];
    [self mc_add:[self mc_row:@"Team Check"     on:(BOOL)esp_team_check          cb:^(BOOL b){ esp_team_check          = b; }]];
    [self mc_add:[self mc_spc:10]];
}

// ── AIM tab ───────────────────────────────────────────────────────────────────
- (void)mc_buildAim {
    [self mc_add:[self mc_spc:4]];
    [self mc_add:[self mc_sec:@"AIMBOT"]];
    [self mc_add:[self mc_row:@"Enabled"       on:(BOOL)aimbot_enabled        cb:^(BOOL b){ aimbot_enabled        = b; }]];
    [self mc_add:[self mc_sep]];
    [self mc_add:[self mc_row:@"Visible Check" on:(BOOL)aimbot_visible_check  cb:^(BOOL b){ aimbot_visible_check  = b; }]];
    [self mc_add:[self mc_sep]];
    [self mc_add:[self mc_row:@"Shoot Check"   on:(BOOL)aimbot_shooting_check cb:^(BOOL b){ aimbot_shooting_check = b; }]];
    [self mc_add:[self mc_sep]];
    [self mc_add:[self mc_row:@"Knife Bot"     on:(BOOL)aimbot_knife_bot      cb:^(BOOL b){ aimbot_knife_bot      = b; }]];
    [self mc_add:[self mc_sep]];
    [self mc_add:[self mc_row:@"FOV Check"     on:(BOOL)aimbot_fov_visible    cb:^(BOOL b){ aimbot_fov_visible    = b; }]];
    [self mc_add:[self mc_sep]];
    [self mc_add:[self mc_row:@"Team Check"    on:(BOOL)aimbot_team_check     cb:^(BOOL b){ aimbot_team_check     = b; }]];
    [self mc_add:[self mc_spc:2]];
    [self mc_add:[self mc_sl:@"FOV"    mn:0 mx:180 v:aimbot_fov           fmt:@"%.0f°"  cb:^(float f){ aimbot_fov           = f; }]];
    [self mc_add:[self mc_sl:@"Smooth" mn:0 mx:20  v:aimbot_smooth        fmt:@"%.1f"   cb:^(float f){ aimbot_smooth        = f; }]];
    [self mc_add:[self mc_spc:4]];
    [self mc_add:[self mc_sec:@"TRIGGERBOT"]];
    [self mc_add:[self mc_row:@"Triggerbot"    on:(BOOL)aimbot_triggerbot     cb:^(BOOL b){ aimbot_triggerbot     = b; }]];
    [self mc_add:[self mc_sep]];
    [self mc_add:[self mc_sl:@"Delay" mn:0 mx:500 v:aimbot_trigger_delay fmt:@"%.0fms" cb:^(float f){ aimbot_trigger_delay = f; }]];
    [self mc_add:[self mc_spc:4]];
    [self mc_add:[self mc_sec:@"ANTI-RECOIL"]];
    [self mc_add:[self mc_row:@"RCS"      on:(BOOL)esp_rcs_enabled cb:^(BOOL b){ esp_rcs_enabled = b; }]];
    [self mc_add:[self mc_sep]];
    [self mc_add:[self mc_sl:@"RCS H" mn:0 mx:2 v:esp_rcs_h fmt:@"%.2f" cb:^(float f){ esp_rcs_h = f; }]];
    [self mc_add:[self mc_sl:@"RCS V" mn:0 mx:2 v:esp_rcs_v fmt:@"%.2f" cb:^(float f){ esp_rcs_v = f; }]];
    [self mc_add:[self mc_spc:10]];
}

// ── MOVE tab ──────────────────────────────────────────────────────────────────
- (void)mc_buildMove {
    [self mc_add:[self mc_spc:4]];
    [self mc_add:[self mc_sec:@"MOVEMENT"]];
    [self mc_add:[self mc_row:@"Bunny Hop"  on:(BOOL)esp_bunny_hop  cb:^(BOOL b){ esp_bunny_hop  = b; }]];
    [self mc_add:[self mc_sep]];
    [self mc_add:[self mc_row:@"Air Jump"   on:(BOOL)esp_air_jump   cb:^(BOOL b){ esp_air_jump   = b; }]];
    [self mc_add:[self mc_sep]];
    [self mc_add:[self mc_row:@"Fast Knife" on:(BOOL)esp_fast_knife cb:^(BOOL b){ esp_fast_knife = b; }]];
    [self mc_add:[self mc_spc:4]];
    [self mc_add:[self mc_sec:@"VIEWMODEL"]];
    [self mc_add:[self mc_row:@"Custom VM" on:(BOOL)viewmodel_enabled cb:^(BOOL b){ viewmodel_enabled = b; }]];
    [self mc_add:[self mc_sep]];
    [self mc_add:[self mc_sl:@"X" mn:-10 mx:10 v:viewmodel_x fmt:@"%.1f" cb:^(float f){ viewmodel_x = f; }]];
    [self mc_add:[self mc_sl:@"Y" mn:-10 mx:10 v:viewmodel_y fmt:@"%.1f" cb:^(float f){ viewmodel_y = f; }]];
    [self mc_add:[self mc_sl:@"Z" mn:-10 mx:10 v:viewmodel_z fmt:@"%.1f" cb:^(float f){ viewmodel_z = f; }]];
    [self mc_add:[self mc_spc:10]];
}

// ── MISC tab ──────────────────────────────────────────────────────────────────
- (void)mc_buildMisc {
    [self mc_add:[self mc_spc:4]];
    [self mc_add:[self mc_sec:@"PLAYER"]];
    [self mc_add:[self mc_row:@"Invisible"      on:(BOOL)esp_invisible cb:^(BOOL b){ esp_invisible = b; }]];
    [self mc_add:[self mc_sep]];
    [self mc_add:[self mc_row:@"Add Score"      on:(BOOL)esp_addscore  cb:^(BOOL b){ esp_addscore  = b; }]];
    [self mc_add:[self mc_spc:4]];
    [self mc_add:[self mc_sec:@"WEAPON"]];
    [self mc_add:[self mc_row:@"Infinite Ammo"  on:(BOOL)esp_inf_ammo  cb:^(BOOL b){ esp_inf_ammo  = b; }]];
    [self mc_add:[self mc_sep]];
    [self mc_add:[self mc_row:@"No Spread"      on:(BOOL)esp_no_spread cb:^(BOOL b){ esp_no_spread = b; }]];
    [self mc_add:[self mc_sep]];
    [self mc_add:[self mc_row:@"Wallshot"       on:(BOOL)esp_wallshot  cb:^(BOOL b){ esp_wallshot  = b; }]];
    [self mc_add:[self mc_sep]];
    [self mc_add:[self mc_row:@"Fast Fire Rate" on:(BOOL)esp_fire_rate cb:^(BOOL b){ esp_fire_rate = b; }]];
    [self mc_add:[self mc_spc:10]];
}

// ── CFG tab ───────────────────────────────────────────────────────────────────
- (void)mc_buildCfg {
    [self mc_add:[self mc_spc:4]];
    [self mc_add:[self mc_sec:@"OPTIONS"]];
    [self mc_add:[self mc_row:@"Auto Load"       on:(BOOL)esp_auto_load       cb:^(BOOL b){ esp_auto_load       = b; }]];
    [self mc_add:[self mc_sep]];
    [self mc_add:[self mc_row:@"Screenshot Safe" on:(BOOL)esp_screenshot_safe cb:^(BOOL b){ esp_screenshot_safe = b; }]];
    [self mc_add:[self mc_spc:10]];
}

@end

// ─────────────────────────────────────────────────────────────────────────────

@implementation ESP_View

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (!self) return nil;

    self.backgroundColor        = [UIColor clearColor];
    self.hasAttemptedLaunch     = NO;
    self.isESPCountEnabled      = NO;
    self.userInteractionEnabled = YES;

    self.espBoxFillLayer = [CAShapeLayer layer];
    self.espBoxFillLayer.fillColor = [UIColor colorWithWhite:1 alpha:0.3].CGColor;
    self.espBoxFillLayer.strokeColor = [UIColor clearColor].CGColor;
    [self.layer addSublayer:self.espBoxFillLayer];

    self.espBoxOutlineLayer = [CAShapeLayer layer];
    self.espBoxOutlineLayer.strokeColor = [UIColor blackColor].CGColor;
    self.espBoxOutlineLayer.fillColor   = [UIColor clearColor].CGColor;
    self.espBoxOutlineLayer.lineWidth   = 3.0;
    [self.layer addSublayer:self.espBoxOutlineLayer];

    self.espBoxLayer = [CAShapeLayer layer];
    self.espBoxLayer.strokeColor = [UIColor colorWithRed:0.0 green:0.9 blue:0.3 alpha:1.0].CGColor;
    self.espBoxLayer.fillColor   = [UIColor clearColor].CGColor;
    self.espBoxLayer.lineWidth   = 1.5;
    [self.layer addSublayer:self.espBoxLayer];

    self.espHealthBarOutlineLayer = [CAShapeLayer layer];
    self.espHealthBarOutlineLayer.strokeColor = [UIColor blackColor].CGColor;
    self.espHealthBarOutlineLayer.fillColor   = [UIColor clearColor].CGColor;
    self.espHealthBarOutlineLayer.lineWidth   = 3.0;
    [self.layer addSublayer:self.espHealthBarOutlineLayer];

    self.espHealthBarLayer = [CAShapeLayer layer];
    self.espHealthBarLayer.strokeColor = [UIColor colorWithRed:0.0 green:1.0 blue:0.0 alpha:0.8].CGColor;
    self.espHealthBarLayer.fillColor   = [UIColor clearColor].CGColor;
    self.espHealthBarLayer.lineWidth   = 2.0;
    [self.layer addSublayer:self.espHealthBarLayer];

    self.espLineOutlineLayer = [CAShapeLayer layer];
    self.espLineOutlineLayer.strokeColor = [UIColor blackColor].CGColor;
    self.espLineOutlineLayer.fillColor   = [UIColor clearColor].CGColor;
    self.espLineOutlineLayer.lineWidth   = 3.0;
    [self.layer addSublayer:self.espLineOutlineLayer];

    self.espLineLayer = [CAShapeLayer layer];
    self.espLineLayer.strokeColor = [UIColor colorWithRed:0.0 green:0.9 blue:0.3 alpha:1.0].CGColor;
    self.espLineLayer.fillColor   = [UIColor clearColor].CGColor;
    self.espLineLayer.lineWidth   = 1.0;
    [self.layer addSublayer:self.espLineLayer];

    self.fovCircleOutlineLayer = [CAShapeLayer layer];
    self.fovCircleOutlineLayer.fillColor   = [UIColor clearColor].CGColor;
    self.fovCircleOutlineLayer.strokeColor = [UIColor colorWithWhite:0 alpha:0.6].CGColor;
    self.fovCircleOutlineLayer.lineWidth   = 3.0;
    self.fovCircleOutlineLayer.hidden      = YES;
    [self.layer addSublayer:self.fovCircleOutlineLayer];

    self.fovCircleLayer = [CAShapeLayer layer];
    self.fovCircleLayer.fillColor   = [UIColor clearColor].CGColor;
    self.fovCircleLayer.strokeColor = [UIColor colorWithRed:0.0 green:0.9 blue:0.3 alpha:1.0].CGColor;
    self.fovCircleLayer.lineWidth   = 1.5;
    self.fovCircleLayer.hidden      = YES;
    [self.layer addSublayer:self.fovCircleLayer];

    UILabel *wm = [[UILabel alloc] init];
    wm.text = @(OBF("extrahook"));
    wm.textColor = [UIColor whiteColor];
    wm.font = [UIFont boldSystemFontOfSize:16.0f];
    wm.userInteractionEnabled = NO;
    [self addSubview:wm];
    self.watermarkLabel = wm;

    UILabel *playerCountLabel = [UILabel new];
    playerCountLabel.hidden = YES;
    self.playerCountLabel = playerCountLabel;

    UILabel *noPlayersLabel = [UILabel new];
    noPlayersLabel.hidden = YES;
    self.noPlayersLabel = noPlayersLabel;

    self.nameLabelPool = [NSMutableArray new];
    self.healthLabelPool = [NSMutableArray new];
    self.weaponLabelPool = [NSMutableArray new];
    self.weaponIconPool = [NSMutableArray new];
    self.platformLabelPool = [NSMutableArray new];
    self.avatarPool = [NSMutableArray new];
    self.aimbotCurrentTarget = 0;
    self.aimbotLastWriteTime = 0;
    self.triggerbotShooting = NO;
    self.triggerbotLastShotTime = 0;

    // In-game menu overlay (tap watermark label to show/hide)
    {
        CGRect  sc  = UIScreen.mainScreen.bounds;
        CGFloat mw  = 300, mh = 360;
        CGFloat mx  = (sc.size.width - mw) * 0.5f;
        self.menuView = [[MenuView alloc] initWithFrame:CGRectMake(mx, 60, mw, mh)];
        [self addSubview:self.menuView];
    }
    self.watermarkLabel.userInteractionEnabled = YES;
    UITapGestureRecognizer *wmTap = [[UITapGestureRecognizer alloc]
        initWithTarget:self action:@selector(toggleMenu)];
    [self.watermarkLabel addGestureRecognizer:wmTap];

    [[NSNotificationCenter defaultCenter]
        addObserver:self
           selector:@selector(clearAllBoxes)
               name:@"ESPClearBoxes"
             object:nil];

    [self startBackgroundKeeper];

    self.displayLinkData = [CADisplayLink displayLinkWithTarget:self selector:@selector(update_data)];
    self.displayLinkData.preferredFramesPerSecond = 120;
    [self.displayLinkData addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    [self showViewForCapture];

    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    if (self.superview) self.frame = self.superview.bounds;
    CGSize s = [self.watermarkLabel sizeThatFits:CGSizeMake(300, 30)];
    self.watermarkLabel.frame = CGRectMake(10, 8, s.width + 4, s.height);
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    for (UIView *sub in self.subviews.reverseObjectEnumerator) {
        if (sub.isHidden || !sub.userInteractionEnabled || sub.alpha < 0.01f) continue;
        CGPoint p = [self convertPoint:point toView:sub];
        if ([sub pointInside:p withEvent:event]) {
            UIView *hit = [sub hitTest:p withEvent:event];
            if (hit) return hit;
        }
    }
    return nil;
}

- (void)toggleMenu {
    if (self.menuView) self.menuView.hidden = !self.menuView.isHidden;
}



- (void)dealloc {
    [self.displayLinkData invalidate];
    self.displayLinkData = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)clearAllBoxes {
    self.espBoxLayer.path        = nil;
    self.espBoxFillLayer.path    = nil;
    self.espLineLayer.path       = nil;
    self.espBoxOutlineLayer.path = nil;
    self.espLineOutlineLayer.path = nil;
    self.espHealthBarLayer.path  = nil;
    self.espHealthBarOutlineLayer.path = nil;
    self.fovCircleLayer.hidden        = YES;
    self.fovCircleOutlineLayer.hidden = YES;
    for (UILabel *lbl in self.nameLabelPool) lbl.hidden = YES;
    for (UILabel *lbl in self.healthLabelPool) lbl.hidden = YES;
    for (UILabel *lbl in self.weaponLabelPool) lbl.hidden = YES;
    for (UIImageView *img in self.weaponIconPool) img.hidden = YES;
    for (UILabel *lbl in self.platformLabelPool) lbl.hidden = YES;
    for (UIImageView *img in self.avatarPool) img.hidden = YES;
}

- (void)update_data {
    if (!esp_box_enabled && !esp_box_3d && !esp_box_corner && !esp_line_enabled && !esp_name_enabled && !esp_health_enabled && !esp_health_bar_enabled && !esp_weapon_enabled) {
        [self clearAllBoxes];
        self.watermarkLabel.text = @(OBF("extrahook"));
        [self.watermarkLabel sizeToFit];
        return;
    }

    static pid_t cached_so2_pid = 0;
    static task_t cached_so2_task = 0;
    static mach_vm_address_t cached_unity_base = 0;

    pid_t so2_pid = get_pid_by_name("Standoff2");

    if (so2_pid <= 0) {
        cached_so2_pid = 0;
        cached_so2_task = 0;
        cached_unity_base = 0;

        [self clearAllBoxes];

        self.playerCountLabel.text      = @(OBF("LAUNCHING..."));
        self.playerCountLabel.textColor = [UIColor redColor];
        self.noPlayersLabel.hidden      = YES;
        self.watermarkLabel.text = @(OBF("extrahook"));
        [self.watermarkLabel sizeToFit];

        if (!self.hasAttemptedLaunch) {
            [self launchGame];
            self.hasAttemptedLaunch = YES;
        }
        return;
    }

    if (so2_pid != cached_so2_pid || !cached_so2_task || !cached_unity_base) {
        cached_so2_task = get_task_by_pid(so2_pid);
        if (cached_so2_task) {
            cached_unity_base = get_image_base_address(cached_so2_task, "UnityFramework");
        }
        cached_so2_pid = so2_pid;
    }

    task_t so2_task = cached_so2_task;
    if (!so2_task) goto CLEAR_BOXES;

    {
        mach_vm_address_t unity_base = cached_unity_base;
        if (!unity_base) goto CLEAR_BOXES;

        mach_vm_address_t typeInfo       = 0, staticFields  = 0;
        mach_vm_address_t playerManager  = 0, playersDict   = 0;
        mach_vm_address_t parentTypeInfo = 0;
        mach_vm_address_t dict28         = 0;
        int playersCount = 0, c18 = 0, c20 = 0, c40 = 0;

        // ── TypeInfo: try cached offset, then scan ±2MB for current game version ──
        {
            static mach_vm_address_t s_ti_offset = 164201496; // known offset

            auto validateChain = [&](mach_vm_address_t ti) -> bool {
                if (ti < 0x1000000) return false;
                mach_vm_address_t pti = Read<mach_vm_address_t>(ti + 0x58, so2_task);
                if (pti < 0x1000000) return false;
                mach_vm_address_t sf = Read<mach_vm_address_t>(pti + 0xB8, so2_task);
                if (!sf || sf < 0x1000000) sf = Read<mach_vm_address_t>(pti + 0xB0, so2_task);
                if (!sf || sf < 0x1000000) return false;
                mach_vm_address_t pm = Read<mach_vm_address_t>(sf + 0x0, so2_task);
                if (pm < 0x1000000) return false;
                return true;
            };

            // 1. Try cached offset first (fast path)
            typeInfo = Read<mach_vm_address_t>(unity_base + s_ti_offset, so2_task);
            if (!validateChain(typeInfo)) {
                typeInfo = 0;
                // 2. Bulk-scan ±2MB around cached offset
                const mach_vm_size_t RANGE  = 2 * 1024 * 1024;
                const mach_vm_size_t CHUNK  = 65536;
                mach_vm_address_t scan_base = (unity_base + s_ti_offset > RANGE)
                                              ? unity_base + s_ti_offset - RANGE
                                              : unity_base;
                mach_vm_size_t scan_size = RANGE * 2;
                uint8_t *buf = (uint8_t*)malloc(CHUNK);
                if (buf) {
                    for (mach_vm_size_t off = 0; off < scan_size && !typeInfo; off += CHUNK) {
                        mach_vm_size_t chunk = (off + CHUNK > scan_size) ? (scan_size - off) : CHUNK;
                        mach_vm_size_t outs  = 0;
                        if (mach_vm_read_overwrite(so2_task, scan_base + off, chunk,
                                                   (mach_vm_address_t)buf, &outs) != KERN_SUCCESS) continue;
                        for (mach_vm_size_t i = 0; i + 8 <= outs; i += 8) {
                            mach_vm_address_t cand = *(mach_vm_address_t*)(buf + i);
                            if (cand < 0x100000000ULL || cand > 0x300000000000ULL) continue;
                            if (validateChain(cand)) {
                                s_ti_offset = (scan_base + off + i) - unity_base;
                                typeInfo    = cand;
                                break;
                            }
                        }
                    }
                    free(buf);
                }
            }
        }
        if (!typeInfo || typeInfo < 0x1000000) goto CLEAR_BOXES;

        parentTypeInfo = Read<mach_vm_address_t>(typeInfo + 0x58, so2_task);
        if (!parentTypeInfo || parentTypeInfo < 0x1000000) goto CLEAR_BOXES;

        staticFields = Read<mach_vm_address_t>(parentTypeInfo + 0xB8, so2_task);
        if (!staticFields || staticFields < 0x1000000)
            staticFields = Read<mach_vm_address_t>(parentTypeInfo + 0xB0, so2_task);
        if (!staticFields || staticFields < 0x1000000) goto CLEAR_BOXES;

        playerManager = Read<mach_vm_address_t>(staticFields + 0x0, so2_task);
        if (!playerManager || playerManager < 0x1000000) goto CLEAR_BOXES;

        {
            static const int kDictOffsets[] = {0x18, 0x20, 0x28, 0x30};
            for (int _di = 0; _di < 4; _di++) {
                mach_vm_address_t cand = Read<mach_vm_address_t>(playerManager + kDictOffsets[_di], so2_task);
                if (cand < 0x1000000) continue;
                c20 = Read<int>(cand + 0x20, so2_task);
                c40 = Read<int>(cand + 0x40, so2_task);
                c18 = Read<int>(cand + 0x18, so2_task);
                if      (c20 > 0 && c20 <= 32) { dict28 = cand; playersCount = c20; break; }
                else if (c40 > 0 && c40 <= 32) { dict28 = cand; playersCount = c40; break; }
                else if (c18 > 0 && c18 <= 32) { dict28 = cand; playersCount = c18; break; }
            }
        }
        playersDict = dict28;

        if (playersCount > 0 && playersCount <= 32) {
            mach_vm_address_t localPlayer = Read<mach_vm_address_t>(playerManager + 0x10, so2_task);
            if (localPlayer < 0x1000000 || Read<mach_vm_address_t>(localPlayer + 0xE0, so2_task) == 0) {
                localPlayer = Read<mach_vm_address_t>(playerManager + 0x70, so2_task);
                if (localPlayer < 0x1000000 || Read<mach_vm_address_t>(localPlayer + 0xE0, so2_task) == 0)
                    localPlayer = Read<mach_vm_address_t>(playerManager + 0x68, so2_task);
            }

            if (esp_invisible && localPlayer > 0x1000000) {
                mach_vm_address_t weaponryController = Read<mach_vm_address_t>(localPlayer + 0x88, so2_task);
                if (weaponryController > 0x1000000)
                    Write<uint8_t>(weaponryController + 0x88, 10, so2_task);
            }

            if (esp_addscore && localPlayer > 0x1000000) {
                mach_vm_address_t photonPlayer = Read<mach_vm_address_t>(localPlayer + 0x160, so2_task);
                if (photonPlayer > 0x1000000) {
                    mach_vm_address_t props = Read<mach_vm_address_t>(photonPlayer + 0x38, so2_task);
                    if (props > 0x1000000) {
                        int size = Read<int>(props + 0x20, so2_task);
                        mach_vm_address_t entries = Read<mach_vm_address_t>(props + 0x18, so2_task);
                        if (entries > 0x1000000 && size > 0 && size <= 64) {
                            for (int i = 0; i < size; i++) {
                                mach_vm_address_t propkey = Read<mach_vm_address_t>(entries + 0x20 + 0x18 * i + 0x8, so2_task);
                                mach_vm_address_t propval = Read<mach_vm_address_t>(entries + 0x20 + 0x18 * i + 0x10, so2_task);
                                if (!propkey || !propval) continue;
                                int strLen = Read<int>(propkey + 0x10, so2_task);
                                if (strLen == 5) {
                                    uint64_t part1 = Read<uint64_t>(propkey + 0x14, so2_task);
                                    if (part1 == 0x0072006F00630073ULL) { // "scor"
                                        uint16_t part2 = Read<uint16_t>(propkey + 0x1C, so2_task);
                                        if (part2 == 0x0065) { // "e"
                                            Write<int>(propval + 0x10, 333, so2_task);
                                            break;
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            if (esp_rcs_enabled && localPlayer > 0x1000000) {
                mach_vm_address_t wc = Read<mach_vm_address_t>(localPlayer + 0x88, so2_task);
                if (wc > 0x1000000) {
                    mach_vm_address_t ctrl = Read<mach_vm_address_t>(wc + 0xA0, so2_task);
                    if (ctrl > 0x1000000) {
                        mach_vm_address_t gun = Read<mach_vm_address_t>(ctrl + 0x168, so2_task);
                        if (gun > 0x1000000) {
                            mach_vm_address_t rcp = Read<mach_vm_address_t>(gun + 0x158, so2_task);
                            if (rcp > 0x1000000) {
                                float rcs_h_val = esp_rcs_h;
                                float rcs_v_val = esp_rcs_v;

                                Write<float>(rcp + 0x10, rcs_h_val, so2_task);
                                Write<float>(rcp + 0x14, rcs_v_val, so2_task);

                                bool hasHValue = Read<bool>(rcp + 0x70, so2_task);
                                if (hasHValue) {
                                    int key_h = Read<int>(rcp + 0x74, so2_task);
                                    int valueAsInt_h = *reinterpret_cast<int*>(&rcs_h_val);
                                    int encoded_h = key_h ^ valueAsInt_h;
                                    Write<int>(rcp + 0x78, encoded_h, so2_task);
                                }
                                
                                bool hasVValue = Read<bool>(rcp + 0x64, so2_task);
                                if (hasVValue) {
                                    int key_v = Read<int>(rcp + 0x68, so2_task);
                                    int valueAsInt_v = *reinterpret_cast<int*>(&rcs_v_val);
                                    int encoded_v = key_v ^ valueAsInt_v;
                                    Write<int>(rcp + 0x6C, encoded_v, so2_task);
                                }
                            }
                        }
                    }
                }
            }

            if (esp_inf_ammo && localPlayer > 0x1000000) {
                mach_vm_address_t wc = Read<mach_vm_address_t>(localPlayer + 0x88, so2_task);
                if (wc > 0x1000000) {
                    mach_vm_address_t ctrl = Read<mach_vm_address_t>(wc + 0xA0, so2_task);
                    if (ctrl > 0x1000000) {
                        Write<int32_t>(ctrl + 0x120, 0,   so2_task);
                        Write<int32_t>(ctrl + 0x124, 999, so2_task);
                        Write<int32_t>(ctrl + 0x128, 0,   so2_task);
                        Write<int32_t>(ctrl + 0x12C, 999, so2_task);
                    }
                }
            }

            if (esp_no_spread && localPlayer > 0x1000000) {
                mach_vm_address_t wc = Read<mach_vm_address_t>(localPlayer + 0x88, so2_task);
                if (wc > 0x1000000) {
                    mach_vm_address_t ctrl = Read<mach_vm_address_t>(wc + 0xA0, so2_task);
                    if (ctrl > 0x1000000) {
                        mach_vm_address_t accData = Read<mach_vm_address_t>(ctrl + 0x228, so2_task);
                        if (accData > 0x1000000) {
                            Write<float>(accData + 0x10, 0.0f, so2_task);
                            Write<float>(accData + 0x14, 0.0f, so2_task);
                        }
                        // Current spread
                        Write<int32_t>(ctrl + 0x1F4, 0, so2_task);
                        Write<int32_t>(ctrl + 0x1F8, 0, so2_task);
                        Write<int32_t>(ctrl + 0x1FC, 0, so2_task);
                        Write<int32_t>(ctrl + 0x200, 0, so2_task);
                    }
                }
            }

            if (esp_air_jump && localPlayer > 0x1000000) {
                mach_vm_address_t character = Read<mach_vm_address_t>(localPlayer + 0x118, so2_task);
                if (character > 0x1000000) {
                    mach_vm_address_t ptr = Read<mach_vm_address_t>(character + 0x10, so2_task);
                    if (ptr > 0x1000000)
                        Write<uint8_t>(ptr + 0xCC, 4, so2_task);
                }
            }

            if (esp_fast_knife && localPlayer > 0x1000000) {
                mach_vm_address_t wc = Read<mach_vm_address_t>(localPlayer + 0x88, so2_task);
                if (wc > 0x1000000) {
                    mach_vm_address_t ctrl = Read<mach_vm_address_t>(wc + 0xA0, so2_task);
                    if (ctrl > 0x1000000) {
                        mach_vm_address_t wp = Read<mach_vm_address_t>(ctrl + 0xA8, so2_task);
                        if (wp > 0x1000000) {
                            uint8_t weaponId = Read<uint8_t>(wp + 0x18, so2_task);
                            if (weaponId >= 70 && weaponId < 90) {
                                mach_vm_address_t knifeParams = Read<mach_vm_address_t>(ctrl + 0x18, so2_task);
                                if (knifeParams > 0x1000000) {
                                    Write<float>(knifeParams + 0x110, 0.01f, so2_task);
                                }
                                // Nullable<SafeFloat> in KnifeController
                                bool hasVal = Read<bool>(ctrl + 0x100, so2_task);
                                if (hasVal) {
                                    int key = Read<int>(ctrl + 0x104, so2_task);
                                    float val = 0.01f;
                                    int valInt = *reinterpret_cast<int*>(&val);
                                    Write<int>(ctrl + 0x108, key ^ valInt, so2_task);
                                }
                            }
                        }
                    }
                }
            }

            if (esp_bunny_hop && localPlayer > 0x1000000) {
                mach_vm_address_t mv = Read<mach_vm_address_t>(localPlayer + 0x98, so2_task);
                if (mv > 0x1000000) {
                    mach_vm_address_t tp = Read<mach_vm_address_t>(mv + 0xA8, so2_task);
                    if (tp > 0x1000000) {
                        mach_vm_address_t jp = Read<mach_vm_address_t>(tp + 0x50, so2_task);
                        if (jp > 0x1000000) {
                            Write<float>(jp + 0x10, (float)esp_bhop_setting, so2_task);
                            Write<float>(jp + 0x60, (float)esp_bhop_setting, so2_task);
                        }
                    }
                    mach_vm_address_t td = Read<mach_vm_address_t>(mv + 0xB0, so2_task);
                    if (td > 0x1000000) {
                        Vector3 zero = {0,0,0};
                        Write<Vector3>(td + 0x68, zero, so2_task);
                    }
                }
            }

            if (esp_wallshot && localPlayer > 0x1000000) {
                mach_vm_address_t wc = Read<mach_vm_address_t>(localPlayer + 0x88, so2_task);
                if (wc > 0x1000000) {
                    mach_vm_address_t ctrl = Read<mach_vm_address_t>(wc + 0xA0, so2_task);
                    if (ctrl > 0x1000000) {
                        mach_vm_address_t gp = Read<mach_vm_address_t>(ctrl + 0xA8, so2_task);
                        if (gp > 0x1000000) {
                            Write<float>(gp + 0x148, 99999.0f, so2_task);
                            Write<float>(gp + 0x1A0, 1.0f,     so2_task);
                            Write<int32_t>(gp + 0x1A4, 9999,   so2_task);
                            Write<int32_t>(gp + 0x258, 1,      so2_task);
                            Write<float>(gp + 0x268, 1.0f,     so2_task);
                            Write<int32_t>(gp + 0x264, 1,      so2_task);
                            Write<int32_t>(gp + 0x274, 9999,   so2_task);
                            Write<int32_t>(gp + 0x2DC, 1,      so2_task);
                            Write<float>(gp + 0x2EC, 99999.0f, so2_task);
                        }
                    }
                }
            }

            if (esp_fire_rate && localPlayer > 0x1000000) {
                mach_vm_address_t wc = Read<mach_vm_address_t>(localPlayer + 0x88, so2_task);
                if (wc > 0x1000000) {
                    mach_vm_address_t ctrl = Read<mach_vm_address_t>(wc + 0xA0, so2_task);
                    if (ctrl > 0x1000000) {
                        Write<int32_t>(ctrl + 0x108, 0, so2_task);
                        Write<int32_t>(ctrl + 0x10C, 0, so2_task);
                    }
                }
            }

            SO2_Matrix viewMatrix = {0};
            if (localPlayer > 0x1000000) {
                mach_vm_address_t v1 = Read<mach_vm_address_t>(localPlayer + 0xE8, so2_task);
                if (v1 > 0x1000000) {
                    mach_vm_address_t v2 = Read<mach_vm_address_t>(v1 + 0x20, so2_task);
                    if (v2 > 0x1000000) {
                        mach_vm_address_t v3 = Read<mach_vm_address_t>(v2 + 0x10, so2_task);
                        if (v3 > 0x1000000) {
                            viewMatrix = Read<SO2_Matrix>(v3 + 0x100, so2_task);
                        }
                    }
                }
            }

            {
                int localTeamAim = GetPlayerTeamAim(localPlayer, so2_task);
                CGFloat w2 = self.bounds.size.width;
                CGFloat h2 = self.bounds.size.height;
                [self runAimbot:localPlayer
                        players:playersDict
                          count:playersCount
                      localTeam:localTeamAim
                           task:so2_task
                          width:w2
                         height:h2
                     viewMatrix:viewMatrix];
            }

            mach_vm_address_t entries_arr = Read<mach_vm_address_t>(playersDict + 0x18, so2_task);
            int capacity = Read<int>(entries_arr + 0x18, so2_task);
            if (capacity > 100) capacity = 100;

            BOOL drawBoxes = esp_box_enabled || esp_box_3d || esp_box_fill || esp_box_corner;
            BOOL drawLines = esp_line_enabled;

            if (!drawBoxes && !drawLines && !esp_name_enabled && !esp_health_enabled && !esp_health_bar_enabled && !esp_weapon_enabled && !esp_weapon_icon_enabled && !esp_platform_enabled) {
                [self clearAllBoxes];
                self.watermarkLabel.text = @"extrahook";
                [self.watermarkLabel sizeToFit];
                return;
            }

            int validPlayers = 0;
            CGFloat w = self.bounds.size.width;
            CGFloat h = self.bounds.size.height;


            for (UILabel *lbl in self.nameLabelPool) lbl.hidden = YES;
            NSUInteger nameLabelIdx = 0;
            for (UILabel *lbl in self.healthLabelPool) lbl.hidden = YES;
            NSUInteger hpLabelIdx = 0;
            for (UILabel *lbl in self.weaponLabelPool) lbl.hidden = YES;
            NSUInteger weaponLabelIdx = 0;
            for (UIImageView *img in self.weaponIconPool) img.hidden = YES;
            NSUInteger weaponIconIdx = 0;
            for (UILabel *lbl in self.platformLabelPool) lbl.hidden = YES;
            NSUInteger platformLabelIdx = 0;
            for (UIImageView *img in self.avatarPool) img.hidden = YES;
            NSUInteger avatarIdx = 0;

            UIBezierPath *boxPath         = [UIBezierPath bezierPath];
            UIBezierPath *boxFillPath     = [UIBezierPath bezierPath];
            UIBezierPath *boxOutlinePath  = [UIBezierPath bezierPath];
            UIBezierPath *linesPath       = [UIBezierPath bezierPath];
            UIBezierPath *lineOutlinePath = [UIBezierPath bezierPath];
            UIBezierPath *healthBarPath   = [UIBezierPath bezierPath];
            UIBezierPath *healthBarOutlinePath = [UIBezierPath bezierPath];

            int localTeam = 0;
            if (esp_team_check) {
                mach_vm_address_t localPhoton = Read<mach_vm_address_t>(localPlayer + 0x160, so2_task);
                mach_vm_address_t localProps  = Read<mach_vm_address_t>(localPhoton + 0x38, so2_task);
                if (localProps > 0x1000000) {
                    int propsSize = Read<int>(localProps + 0x20, so2_task);
                    mach_vm_address_t propsList = Read<mach_vm_address_t>(localProps + 0x18, so2_task);
                    for (int j = 0; j < propsSize; j++) {
                        mach_vm_address_t propkey = Read<mach_vm_address_t>(propsList + 0x28 + 0x18 * j, so2_task);
                        if (!propkey) continue;
                        int keyLen = Read<int>(propkey + 0x10, so2_task);
                        if (keyLen == 4) {
                            uint64_t str_val = Read<uint64_t>(propkey + 0x14, so2_task);
                            if (str_val == 0x006D006100650074ULL) { // "team"
                                mach_vm_address_t propval = Read<mach_vm_address_t>(propsList + 0x30 + 0x18 * j, so2_task);
                                localTeam = Read<int>(propval + 0x10, so2_task);
                                break;
                            }
                        }
                    }
                }
            }
            mach_vm_address_t *players = (mach_vm_address_t *)malloc(capacity * sizeof(mach_vm_address_t));
            for (int i = 0; i < capacity; i++) {
                players[i] = Read<mach_vm_address_t>(entries_arr + 0x20 + (i * 0x18) + 0x10, so2_task);
            }

            for (int i = 0; i < capacity; i++) {
                mach_vm_address_t player = players[i];
                if (player < 0x1000000 || player == localPlayer) continue;

                if (esp_team_check) {
                    mach_vm_address_t photon = Read<mach_vm_address_t>(player + 0x160, so2_task);
                    if (photon > 0x1000000) {
                        mach_vm_address_t props = Read<mach_vm_address_t>(photon + 0x38, so2_task);
                        if (props > 0x1000000) {
                            mach_vm_address_t propsList = Read<mach_vm_address_t>(props + 0x18, so2_task);
                            if (propsList > 0x1000000) {
                                if (GetPlayerTeamAim(player, so2_task) == localTeam) continue;
                            }
                        }
                    }
                }

                mach_vm_address_t moveCtrl = Read<mach_vm_address_t>(player + 0x98, so2_task);
                if (moveCtrl < 0x1000000) continue;
                
                mach_vm_address_t moveData = Read<mach_vm_address_t>(moveCtrl + 0xB0, so2_task);
                if (moveData < 0x1000000) continue;

                Vector3 pos = Read<Vector3>(moveData + 0x44, so2_task);
                if (pos.x == 0 && pos.y == 0 && pos.z == 0) continue;

                Vector3 screenFoot = WorldToScreen(pos, viewMatrix, w, h);
                if (screenFoot.z <= 0.01f) continue;

                Vector3 headPos = pos;
                headPos.y += 1.67f;
                Vector3 screenHead = WorldToScreen(headPos, viewMatrix, w, h);

                if (screenHead.z > 0.01f && screenFoot.y > screenHead.y) {
                    validPlayers++;
                    float bh = screenFoot.y - screenHead.y;
                    float bw = bh / 2.0f;
                    
                    if (drawBoxes) {
                        CGRect rect = CGRectMake(screenHead.x - bw / 2.0f, screenHead.y, bw, bh);
                        
                        if (esp_box_fill) {
                            [boxFillPath appendPath:[UIBezierPath bezierPathWithRect:rect]];
                        }
                        
                        if (esp_box_3d) {
                            float bw3d = 0.35f;
                            Vector3 p[8];
                            p[0] = {pos.x - bw3d, pos.y, pos.z - bw3d};
                            p[1] = {pos.x + bw3d, pos.y, pos.z - bw3d};
                            p[2] = {pos.x + bw3d, pos.y, pos.z + bw3d};
                            p[3] = {pos.x - bw3d, pos.y, pos.z + bw3d};

                            p[4] = {headPos.x - bw3d, headPos.y, headPos.z - bw3d};
                            p[5] = {headPos.x + bw3d, headPos.y, headPos.z - bw3d};
                            p[6] = {headPos.x + bw3d, headPos.y, headPos.z + bw3d};
                            p[7] = {headPos.x - bw3d, headPos.y, headPos.z + bw3d};

                            Vector3 sp[8];
                            bool allValid = true;
                            for (int i=0; i<8; i++) {
                                sp[i] = WorldToScreen(p[i], viewMatrix, w, h);
                                if (sp[i].z <= 0) allValid = false;
                            }

                            if (allValid) {
                                auto drawCube = [&](UIBezierPath *pth) {
                                    [pth moveToPoint:CGPointMake(sp[0].x, sp[0].y)]; [pth addLineToPoint:CGPointMake(sp[1].x, sp[1].y)];
                                    [pth addLineToPoint:CGPointMake(sp[2].x, sp[2].y)]; [pth addLineToPoint:CGPointMake(sp[3].x, sp[3].y)];
                                    [pth addLineToPoint:CGPointMake(sp[0].x, sp[0].y)];
                                    [pth moveToPoint:CGPointMake(sp[4].x, sp[4].y)]; [pth addLineToPoint:CGPointMake(sp[5].x, sp[5].y)];
                                    [pth addLineToPoint:CGPointMake(sp[6].x, sp[6].y)]; [pth addLineToPoint:CGPointMake(sp[7].x, sp[7].y)];
                                    [pth addLineToPoint:CGPointMake(sp[4].x, sp[4].y)];
                                    [pth moveToPoint:CGPointMake(sp[0].x, sp[0].y)]; [pth addLineToPoint:CGPointMake(sp[4].x, sp[4].y)];
                                    [pth moveToPoint:CGPointMake(sp[1].x, sp[1].y)]; [pth addLineToPoint:CGPointMake(sp[5].x, sp[5].y)];
                                    [pth moveToPoint:CGPointMake(sp[2].x, sp[2].y)]; [pth addLineToPoint:CGPointMake(sp[6].x, sp[6].y)];
                                    [pth moveToPoint:CGPointMake(sp[3].x, sp[3].y)]; [pth addLineToPoint:CGPointMake(sp[7].x, sp[7].y)];
                                };
                                drawCube(boxPath);
                                if (esp_box_outline) drawCube(boxOutlinePath);
                            } else {

                                [boxPath appendPath:[UIBezierPath bezierPathWithRect:rect]];
                                if (esp_box_outline) [boxOutlinePath appendPath:[UIBezierPath bezierPathWithRect:rect]];
                            }
                        } else if (esp_box_corner) {
                            float cw = bw / 4.0f;
                            float ch = bh / 4.0f;
                            
                            [boxPath moveToPoint:CGPointMake(rect.origin.x, rect.origin.y + ch)];
                            [boxPath addLineToPoint:CGPointMake(rect.origin.x, rect.origin.y)];
                            [boxPath addLineToPoint:CGPointMake(rect.origin.x + cw, rect.origin.y)];
                            [boxPath moveToPoint:CGPointMake(rect.origin.x + bw - cw, rect.origin.y)];
                            [boxPath addLineToPoint:CGPointMake(rect.origin.x + bw, rect.origin.y)];
                            [boxPath addLineToPoint:CGPointMake(rect.origin.x + bw, rect.origin.y + ch)];
                            [boxPath moveToPoint:CGPointMake(rect.origin.x + bw, rect.origin.y + bh - ch)];
                            [boxPath addLineToPoint:CGPointMake(rect.origin.x + bw, rect.origin.y + bh)];
                            [boxPath addLineToPoint:CGPointMake(rect.origin.x + bw - cw, rect.origin.y + bh)];
                            [boxPath moveToPoint:CGPointMake(rect.origin.x + cw, rect.origin.y + bh)];
                            [boxPath addLineToPoint:CGPointMake(rect.origin.x, rect.origin.y + bh)];
                            [boxPath addLineToPoint:CGPointMake(rect.origin.x, rect.origin.y + bh - ch)];
                            
                            if (esp_box_outline) {
                                [boxOutlinePath appendPath:boxPath];
                            }
                        } else {
                            [boxPath appendPath:[UIBezierPath bezierPathWithRect:rect]];
                            if (esp_box_outline) [boxOutlinePath appendPath:[UIBezierPath bezierPathWithRect:rect]];
                        }
                    }
                    
                    if (drawLines) {
                        [linesPath moveToPoint:CGPointMake(w / 2.0f, 0)];
                        [linesPath addLineToPoint:CGPointMake(screenHead.x, screenHead.y)];
                        if (esp_line_outline) {
                            [lineOutlinePath moveToPoint:CGPointMake(w / 2.0f, 0)];
                            [lineOutlinePath addLineToPoint:CGPointMake(screenHead.x, screenHead.y)];
                        }
                    }

                    if (esp_name_enabled) {
                        UILabel *nameLbl = nil;
                        if (nameLabelIdx < self.nameLabelPool.count) {
                            nameLbl = self.nameLabelPool[nameLabelIdx];
                        } else {
                            nameLbl = [[UILabel alloc] init];
                            nameLbl.userInteractionEnabled = NO;
                            [self addSubview:nameLbl];
                            [self.nameLabelPool addObject:nameLbl];
                        }
                        nameLabelIdx++;
                        
                        UIImageView *avatarView = nil;
                        if (esp_avatar_enabled) {
                            if (avatarIdx < self.avatarPool.count) {
                                avatarView = self.avatarPool[avatarIdx];
                            } else {
                                avatarView = [[UIImageView alloc] init];
                                avatarView.userInteractionEnabled = NO;
                                avatarView.layer.cornerRadius = 2.0;
                                avatarView.clipsToBounds = YES;
                                [self addSubview:avatarView];
                                [self.avatarPool addObject:avatarView];
                            }
                            avatarIdx++;
                        }

                        mach_vm_address_t photon_n = Read<mach_vm_address_t>(player + 0x160, so2_task);
                        NSString *nameStr = @"???";
                        if (photon_n > 0x1000000) {
                            mach_vm_address_t namePtr = Read<mach_vm_address_t>(photon_n + 0x20, so2_task);
                            if (namePtr > 0x1000000) {
                                int nameLen = Read<int>(namePtr + 0x10, so2_task);
                                if (nameLen > 0 && nameLen < 32) {
struct UnityString32 { uint16_t chars[32]; };
                                    UnityString32 strData = Read<UnityString32>(namePtr + 0x14, so2_task);
                                    nameStr = [NSString stringWithCharacters:(const unichar *)strData.chars length:nameLen];
                                }
                            }
                        }

                        if (esp_name_outline) {
                            NSDictionary *attrs = @{
                                NSFontAttributeName: [UIFont systemFontOfSize:10 weight:UIFontWeightBold],
                                NSForegroundColorAttributeName: [UIColor whiteColor],
                                NSStrokeColorAttributeName: [UIColor blackColor],
                                NSStrokeWidthAttributeName: @(-2.0),
                            };
                            nameLbl.attributedText = [[NSAttributedString alloc] initWithString:nameStr attributes:attrs];
                        } else {
                            nameLbl.font = [UIFont systemFontOfSize:10 weight:UIFontWeightBold];
                            nameLbl.text = nameStr;
                            nameLbl.textColor = [UIColor whiteColor];
                        }

                        [nameLbl sizeToFit];
                        
                        if (esp_avatar_enabled) {
                            NSData *pfpData = GetPlayerAvatarData(player, so2_task);
                            if (pfpData) {
                                UIImage *pfpImg = [UIImage imageWithData:pfpData];
                                if (pfpImg) {
                                    avatarView.image = pfpImg;
                                    float avatarSize = 13.0;
                                    float totalWidth = nameLbl.frame.size.width + avatarSize + 4;
                                    
                                    avatarView.frame = CGRectMake(screenHead.x - totalWidth/2.0f, screenHead.y - 10 - avatarSize/2.0f, avatarSize, avatarSize);
                                    nameLbl.center = CGPointMake(screenHead.x + (avatarSize+4)/2.0f, screenHead.y - 10);
                                    avatarView.hidden = NO;
                                } else {
                                    avatarView.hidden = YES;
                                    nameLbl.center = CGPointMake(screenHead.x, screenHead.y - 10);
                                }
                            } else {
                                avatarView.hidden = YES;
                                nameLbl.center = CGPointMake(screenHead.x, screenHead.y - 10);
                            }
                        } else {
                            nameLbl.center = CGPointMake(screenHead.x, screenHead.y - 10);
                        }
                        
                        nameLbl.hidden = NO;
                    }

                    int hpVal = GetPlayerHealthAim(player, so2_task);
                    if (hpVal > 100) hpVal = 100;
                    if (hpVal < 0) hpVal = 0;
                    float healthPercent = (float)hpVal / 100.0f;
                    float barTopY = screenFoot.y - (bh * healthPercent);
                    float barX = screenHead.x - bw/2.0f - 5;

                    if (esp_health_enabled) {
                        UILabel *hpLbl = nil;
                        if (hpLabelIdx < self.healthLabelPool.count) {
                            hpLbl = self.healthLabelPool[hpLabelIdx];
                        } else {
                            hpLbl = [[UILabel alloc] init];
                            hpLbl.userInteractionEnabled = NO;
                            [self addSubview:hpLbl];
                            [self.healthLabelPool addObject:hpLbl];
                        }
                        hpLabelIdx++;

                        hpLbl.text = [NSString stringWithFormat:@"%d", hpVal];
                        hpLbl.font = [UIFont systemFontOfSize:10 weight:UIFontWeightBold];
                        hpLbl.textColor = [UIColor whiteColor];
                        [hpLbl sizeToFit];
                        
                        float textX = screenHead.x - bw/2.0f - hpLbl.frame.size.width/2.0f - 2;
                        if (esp_health_bar_enabled) {
                            textX -= 6; 
                            hpLbl.center = CGPointMake(textX, barTopY);
                        } else {
                            hpLbl.center = CGPointMake(textX, screenHead.y + hpLbl.frame.size.height/2.0f);
                        }
                        hpLbl.hidden = NO;
                    }

                    if (esp_health_bar_enabled) {
                        float barTopYCalc = screenFoot.y - bh; 
                        
                        [healthBarOutlinePath moveToPoint:CGPointMake(barX, screenFoot.y)];
                        [healthBarOutlinePath addLineToPoint:CGPointMake(barX, barTopYCalc)];
                        
                        [healthBarPath moveToPoint:CGPointMake(barX, screenFoot.y)];
                        [healthBarPath addLineToPoint:CGPointMake(barX, barTopY)];
                    }

                    if (esp_weapon_enabled || esp_weapon_icon_enabled) {
                        UILabel *weaponLbl = nil;
                        if (weaponLabelIdx < self.weaponLabelPool.count) {
                            weaponLbl = self.weaponLabelPool[weaponLabelIdx];
                        } else {
                            weaponLbl = [[UILabel alloc] init];
                            weaponLbl.userInteractionEnabled = NO;
                            [self addSubview:weaponLbl];
                            [self.weaponLabelPool addObject:weaponLbl];
                        }
                        weaponLabelIdx++;

                        UIImageView *iconView = nil;
                        if (weaponIconIdx < self.weaponIconPool.count) {
                            iconView = self.weaponIconPool[weaponIconIdx];
                        } else {
                            iconView = [[UIImageView alloc] init];
                            iconView.userInteractionEnabled = NO;
                            iconView.contentMode = UIViewContentModeScaleAspectFit;
                            [self addSubview:iconView];
                            [self.weaponIconPool addObject:iconView];
                        }
                        weaponIconIdx++;

                        NSString *weaponStr = @"";
                        mach_vm_address_t wc = Read<mach_vm_address_t>(player + 0x88, so2_task);
                        if (wc > 0x1000000) {
                            mach_vm_address_t ctrl = Read<mach_vm_address_t>(wc + 0xA0, so2_task);
                            if (ctrl > 0x1000000) {
                                mach_vm_address_t wp = Read<mach_vm_address_t>(ctrl + 0xA8, so2_task);
                                if (wp > 0x1000000) {
                                    mach_vm_address_t namePtr = Read<mach_vm_address_t>(wp + 0x20, so2_task);
                                    if (namePtr > 0x1000000) {
                                        int nameLen = Read<int>(namePtr + 0x10, so2_task);
                                        if (nameLen > 0 && nameLen < 32) {
                                            struct UnityString32 { uint16_t chars[32]; };
                                            UnityString32 strData = Read<UnityString32>(namePtr + 0x14, so2_task);
                                            weaponStr = [NSString stringWithCharacters:(const unichar *)strData.chars length:nameLen];
                                        }
                                    }
                                }
                            }
                        }

                        if (weaponStr.length > 0) {
                            NSString *lowerStr = weaponStr.lowercaseString;
                            UIImage *iconImg = nil;
                            
                            // MAPPING
                            if ([lowerStr containsString:@"akr12"]) { iconImg = [UIImage imageWithData:[NSData dataWithBytes:__akr12 length:sizeof(__akr12)]]; weaponStr = @"AKR12"; }
                            else if ([lowerStr containsString:@"akr"]) { iconImg = [UIImage imageWithData:[NSData dataWithBytes:__akr length:sizeof(__akr)]]; weaponStr = @"AK-47"; }
                            else if ([lowerStr containsString:@"famas"]) { iconImg = [UIImage imageWithData:[NSData dataWithBytes:__famas length:sizeof(__famas)]]; weaponStr = @"Famas"; }
                            else if ([lowerStr containsString:@"fnfal"]) { iconImg = [UIImage imageWithData:[NSData dataWithBytes:__fnfal length:sizeof(__fnfal)]]; weaponStr = @"FNFAL"; }
                            else if ([lowerStr containsString:@"m16"]) { iconImg = [UIImage imageWithData:[NSData dataWithBytes:__m16 length:sizeof(__m16)]]; weaponStr = @"M16"; }
                            else if ([lowerStr containsString:@"m4a1"]) { iconImg = [UIImage imageWithData:[NSData dataWithBytes:__m4 length:sizeof(__m4)]]; weaponStr = @"M4A1"; }
                            else if ([lowerStr containsString:@"m4"]) { iconImg = [UIImage imageWithData:[NSData dataWithBytes:__m4 length:sizeof(__m4)]]; weaponStr = @"M4"; }
                            else if ([lowerStr containsString:@"val"]) { iconImg = [UIImage imageWithData:[NSData dataWithBytes:__val length:sizeof(__val)]]; weaponStr = @"AS VAL"; }
                            // Pistols
                            else if ([lowerStr containsString:@"g22"] || [lowerStr containsString:@"glock"]) { iconImg = [UIImage imageWithData:[NSData dataWithBytes:__g22 length:sizeof(__g22)]]; weaponStr = @"G22"; }
                            else if ([lowerStr containsString:@"deagle"] || [lowerStr containsString:@"desert"]) { iconImg = [UIImage imageWithData:[NSData dataWithBytes:__desert_eagle length:sizeof(__desert_eagle)]]; weaponStr = @"Deagle"; }
                            else if ([lowerStr containsString:@"usp"]) { iconImg = [UIImage imageWithData:[NSData dataWithBytes:__usp length:sizeof(__usp)]]; weaponStr = @"USP"; }
                            else if ([lowerStr containsString:@"p350"]) { iconImg = [UIImage imageWithData:[NSData dataWithBytes:__p350 length:sizeof(__p350)]]; weaponStr = @"P350"; }
                            else if ([lowerStr containsString:@"tec9"]) { iconImg = [UIImage imageWithData:[NSData dataWithBytes:__tec9 length:sizeof(__tec9)]]; weaponStr = @"TEC-9"; }
                            else if ([lowerStr containsString:@"five"]) { iconImg = [UIImage imageWithData:[NSData dataWithBytes:__five_seven length:sizeof(__five_seven)]]; weaponStr = @"FS"; }
                            else if ([lowerStr containsString:@"berettas"]) { iconImg = [UIImage imageWithData:[NSData dataWithBytes:__berettas length:sizeof(__berettas)]]; weaponStr = @"Dual Berettas"; }
                            // SMGs
                            else if ([lowerStr containsString:@"mac10"]) { iconImg = [UIImage imageWithData:[NSData dataWithBytes:__mac10 length:sizeof(__mac10)]]; weaponStr = @"MAC-10"; }
                            else if ([lowerStr containsString:@"mp5"]) { iconImg = [UIImage imageWithData:[NSData dataWithBytes:__mp5 length:sizeof(__mp5)]]; weaponStr = @"MP5"; }
                            else if ([lowerStr containsString:@"mp7"]) { iconImg = [UIImage imageWithData:[NSData dataWithBytes:__mp7 length:sizeof(__mp7)]]; weaponStr = @"MP7"; }
                            else if ([lowerStr containsString:@"p90"]) { iconImg = [UIImage imageWithData:[NSData dataWithBytes:__p90 length:sizeof(__p90)]]; weaponStr = @"P90"; }
                            else if ([lowerStr containsString:@"ump45"]) { iconImg = [UIImage imageWithData:[NSData dataWithBytes:__ump45 length:sizeof(__ump45)]]; weaponStr = @"UMP45"; }
                            else if ([lowerStr containsString:@"uzi"]) { iconImg = [UIImage imageWithData:[NSData dataWithBytes:__uzi length:sizeof(__uzi)]]; weaponStr = @"UZI"; }
                            // Snipers
                            else if ([lowerStr containsString:@"awm"]) { iconImg = [UIImage imageWithData:[NSData dataWithBytes:__awm length:sizeof(__awm)]]; weaponStr = @"AWM"; }
                            else if ([lowerStr containsString:@"m110"]) { iconImg = [UIImage imageWithData:[NSData dataWithBytes:__m110 length:sizeof(__m110)]]; weaponStr = @"M110"; }
                            else if ([lowerStr containsString:@"m40"]) { iconImg = [UIImage imageWithData:[NSData dataWithBytes:__m40 length:sizeof(__m40)]]; weaponStr = @"M40"; }
                            else if ([lowerStr containsString:@"mallard"]) { iconImg = [UIImage imageWithData:[NSData dataWithBytes:__mallard length:sizeof(__mallard)]]; weaponStr = @"Mallard"; }
                            // Heavy
                            else if ([lowerStr containsString:@"fabm"]) { iconImg = [UIImage imageWithData:[NSData dataWithBytes:__fabm length:sizeof(__fabm)]]; weaponStr = @"Fabarm"; }
                            else if ([lowerStr containsString:@"m60"]) { iconImg = [UIImage imageWithData:[NSData dataWithBytes:__m60 length:sizeof(__m60)]]; weaponStr = @"M60"; }
                            else if ([lowerStr containsString:@"sm1014"]) { iconImg = [UIImage imageWithData:[NSData dataWithBytes:__sm1014 length:sizeof(__sm1014)]]; weaponStr = @"SM1014"; }
                            else if ([lowerStr containsString:@"spas"]) { iconImg = [UIImage imageWithData:[NSData dataWithBytes:__spas length:sizeof(__spas)]]; weaponStr = @"SPAS-12"; }
                            // Grenades
                            else if ([lowerStr containsString:@"flash"]) { iconImg = [UIImage imageWithData:[NSData dataWithBytes:__flash length:sizeof(__flash)]]; weaponStr = @"Flash"; }
                            else if ([lowerStr containsString:@"he"]) { iconImg = [UIImage imageWithData:[NSData dataWithBytes:__he length:sizeof(__he)]]; weaponStr = @"HE"; }
                            else if ([lowerStr containsString:@"molotov"]) { iconImg = [UIImage imageWithData:[NSData dataWithBytes:__molotov length:sizeof(__molotov)]]; weaponStr = @"Molotov"; }
                            else if ([lowerStr containsString:@"smoke"]) { iconImg = [UIImage imageWithData:[NSData dataWithBytes:__smoke length:sizeof(__smoke)]]; weaponStr = @"Smoke"; }
                            else if ([lowerStr containsString:@"thermite"]) { iconImg = [UIImage imageWithData:[NSData dataWithBytes:__thermite length:sizeof(__thermite)]]; weaponStr = @"Thermite"; }
                            // Knives   (test)
                            else if ([lowerStr containsString:@"butterfly"]) { iconImg = [UIImage imageWithData:[NSData dataWithBytes:__butterfly length:sizeof(__butterfly)]]; weaponStr = @"Butterfly"; }
                            else if ([lowerStr containsString:@"karambit"]) { iconImg = [UIImage imageWithData:[NSData dataWithBytes:__karambit length:sizeof(__karambit)]]; weaponStr = @"Karambit"; }
                            else if ([lowerStr containsString:@"m9"]) { iconImg = [UIImage imageWithData:[NSData dataWithBytes:__m9bayonet length:sizeof(__m9bayonet)]]; weaponStr = @"M9 Bayonet"; }
                            else if ([lowerStr containsString:@"tanto"]) { iconImg = [UIImage imageWithData:[NSData dataWithBytes:__tanto length:sizeof(__tanto)]]; weaponStr = @"Tanto"; }
                            else if ([lowerStr containsString:@"flip"]) { iconImg = [UIImage imageWithData:[NSData dataWithBytes:__flipknife length:sizeof(__flipknife)]]; weaponStr = @"Flip Knife"; }
                            else if ([lowerStr containsString:@"jkommando"]) { iconImg = [UIImage imageWithData:[NSData dataWithBytes:__jkommando length:sizeof(__jkommando)]]; weaponStr = @"Jkommando"; }
                            else if ([lowerStr containsString:@"scorpion"]) { iconImg = [UIImage imageWithData:[NSData dataWithBytes:__scorpion length:sizeof(__scorpion)]]; weaponStr = @"Scorpion"; }
                            else if ([lowerStr containsString:@"stiletto"]) { iconImg = [UIImage imageWithData:[NSData dataWithBytes:__stiletto length:sizeof(__stiletto)]]; weaponStr = @"Stiletto"; }
                            else if ([lowerStr containsString:@"kukri"]) { iconImg = [UIImage imageWithData:[NSData dataWithBytes:__kukri length:sizeof(__kukri)]]; weaponStr = @"Kukri"; }
                            else if ([lowerStr containsString:@"kunai"]) { iconImg = [UIImage imageWithData:[NSData dataWithBytes:__kunai length:sizeof(__kunai)]]; weaponStr = @"Kunai"; }
                            else if ([lowerStr containsString:@"fang"]) { iconImg = [UIImage imageWithData:[NSData dataWithBytes:__fang length:sizeof(__fang)]]; weaponStr = @"Fang"; }
                            else if ([lowerStr containsString:@"dual"]) { iconImg = [UIImage imageWithData:[NSData dataWithBytes:__dual_daggers length:sizeof(__dual_daggers)]]; weaponStr = @"Dual Daggers"; }
                            else if ([lowerStr containsString:@"kabar"]) { iconImg = [UIImage imageWithData:[NSData dataWithBytes:__kabar length:sizeof(__kabar)]]; weaponStr = @"Kabar"; }
                            else if ([lowerStr containsString:@"mantis"]) { iconImg = [UIImage imageWithData:[NSData dataWithBytes:__mantis length:sizeof(__mantis)]]; weaponStr = @"Mantis"; }
                            else if ([lowerStr containsString:@"sting"]) { iconImg = [UIImage imageWithData:[NSData dataWithBytes:__sting length:sizeof(__sting)]]; weaponStr = @"Sting"; }
                            else if ([lowerStr containsString:@"knife"]) { iconImg = [UIImage imageWithData:[NSData dataWithBytes:__karambit length:sizeof(__karambit)]]; weaponStr = @"Knife"; } // Default knife icon
                            // Other
                            else if ([lowerStr containsString:@"bomb"]) { iconImg = [UIImage imageWithData:[NSData dataWithBytes:__bomb length:sizeof(__bomb)]]; weaponStr = @"BOMB"; }

                            if (esp_weapon_enabled) {
                                if (esp_name_outline) {
                                    NSDictionary *attrs = @{
                                        NSFontAttributeName: [UIFont systemFontOfSize:10 weight:UIFontWeightBold],
                                        NSForegroundColorAttributeName: [UIColor whiteColor],
                                        NSStrokeColorAttributeName: [UIColor blackColor],
                                        NSStrokeWidthAttributeName: @(-2.0),
                                    };
                                    weaponLbl.attributedText = [[NSAttributedString alloc] initWithString:weaponStr attributes:attrs];
                                } else {
                                    weaponLbl.attributedText = nil;
                                    weaponLbl.font = [UIFont systemFontOfSize:10 weight:UIFontWeightBold];
                                    weaponLbl.textColor = [UIColor whiteColor];
                                    weaponLbl.text = weaponStr;
                                }
                                [weaponLbl sizeToFit];
                                weaponLbl.center = CGPointMake(screenHead.x, screenFoot.y + weaponLbl.frame.size.height/2.0f + 2);
                                weaponLbl.hidden = NO;
                            } else {
                                weaponLbl.hidden = YES;
                            }

                            if (esp_weapon_icon_enabled && iconImg) {
                                iconView.image = iconImg;
                                iconView.frame = CGRectMake(0, 0, 30, 15);
                                CGFloat yIcon = screenFoot.y + 10;
                                if (esp_weapon_enabled) {
                                    yIcon = weaponLbl.center.y + weaponLbl.frame.size.height/2.0f + 10;
                                }
                                iconView.center = CGPointMake(screenHead.x, yIcon);
                                iconView.hidden = NO;
                            } else {
                                iconView.hidden = YES;
                            }
                        } else {
                            weaponLbl.hidden = YES;
                            iconView.hidden = YES;
                        }
                    }

                    if (esp_platform_enabled) {
                        UILabel *plLbl = nil;
                        if (platformLabelIdx < self.platformLabelPool.count) {
                            plLbl = self.platformLabelPool[platformLabelIdx];
                        } else {
                            plLbl = [[UILabel alloc] init];
                            plLbl.userInteractionEnabled = NO;
                            plLbl.font = [UIFont systemFontOfSize:10 weight:UIFontWeightBold];
                            plLbl.textColor = [UIColor whiteColor];
                            [self addSubview:plLbl];
                            [self.platformLabelPool addObject:plLbl];
                        }
                        platformLabelIdx++;

                        int platformVal = GetPlayerPlatform(player, so2_task);

                        NSString *plStr = @"Unknown";
                        if (platformVal == 1) plStr = @"Android";
                        else if (platformVal == 2) plStr = @"iOS";
                        
                        plLbl.text = plStr;
                        [plLbl sizeToFit];
                        
                        plLbl.center = CGPointMake(screenHead.x + bw/2.0f + plLbl.frame.size.width/2.0f + 4, screenHead.y + plLbl.frame.size.height/2.0f);
                        plLbl.hidden = NO;
                    }
                }
            }
            self.playerCountLabel.text = [NSString stringWithFormat:@"extrahook | Players: %d", (int)validPlayers];
            self.playerCountLabel.hidden = NO;
            [self.playerCountLabel sizeToFit];
            free(players);

            [CATransaction begin];
            [CATransaction setDisableActions:YES];
            self.espBoxFillLayer.path     = (drawBoxes && esp_box_fill) ? boxFillPath.CGPath : nil;
            self.espBoxLayer.path         = drawBoxes ? boxPath.CGPath : nil;
            self.espBoxOutlineLayer.path  = (drawBoxes && esp_box_outline) ? boxOutlinePath.CGPath : nil;
            self.espLineLayer.path        = drawLines ? linesPath.CGPath : nil;
            self.espLineOutlineLayer.path = (drawLines && esp_line_outline) ? lineOutlinePath.CGPath : nil;
            self.espHealthBarLayer.path = esp_health_bar_enabled ? healthBarPath.CGPath : nil;
            self.espHealthBarOutlineLayer.path = (esp_health_bar_enabled && esp_health_bar_outline) ? healthBarOutlinePath.CGPath : nil;
            [CATransaction commit];
            [CATransaction flush];

            self.watermarkLabel.text = @(OBF("extrahook"));
            [self.watermarkLabel sizeToFit];
            return;
        }
    }

CLEAR_BOXES:
    [self clearAllBoxes];
    self.watermarkLabel.text = @"extrahook";
    [self.watermarkLabel sizeToFit];

    self.playerCountLabel.textColor = [[UIColor greenColor] colorWithAlphaComponent:0.5];
    self.playerCountLabel.text      = @"PLAYERS: 0";
    self.playerCountLabel.hidden    = !self.isESPCountEnabled;
    self.noPlayersLabel.hidden      = YES;
}

static mach_vm_address_t GetAimBoneOffset(int idx) {
    switch(idx) {
        case 0: return 0x20;
        case 1: return 0x28;
        case 2: return 0x40;
        case 3: return 0x88;
        default: return 0x20;
    }
}

static Vector3 GetBonePosition(mach_vm_address_t player, int boneIdx, task_t task) {
    mach_vm_address_t characterView = Read<mach_vm_address_t>(player + 0x48, task);
    if (!characterView || characterView < 0x1000000) return {0,0,0};
    
    mach_vm_address_t bipedMap = Read<mach_vm_address_t>(characterView + 0x48, task);
    if (!bipedMap || bipedMap < 0x1000000) return {0,0,0};
    
    mach_vm_address_t boneTransform = Read<mach_vm_address_t>(bipedMap + GetAimBoneOffset(boneIdx), task);
    if (!boneTransform || boneTransform < 0x1000000) return {0,0,0};
    
    return get_position_by_transform(boneTransform, task);
}

static int GetPlayerTeamAim(mach_vm_address_t player, task_t task) {
    if (!player || player < 0x1000000) return -1;
    mach_vm_address_t photon = Read<mach_vm_address_t>(player + 0x160, task);
    if (!photon || photon < 0x1000000) return -1;
    mach_vm_address_t props = Read<mach_vm_address_t>(photon + 0x38, task);
    if (!props || props < 0x1000000) return -1;
    int sz = Read<int>(props + 0x20, task);
    if (sz <= 0 || sz > 64) return -1;
    mach_vm_address_t entries = Read<mach_vm_address_t>(props + 0x18, task);
    if (!entries || entries < 0x1000000) return -1;
    for (int j = 0; j < sz && j < 32; j++) {
        mach_vm_address_t pk = Read<mach_vm_address_t>(entries + 0x28 + 0x18 * j, task);
        if (!pk || pk < 0x1000000) continue;
        int kl = Read<int>(pk + 0x10, task);
        if (kl == 4) {
            uint64_t str_val = Read<uint64_t>(pk + 0x14, task);
            if (str_val == 0x006D006100650074ULL) { // "team"
                mach_vm_address_t pv = Read<mach_vm_address_t>(entries + 0x30 + 0x18 * j, task);
                if (!pv || pv < 0x1000000) continue;
                return Read<int>(pv + 0x10, task);
            }
        }
    }
    return -1;
}




static NSData* GetPlayerAvatarData(mach_vm_address_t player, task_t task) {
    if (!player || player < 0x1000000) return nil;
    mach_vm_address_t photon = Read<mach_vm_address_t>(player + 0x160, task);
    if (!photon || photon < 0x1000000) return nil;
    mach_vm_address_t props = Read<mach_vm_address_t>(photon + 0x38, task);
    if (!props || props < 0x1000000) return nil;
    int sz = Read<int>(props + 0x20, task);
    if (sz <= 0 || sz > 64) return nil;
    mach_vm_address_t entries = Read<mach_vm_address_t>(props + 0x18, task);
    if (!entries || entries < 0x1000000) return nil;
    for (int j = 0; j < sz && j < 32; j++) {
        mach_vm_address_t pk = Read<mach_vm_address_t>(entries + 0x28 + 0x18 * j, task);
        if (!pk || pk < 0x1000000) continue;
        int kl = Read<int>(pk + 0x10, task);
        if (kl == 6) { // "avatar"
            uint64_t v1 = Read<uint64_t>(pk + 0x14, task); // first 4 chars "avat"
            if (v1 == 0x0074006100760061ULL) {
                mach_vm_address_t pv = Read<mach_vm_address_t>(entries + 0x30 + 0x18 * j, task);
                if (!pv || pv < 0x1000000) continue;
                int arrLen = Read<int>(pv + 0x18, task);
                if (arrLen > 0 && arrLen < 500000) {
                    void* buf = malloc(arrLen);
                    mach_vm_address_t dataCenter = pv + 0x20;
                    kern_return_t kr = mach_vm_read_overwrite(task, dataCenter, arrLen, (mach_vm_address_t)buf, (mach_vm_size_t*)&arrLen);
                    if (kr == KERN_SUCCESS) {
                        return [NSData dataWithBytesNoCopy:buf length:arrLen freeWhenDone:YES];
                    }
                    free(buf);
                }
            }
        }
    }
    return nil;
}

static int GetPlayerPlatform(mach_vm_address_t player, task_t task) {
    if (!player || player < 0x1000000) return 0;
    mach_vm_address_t photon = Read<mach_vm_address_t>(player + 0x160, task);
    if (!photon || photon < 0x1000000) return 0;
    mach_vm_address_t props = Read<mach_vm_address_t>(photon + 0x38, task);
    if (!props || props < 0x1000000) return 0;
    int sz = Read<int>(props + 0x20, task);
    if (sz <= 0 || sz > 64) return 0;
    mach_vm_address_t entries = Read<mach_vm_address_t>(props + 0x18, task);
    if (!entries || entries < 0x1000000) return 0;
    for (int j = 0; j < sz && j < 32; j++) {
        mach_vm_address_t pk = Read<mach_vm_address_t>(entries + 0x28 + 0x18 * j, task);
        if (!pk || pk < 0x1000000) continue;
        int kl = Read<int>(pk + 0x10, task);
        if (kl == 2) {
            uint32_t str_val = Read<uint32_t>(pk + 0x14, task);
             // "pl" -> p=0x70, l=0x6C -> memory: 70 00 6C 00 -> 0x006C0070
            if (str_val == 0x006C0070) {
                mach_vm_address_t pv = Read<mach_vm_address_t>(entries + 0x30 + 0x18 * j, task);
                if (!pv || pv < 0x1000000) continue;
                return Read<int>(pv + 0x10, task);
            }
        }
    }
    return 0;
}

static int GetPlayerHealthAim(mach_vm_address_t player, task_t task) {
    if (!player || player < 0x1000000) return 0;
    mach_vm_address_t photon = Read<mach_vm_address_t>(player + 0x160, task);
    if (!photon || photon < 0x1000000) return 0;
    mach_vm_address_t props = Read<mach_vm_address_t>(photon + 0x38, task);
    if (!props || props < 0x1000000) return 0;
    int sz = Read<int>(props + 0x20, task);
    if (sz <= 0 || sz > 64) return 0;
    mach_vm_address_t entries = Read<mach_vm_address_t>(props + 0x18, task);
    if (!entries || entries < 0x1000000) return 0;
    for (int j = 0; j < sz && j < 32; j++) {
        mach_vm_address_t pk = Read<mach_vm_address_t>(entries + 0x28 + 0x18 * j, task);
        if (!pk || pk < 0x1000000) continue;
        int kl = Read<int>(pk + 0x10, task);
        if (kl == 6) {
            uint64_t str_val = Read<uint64_t>(pk + 0x14, task);
            if (str_val == 0x006C006100650068ULL) { // "heal"
                mach_vm_address_t pv = Read<mach_vm_address_t>(entries + 0x30 + 0x18 * j, task);
                if (!pv || pv < 0x1000000) continue;
                return Read<int>(pv + 0x10, task);
            }
        }
    }
    return 0;
}

static BOOL IsPlayerVisible(mach_vm_address_t player, task_t task) {
    if (!player || player < 0x1000000) return NO;
    mach_vm_address_t occ = Read<mach_vm_address_t>(player + 0xB8, task);
    if (!occ || occ < 0x1000000) return YES;
    
    int visState = Read<int>(occ + 0x34, task);
    int occState = Read<int>(occ + 0x38, task);
    
    return (visState == 2 && occState != 1);
}


- (void)applyViewmodelSettings:(mach_vm_address_t)localPlayer task:(task_t)task {
    if (!localPlayer || localPlayer < 0x1000000) return;

    if (viewmodel_enabled) {
        mach_vm_address_t armsController = Read<mach_vm_address_t>(localPlayer + 0xA0, task);
        if (armsController && armsController > 0x1000000) {
            Vector3 offset = {viewmodel_x / -10.0f, viewmodel_y / -10.0f, viewmodel_z / -10.0f};
            Write<Vector3>(armsController + 0xE8, offset, task);
        }
    }
}


- (void)runAimbot:(mach_vm_address_t)localPlayer
          players:(mach_vm_address_t)playersList
            count:(int)count
        localTeam:(int)localTeam
             task:(task_t)so2_task
            width:(CGFloat)w
           height:(CGFloat)h
       viewMatrix:(SO2_Matrix)viewMatrix {

    [self applyViewmodelSettings:localPlayer task:so2_task];

    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    if (aimbot_fov_visible) {
        CGPoint center = CGPointMake(w / 2.0f, h / 2.0f);
        CGFloat radius = aimbot_fov;
        CGRect circleRect = CGRectMake(center.x - radius, center.y - radius, radius*2, radius*2);
        UIBezierPath *circlePath = [UIBezierPath bezierPathWithOvalInRect:circleRect];
        self.fovCircleOutlineLayer.path = circlePath.CGPath;
        self.fovCircleLayer.path        = circlePath.CGPath;
        self.fovCircleOutlineLayer.hidden = NO;
        self.fovCircleLayer.hidden        = NO;
    } else {
        self.fovCircleOutlineLayer.hidden = YES;
        self.fovCircleLayer.hidden        = YES;
    }
    [CATransaction commit];
    [CATransaction flush];

    if (!aimbot_enabled && !aimbot_triggerbot) {
        self.aimbotCurrentTarget = 0;
        if (self.triggerbotShooting) {
            mach_vm_address_t wc = Read<mach_vm_address_t>(localPlayer + 0x88, so2_task);
            if (!wc) wc = Read<mach_vm_address_t>(localPlayer + 0x68, so2_task);
            if (wc > 0x1000000) {
                mach_vm_address_t wctrl = Read<mach_vm_address_t>(wc + 0xA0, so2_task);
                if (wctrl > 0x1000000) {
                    Write<uint8_t>(wctrl + 0x148, 2, so2_task);
                }
            }
            self.triggerbotShooting = NO;
            self.triggerbotLastShotTime = CACurrentMediaTime();
        }
        return;
    }
    
    if (aimbot_shooting_check) {
        mach_vm_address_t wc = Read<mach_vm_address_t>(localPlayer + 0x88, so2_task);
        if (!wc) wc = Read<mach_vm_address_t>(localPlayer + 0x68, so2_task);
        if (wc > 0x1000000) {
            mach_vm_address_t wctrl = Read<mach_vm_address_t>(wc + 0xA0, so2_task);
            if (wctrl > 0x1000000) {
                uint8_t fireState = Read<uint8_t>(wctrl + 0x148, so2_task);
                if (fireState != 3) {
                    self.aimbotCurrentTarget = 0;
                    return;
                }
            }
        }
    }
    
    if (aimbot_knife_bot == NO) {
        mach_vm_address_t wc = Read<mach_vm_address_t>(localPlayer + 0x88, so2_task);
        if (wc > 0x1000000) {
            mach_vm_address_t wctrl = Read<mach_vm_address_t>(wc + 0xA0, so2_task);
            if (wctrl > 0x1000000) {
                mach_vm_address_t wp = Read<mach_vm_address_t>(wctrl + 0xA8, so2_task);
                if (wp > 0x1000000) {
                    uint8_t wid = Read<uint8_t>(wp + 0x18, so2_task);
                    if (wid >= 70 && wid < 90) {
                        self.aimbotCurrentTarget = 0;
                        return;
                    }
                }
            }
        }
    }

    float cx = w / 2.0f, cy = h / 2.0f;
    float closestDist = FLT_MAX;
    mach_vm_address_t closestPlayer = 0;
    Vector3 closestBonePos = {0,0,0};

    mach_vm_address_t entries = Read<mach_vm_address_t>(playersList + 0x18, so2_task);
    if (!entries || entries < 0x1000000) return;

    for (int i = 0; i < count && i < 32; i++) {
        mach_vm_address_t player = Read<mach_vm_address_t>(entries + 0x30 + 0x18 * i, so2_task);
        if (!player || player < 0x1000000) continue;
        if (player == localPlayer) continue;
        
        int hp = GetPlayerHealthAim(player, so2_task);
        if (hp <= 0) continue;
        
        if (aimbot_team_check && GetPlayerTeamAim(player, so2_task) == localTeam) continue;
        
        if (aimbot_visible_check && !IsPlayerVisible(player, so2_task)) continue;

        Vector3 bonePos = GetBonePosition(player, aimbot_bone_index, so2_task);
        if (bonePos.x == 0 && bonePos.y == 0 && bonePos.z == 0) continue;

        Vector3 sp = WorldToScreen(bonePos, viewMatrix, (int)w, (int)h);
        if (sp.z <= 0) continue;

        float dx = sp.x - cx, dy = sp.y - cy;
        float dist2D = sqrtf(dx*dx + dy*dy);
        if (dist2D > aimbot_fov) continue;

        if (dist2D < closestDist) {
            closestDist = dist2D;
            closestPlayer = player;
            closestBonePos = bonePos;
        }
    }

    if (!closestPlayer) {
        self.aimbotCurrentTarget = 0;
        if (self.triggerbotShooting) {
            mach_vm_address_t wc = Read<mach_vm_address_t>(localPlayer + 0x88, so2_task);
            if (!wc) wc = Read<mach_vm_address_t>(localPlayer + 0x68, so2_task);
            if (wc > 0x1000000) {
                mach_vm_address_t wctrl = Read<mach_vm_address_t>(wc + 0xA0, so2_task);
                if (wctrl > 0x1000000) {
                    Write<uint8_t>(wctrl + 0x148, 2, so2_task);
                }
            }
            self.triggerbotShooting = NO;
            self.triggerbotLastShotTime = CACurrentMediaTime();
        }
        return;
    }

    self.aimbotCurrentTarget = closestPlayer;

    mach_vm_address_t aimController = Read<mach_vm_address_t>(localPlayer + 0x80, so2_task);
    if (!aimController) aimController = Read<mach_vm_address_t>(localPlayer + 0x60, so2_task);
    if (!aimController || aimController < 0x1000000) return;

    mach_vm_address_t aimingData = Read<mach_vm_address_t>(aimController + 0x90, so2_task);
    if (!aimingData || aimingData < 0x1000000) return;

    mach_vm_address_t camTransform = Read<mach_vm_address_t>(aimController + 0x80, so2_task);
    Vector3 cameraPos = {0,0,0};
    if (camTransform && camTransform > 0x1000000) {
        cameraPos = get_position_by_transform(camTransform, so2_task);
    }
    if (cameraPos.x == 0 && cameraPos.y == 0 && cameraPos.z == 0) {
        mach_vm_address_t mv = Read<mach_vm_address_t>(localPlayer + 0x98, so2_task);
        if (mv > 0x1000000) {
            mach_vm_address_t md = Read<mach_vm_address_t>(mv + 0xB0, so2_task);
            if (md > 0x1000000) {
                cameraPos = Read<Vector3>(md + 0x44, so2_task);
            }
        }
    }

    float currentPitch = Read<float>(aimingData + 0x18, so2_task);
    float currentYaw   = Read<float>(aimingData + 0x1C, so2_task);

    float dirX = closestBonePos.x - cameraPos.x;
    float dirY = closestBonePos.y - cameraPos.y;
    float dirZ = closestBonePos.z - cameraPos.z;
    float dist = sqrtf(dirX*dirX + dirY*dirY + dirZ*dirZ);
    if (dist < 0.0001f) return;

    float targetPitch = -asinf(dirY / dist) * (180.0f / M_PI);
    float targetYaw   = atan2f(dirX, dirZ) * (180.0f / M_PI);

    float pitchDelta = targetPitch - currentPitch;
    float yawDelta   = targetYaw - currentYaw;
    while (yawDelta > 180.0f) yawDelta -= 360.0f;
    while (yawDelta < -180.0f) yawDelta += 360.0f;

    float newPitch, newYaw;

    if (aimbot_smooth <= 1.0f) {
        newPitch = fmaxf(-89.0f, fminf(89.0f, targetPitch));
        newYaw   = targetYaw;
    } else {
        float smooth = 1.0f / (1.0f + aimbot_smooth * 0.5f);
        smooth = fmaxf(0.03f, fminf(smooth, 1.0f));
        
        newPitch = fmaxf(-89.0f, fminf(89.0f, currentPitch + pitchDelta * smooth));
        newYaw   = currentYaw + yawDelta * smooth;
    }

    double now = CACurrentMediaTime();
    self.aimbotLastWriteTime = now;

    if (aimbot_enabled) {
        Write<float>(aimingData + 0x18, newPitch, so2_task);
        Write<float>(aimingData + 0x1C, newYaw,   so2_task);
        Write<float>(aimingData + 0x24, newPitch, so2_task);
        Write<float>(aimingData + 0x28, newYaw,   so2_task);
    }

    if (aimbot_triggerbot) {
        if (closestDist > 10.0f) {
            if (self.triggerbotShooting) {
                mach_vm_address_t wc = Read<mach_vm_address_t>(localPlayer + 0x88, so2_task);
                if (!wc) wc = Read<mach_vm_address_t>(localPlayer + 0x68, so2_task);
                if (wc > 0x1000000) {
                    mach_vm_address_t wctrl = Read<mach_vm_address_t>(wc + 0xA0, so2_task);
                    if (wctrl > 0x1000000) {
                        Write<uint8_t>(wctrl + 0x148, 2, so2_task);
                    }
                }
                self.triggerbotShooting = NO;
                self.triggerbotLastShotTime = now;
            }
            return;
        }

        mach_vm_address_t wc = Read<mach_vm_address_t>(localPlayer + 0x88, so2_task);
        if (!wc) wc = Read<mach_vm_address_t>(localPlayer + 0x68, so2_task);
        if (!wc || wc < 0x1000000) return;
        mach_vm_address_t wctrl = Read<mach_vm_address_t>(wc + 0xA0, so2_task);
        if (!wctrl || wctrl < 0x1000000) return;

        double elapsed = now - self.triggerbotLastShotTime;

        if (!self.triggerbotShooting) {
            if (elapsed >= aimbot_trigger_delay) {
                Write<uint8_t>(wctrl + 0x148, 3, so2_task);
                self.triggerbotShooting = YES;
                self.triggerbotLastShotTime = now;
            }
        } else {
            if (elapsed >= aimbot_trigger_delay) {
                Write<uint8_t>(wctrl + 0x148, 2, so2_task);
                self.triggerbotShooting = NO;
                self.triggerbotLastShotTime = now;
            }
        }
    }
}

- (void)launchGame {
    [[LSApplicationWorkspace defaultWorkspace]
        openApplicationWithBundleID:@(OBF("com.axlebolt.standoff2"))];
}

- (void)startBackgroundKeeper {
    [[AVAudioSession sharedInstance]
        setCategory:AVAudioSessionCategoryPlayback
        withOptions:AVAudioSessionCategoryOptionMixWithOthers
        error:nil];
    [[AVAudioSession sharedInstance] setActive:YES error:nil];

    NSURL *url = [NSURL URLWithString:@"https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3"];
    self.backgroundPlayer                 = [[AVPlayer alloc] initWithURL:url];
    self.backgroundPlayer.volume          = 0.0f;
    self.backgroundPlayer.actionAtItemEnd = AVPlayerActionAtItemEndNone;

    [[NSNotificationCenter defaultCenter]
        addObserver:self
           selector:@selector(playerItemDidReachEnd:)
               name:AVPlayerItemDidPlayToEndTimeNotification
             object:self.backgroundPlayer.currentItem];

    [self.backgroundPlayer play];
}

- (void)playerItemDidReachEnd:(NSNotification *)notification {
    [(AVPlayerItem *)notification.object seekToTime:kCMTimeZero completionHandler:nil];
}

@end