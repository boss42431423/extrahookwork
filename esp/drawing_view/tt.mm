#import "esp.h"
#import "cfg.h"
#include "obfusheader.h"
#import "tt.h"
#include <string>
#include <vector>
#include <map>
#import "../../sources/UIView+SecureView.h"

extern volatile bool esp_screenshot_safe;

// ── Accent color (antilose: ImVec4(1.0, 0.1, 0.1, 1.0)) ─────────────────────
// Ported from antilose: style->Colors[ImGuiCol_CheckMark] = accentColor;
static UIColor *g_accentColor;
static UIColor *Accent(void) {
    if (!g_accentColor) g_accentColor = [UIColor colorWithRed:1.0f green:0.10f blue:0.10f alpha:1.0f];
    return g_accentColor;
}
static void SetAccent(UIColor *c) { g_accentColor = c; }
#define GRAY(v) [UIColor colorWithWhite:(v)/255.0f alpha:1.0f]

// ── ESP Preview flag (antilose: MenuConfigT.EspPreview) ───────────────────────
static BOOL g_espPreviewEnabled = NO;
static UIView *g_espPreviewWindow = nil;  // floating preview view on ESP_View

// ─────────────────────────────────────────────────────────────────────────────
#pragma mark - CustomSliderView  (brazilix)
// ─────────────────────────────────────────────────────────────────────────────

@interface CustomSliderView : UIView
@property (nonatomic, assign) float value;
@property (nonatomic, assign) float minValue;
@property (nonatomic, assign) float maxValue;
@property (nonatomic, copy)   void (^valueChanged)(float newValue);
- (instancetype)initWithFrame:(CGRect)frame min:(float)min max:(float)max current:(float)current;
@end

@implementation CustomSliderView {
    UIView *_track;
    UIView *_fill;
    UIView *_thumb;
}
- (instancetype)initWithFrame:(CGRect)frame min:(float)min max:(float)max current:(float)current {
    self = [super initWithFrame:frame];
    if (self) {
        _minValue = min; _maxValue = max; _value = current;
        _track = [[UIView alloc] initWithFrame:CGRectMake(0, frame.size.height/2-1, frame.size.width, 2)];
        _track.backgroundColor = GRAY(45); _track.userInteractionEnabled = NO;
        [self addSubview:_track];
        _fill = [[UIView alloc] initWithFrame:CGRectMake(0, frame.size.height/2-1, 0, 2)];
        _fill.backgroundColor = Accent(); _fill.userInteractionEnabled = NO;
        [self addSubview:_fill];
        _thumb = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 12, 12)];
        _thumb.backgroundColor = Accent(); _thumb.layer.cornerRadius = 6;
        _thumb.userInteractionEnabled = NO;
        [self addSubview:_thumb];
        [self addGestureRecognizer:[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)]];
        [self addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)]];
        [self updateThumbPosition];
    }
    return self;
}
- (void)handlePan:(UIPanGestureRecognizer *)g { [self updateValueWithX:[g locationInView:self].x]; }
- (void)handleTap:(UITapGestureRecognizer *)g { [self updateValueWithX:[g locationInView:self].x]; }
- (void)updateValueWithX:(CGFloat)x {
    float p = x / self.frame.size.width;
    if (p < 0) p = 0; if (p > 1) p = 1;
    _value = _minValue + (_maxValue - _minValue) * p;
    [self updateThumbPosition];
    if (self.valueChanged) self.valueChanged(_value);
}
- (void)updateThumbPosition {
    float p = (_maxValue > _minValue) ? (_value - _minValue) / (_maxValue - _minValue) : 0;
    CGFloat x = self.frame.size.width * p;
    _thumb.center = CGPointMake(x, self.frame.size.height / 2);
    _fill.frame = CGRectMake(0, self.frame.size.height/2-1, x, 2);
}
- (void)setValue:(float)value { _value = value; [self updateThumbPosition]; }
@end

// ─────────────────────────────────────────────────────────────────────────────
#pragma mark - CustomSegmentedControl  (brazilix)
// ─────────────────────────────────────────────────────────────────────────────

@interface CustomSegmentedControl : UIView
@property (nonatomic, assign) NSInteger selectedIndex;
@property (nonatomic, copy)   void (^valueChanged)(NSInteger newIndex);
- (instancetype)initWithFrame:(CGRect)frame items:(NSArray *)items current:(NSInteger)current;
- (void)reloadUI:(NSInteger)idx;
@end
@implementation CustomSegmentedControl { NSArray *_items; NSMutableArray *_labels; }
- (instancetype)initWithFrame:(CGRect)frame items:(NSArray *)items current:(NSInteger)current {
    self = [super initWithFrame:frame];
    if (self) {
        _items = items; _selectedIndex = current; _labels = [NSMutableArray new];
        self.backgroundColor = GRAY(20); self.layer.cornerRadius = 4; self.clipsToBounds = YES;
        CGFloat bw = frame.size.width / items.count;
        for (int i = 0; i < (int)items.count; i++) {
            UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(i*bw, 0, bw, frame.size.height)];
            l.text = items[i]; l.textAlignment = NSTextAlignmentCenter;
            l.font = [UIFont systemFontOfSize:10 weight:(i==current?UIFontWeightBold:UIFontWeightRegular)];
            l.textColor = (i==current) ? Accent() : GRAY(160);
            l.backgroundColor = (i==current) ? GRAY(38) : [UIColor clearColor];
            [self addSubview:l]; [_labels addObject:l];
        }
        [self addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)]];
    }
    return self;
}
- (void)reloadUI:(NSInteger)idx {
    if (idx < 0) idx = 0;
    if (idx >= (NSInteger)_items.count) idx = _items.count - 1;
    _selectedIndex = idx;
    for (int i = 0; i < (int)_labels.count; i++) {
        UILabel *l = _labels[i]; BOOL s = (i==idx);
        l.textColor = s ? Accent() : GRAY(160);
        l.backgroundColor = s ? GRAY(38) : [UIColor clearColor];
        l.font = [UIFont systemFontOfSize:10 weight:(s?UIFontWeightBold:UIFontWeightRegular)];
    }
}
- (void)handleTap:(UITapGestureRecognizer *)g {
    NSInteger idx = (NSInteger)([g locationInView:self].x / (self.frame.size.width / _items.count));
    if (idx < 0) idx = 0; if (idx >= (NSInteger)_items.count) idx = _items.count-1;
    [self reloadUI:idx]; if (self.valueChanged) self.valueChanged(idx);
}
@end

// ─────────────────────────────────────────────────────────────────────────────
#pragma mark - VerticalOnlyPanGestureRecognizer  (brazilix)
// ─────────────────────────────────────────────────────────────────────────────

@interface VerticalOnlyPanGestureRecognizer : UIPanGestureRecognizer @end
@implementation VerticalOnlyPanGestureRecognizer
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    UIView *v = touches.anyObject.view;
    while (v) {
        if ([v isKindOfClass:[CustomSegmentedControl class]] || [v isKindOfClass:[CustomSliderView class]])
        { self.state = UIGestureRecognizerStateFailed; return; } v = v.superview;
    }
    [super touchesBegan:touches withEvent:event];
}
- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesMoved:touches withEvent:event];
    if (self.state == UIGestureRecognizerStateBegan) {
        CGPoint vel = [self velocityInView:self.view];
        if (fabs(vel.x) > fabs(vel.y)) self.state = UIGestureRecognizerStateFailed;
    }
}
@end

// ─────────────────────────────────────────────────────────────────────────────
#pragma mark - MenuView
// ─────────────────────────────────────────────────────────────────────────────

@interface MenuView () <UIGestureRecognizerDelegate> @end

@implementation MenuView {
    // ── antilose: animated gradient (collerp) ─────────────────────────────
    CAGradientLayer *_gradL, *_gradR;
    CADisplayLink   *_gradLink;
    float            _colstage;
    BOOL             _colswitch;

    // ── brazilix layout ───────────────────────────────────────────────────
    UIView *_headerView;
    UIView *_contentView;
    UIView *_leftBarView;
    UIView *_aimContainer, *_visualContainer, *_playerContainer;
    UIView *_configContainer, *_skinContainer, *_otherContainer;
    UIView *_innerContent;
    NSMutableArray<UILabel *> *_tabLabels;
    CGPoint _initialTouchPoint;

    // ── brazilix checkmarks ───────────────────────────────────────────────
    CAShapeLayer *_boxCheckmark, *_boxOutlineCheckmark, *_boxFillCheckmark;
    CAShapeLayer *_boxCornerCheckmark, *_box3DCheckmark;
    CAShapeLayer *_lineCheckmark, *_lineOutlineCheckmark;
    CAShapeLayer *_teamCheckmark, *_nameCheckmark, *_nameOutlineCheckmark;
    CAShapeLayer *_invisibleCheckmark, *_addscoreCheckmark;
    CAShapeLayer *_infAmmoCheckmark, *_noSpreadCheckmark, *_airJumpCheckmark;
    CAShapeLayer *_fastKnifeCheckmark, *_bunnyHopCheckmark;
    CAShapeLayer *_wallshotCheckmark, *_fireRateCheckmark;
    CAShapeLayer *_healthCheckmark, *_healthBarCheckmark, *_healthBarOutlineCheckmark;
    CAShapeLayer *_weaponCheckmark, *_weaponIconCheckmark;
    CAShapeLayer *_platformCheckmark, *_avatarCheckmark;
    CAShapeLayer *_skeletonCheckmark, *_hitboxCheckmark;
    CAShapeLayer *_screenshotSafeCheckmark;
    // antilose ported features
    CAShapeLayer *_espPreviewCheckmark;

    CAShapeLayer *_aimbotCheckmark, *_triggerbotCheckmark;
    CAShapeLayer *_aimbotFovVisibleCheckmark;
    CAShapeLayer *_visibleCheckCheckmark, *_shootingCheckCheckmark;
    CAShapeLayer *_knifeBotCheckmark, *_aimbotTeamCheckmark;
    CAShapeLayer *_rcsCheckmark, *_viewmodelCheckmark;

    // ── brazilix content views ────────────────────────────────────────────
    UIView *_aimContent, *_visualContent, *_playerContent;
    UIView *_configContent, *_skinContent, *_otherContent;

    // ── brazilix sliders ──────────────────────────────────────────────────
    CustomSegmentedControl *_boneSelector;
    UILabel *_fovValueLabel, *_smoothValueLabel, *_rcsHValueLabel;
    UILabel *_rcsVValueLabel, *_bhopValueLabel, *_triggerDelayValueLabel;
    UILabel *_viewmodelXValueLabel, *_viewmodelYValueLabel, *_viewmodelZValueLabel;
    CustomSliderView *_fovSlider, *_smoothSlider, *_rcsHSlider;
    CustomSliderView *_rcsVSlider, *_bhopSlider, *_triggerDelaySlider;
    CustomSliderView *_viewmodelXSlider, *_viewmodelYSlider, *_viewmodelZSlider;

    // ── brazilix config/skin ──────────────────────────────────────────────
    CGFloat _configListStartY, _skinListStartY;
    NSTimer *_skinTimer;
    NSArray *_cachedSkins;
    std::map<int, std::string> _allSkinsMap;
    std::vector<std::pair<int, uintptr_t>> _ownedSkinsInfo;
    int _selectedOwnedIdx, _selectedReplaceIdx;
    std::vector<std::pair<int, std::string>> _allSkinsList;
}

// ── antilose: gradient tick (collerp teal→purple→yellow-green) ───────────────
- (void)tickGradient:(CADisplayLink *)link {
    float dt = (float)link.duration;
    _colstage += _colswitch ? dt : -dt;
    if (_colstage >= 1.0f) { _colstage = 1.0f; _colswitch = NO; }
    if (_colstage <= 0.0f) { _colstage = 0.0f; _colswitch = YES; }
    float t = _colstage;
    // antilose: otcol1(100,160,180) otcol2(170,95,170) otcol3(200,210,135)
    // ntcol = collerp(otcol1,otcol2,t); etc.
    UIColor *c1 = [UIColor colorWithRed:(100+t*(170-100))/255.f green:(160+t*(95-160))/255.f  blue:(180+t*(170-180))/255.f alpha:1];
    UIColor *c2 = [UIColor colorWithRed:(170+t*(200-170))/255.f green:(95+t*(210-95))/255.f   blue:(170+t*(135-170))/255.f alpha:1];
    UIColor *c3 = [UIColor colorWithRed:(200+t*(100-200))/255.f green:(210+t*(160-210))/255.f blue:(135+t*(180-135))/255.f alpha:1];
    [CATransaction begin]; [CATransaction setDisableActions:YES];
    _gradL.colors = @[(id)c1.CGColor, (id)c2.CGColor];
    _gradR.colors = @[(id)c2.CGColor, (id)c3.CGColor];
    [CATransaction commit];
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (!self) return nil;
    self.backgroundColor = [UIColor blackColor];
    self.clipsToBounds = YES;
    self.userInteractionEnabled = YES;
    _selectedOwnedIdx = -1; _selectedReplaceIdx = -1;

    CGFloat W = frame.size.width, H = frame.size.height;

    // ── antilose: layered borders ─────────────────────────────────────────
    // DrawMenuRect: (0,0,0) → (60,60,60) → (40,40,40) → (60,60,60) → (12,12,12)
    float borderRGB[] = {0, 60, 40, 60, 12};
    CGFloat borderIns[] = {0, 1, 2, 5, 6};
    for (int i = 0; i < 5; i++) {
        CALayer *l = [CALayer layer];
        l.frame = CGRectInset(self.bounds, borderIns[i], borderIns[i]);
        l.backgroundColor = GRAY(borderRGB[i]).CGColor;
        l.zPosition = -10 + i;
        [self.layer addSublayer:l];
    }

    const CGFloat B     = 6.0f;
    const CGFloat HDR_H = 8.0f;   // antilose header strip height
    const CGFloat CAT_W = 70.0f;  // brazilix leftBarWidth

    // ── antilose: animated gradient header strip ──────────────────────────
    _headerView = [[UIView alloc] initWithFrame:CGRectMake(B, B, W-B*2, HDR_H)];
    _headerView.backgroundColor = GRAY(20);
    _headerView.userInteractionEnabled = YES;
    [self addSubview:_headerView];
    CGFloat hw = (W-B*2)/2.0f;
    _gradL = [CAGradientLayer layer]; _gradL.frame = CGRectMake(0,0,hw,HDR_H);
    _gradL.startPoint = CGPointMake(0,0.5); _gradL.endPoint = CGPointMake(1,0.5);
    _gradR = [CAGradientLayer layer]; _gradR.frame = CGRectMake(hw,0,hw,HDR_H);
    _gradR.startPoint = CGPointMake(0,0.5); _gradR.endPoint = CGPointMake(1,0.5);
    _gradL.colors = _gradR.colors = @[(id)GRAY(100).CGColor,(id)GRAY(100).CGColor];
    [_headerView.layer addSublayer:_gradL]; [_headerView.layer addSublayer:_gradR];
    _colstage = 0.f; _colswitch = YES;
    _gradLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(tickGradient:)];
    _gradLink.preferredFramesPerSecond = 30;
    [_gradLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    // drag by header (brazilix)
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    pan.cancelsTouchesInView = NO; [_headerView addGestureRecognizer:pan];

    // ── antilose: sidebar (dark 12,12,12 + dividers 0/41/20) ─────────────
    _leftBarView = [[UIView alloc] initWithFrame:CGRectMake(B, B+HDR_H, CAT_W, H-B-(B+HDR_H))];
    _leftBarView.backgroundColor = GRAY(12);
    _leftBarView.userInteractionEnabled = YES;
    [self addSubview:_leftBarView];
    float divRGB[] = {0, 41, 20};
    for (int i = 0; i < 3; i++) {
        UIView *d = [[UIView alloc] initWithFrame:CGRectMake(B+CAT_W+i, B, 1, H-B*2)];
        d.backgroundColor = GRAY(divRGB[i]); d.userInteractionEnabled = NO;
        [self addSubview:d];
    }

    // antilose: "A" logo with accent color + glow
    UILabel *logo = [[UILabel alloc] initWithFrame:CGRectMake(0, 2, CAT_W, 28)];
    logo.text = @"EH"; logo.textAlignment = NSTextAlignmentCenter;
    logo.font = [UIFont boldSystemFontOfSize:15]; logo.textColor = Accent();
    logo.userInteractionEnabled = NO; [_leftBarView addSubview:logo];

    // antilose: AddCategoryButton style — accent color + bold when selected, gray otherwise
    NSArray *tabs = @[@(OBF("AIM")),@(OBF("VISUAL")),@(OBF("PLAYER")),@(OBF("CONFIG")),@(OBF("SKINS")),@(OBF("OTHER"))];
    _tabLabels = [NSMutableArray new];
    for (int i = 0; i < 6; i++) {
        UILabel *tl = [[UILabel alloc] initWithFrame:CGRectMake(0, 32+i*32, CAT_W, 32)];
        tl.text = tabs[i]; tl.textAlignment = NSTextAlignmentCenter;
        tl.font = [UIFont systemFontOfSize:11 weight:(i==0?UIFontWeightBold:UIFontWeightRegular)];
        tl.textColor = (i==0) ? Accent() : GRAY(160);
        tl.userInteractionEnabled = YES; tl.tag = i;
        [_leftBarView addSubview:tl]; [_tabLabels addObject:tl];
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tabTapped:)];
        [tl addGestureRecognizer:tap];
    }

    // ── antilose: content area triple inner border (0 → 40 → 30) ─────────
    CGFloat cX = B+CAT_W+3, cY = B+HDR_H, cW = W-cX-B, cH = H-cY-B;
    float innerRGB[] = {0, 40, 28};
    for (int i = 0; i < 3; i++) {
        UIView *cb = [[UIView alloc] initWithFrame:CGRectMake(cX+i, cY+i, cW-i*2, cH-i*2)];
        cb.backgroundColor = GRAY(innerRGB[i]); cb.userInteractionEnabled = NO;
        [self addSubview:cb];
    }
    _contentView = [[UIView alloc] initWithFrame:CGRectMake(cX+3, cY+3, cW-6, cH-6)];
    _contentView.clipsToBounds = YES; _contentView.userInteractionEnabled = YES;
    _contentView.backgroundColor = [UIColor clearColor];
    [self addSubview:_contentView];

    // ── brazilix: containers ──────────────────────────────────────────────
    _aimContainer    = [[UIView alloc] initWithFrame:_contentView.bounds];
    _visualContainer = [[UIView alloc] initWithFrame:_contentView.bounds];
    _playerContainer = [[UIView alloc] initWithFrame:_contentView.bounds];
    _configContainer = [[UIView alloc] initWithFrame:_contentView.bounds];
    _skinContainer   = [[UIView alloc] initWithFrame:_contentView.bounds];
    _otherContainer  = [[UIView alloc] initWithFrame:_contentView.bounds];
    _visualContainer.hidden = _playerContainer.hidden = _configContainer.hidden =
        _skinContainer.hidden = _otherContainer.hidden = YES;
    CGFloat cw = _contentView.bounds.size.width;
    _aimContent    = [[UIView alloc] initWithFrame:CGRectMake(0,0,cw,500)];
    _visualContent = [[UIView alloc] initWithFrame:CGRectMake(0,0,cw,640)];
    _playerContent = [[UIView alloc] initWithFrame:CGRectMake(0,0,cw,480)];
    _configContent = [[UIView alloc] initWithFrame:CGRectMake(0,0,cw,400)];
    _skinContent   = [[UIView alloc] initWithFrame:CGRectMake(0,0,cw,2000)];
    _otherContent  = [[UIView alloc] initWithFrame:CGRectMake(0,0,cw,300)];
    for (UIView *v in @[_aimContent,_visualContent,_playerContent,_configContent,_skinContent,_otherContent])
        v.userInteractionEnabled = YES;
    [_aimContainer addSubview:_aimContent]; [_visualContainer addSubview:_visualContent];
    [_playerContainer addSubview:_playerContent]; [_configContainer addSubview:_configContent];
    [_skinContainer addSubview:_skinContent]; [_otherContainer addSubview:_otherContent];
    [_contentView addSubview:_aimContainer]; [_contentView addSubview:_visualContainer];
    [_contentView addSubview:_playerContainer]; [_contentView addSubview:_configContainer];
    [_contentView addSubview:_skinContainer]; [_contentView addSubview:_otherContainer];
    VerticalOnlyPanGestureRecognizer *sp = [[VerticalOnlyPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleScrollPan:)];
    sp.cancelsTouchesInView = YES; sp.delaysTouchesBegan = sp.delaysTouchesEnded = NO;
    sp.delegate = self; [_contentView addGestureRecognizer:sp];

    // ── SKINS tab (brazilix) ──────────────────────────────────────────────
    _innerContent = _skinContent;
    CGFloat yS = 4; [self addSectionHeader:@"SKINS" atY:yS]; yS += 26; _skinListStartY = yS;
    _skinTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(refreshSkinList) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:_skinTimer forMode:NSRunLoopCommonModes];
    [self refreshSkinList];

    // ── AIM tab (brazilix) ────────────────────────────────────────────────
    _innerContent = _aimContent;
    CGFloat y = 4;
    [self addSectionHeader:@(OBF("AIMBOT")) atY:y]; y += 26;
    _aimbotCheckmark           = [self addToggle:@(OBF("Aimbot"))        atY:y action:@selector(aimbotTapped)        enabled:aimbot_enabled];       y+=32;
    _triggerbotCheckmark       = [self addToggle:@(OBF("Triggerbot"))    atY:y action:@selector(triggerbotTapped)    enabled:aimbot_triggerbot];     y+=32;
    _aimbotFovVisibleCheckmark = [self addToggle:@(OBF("FOV Circle"))    atY:y action:@selector(aimbotFovTapped)     enabled:aimbot_fov_visible];    y+=32;
    _visibleCheckCheckmark     = [self addToggle:@(OBF("Visible Check")) atY:y action:@selector(visibleCheckTapped)  enabled:aimbot_visible_check];  y+=32;
    _shootingCheckCheckmark    = [self addToggle:@(OBF("Fire Check"))    atY:y action:@selector(shootingCheckTapped) enabled:aimbot_shooting_check]; y+=32;
    _knifeBotCheckmark         = [self addToggle:@(OBF("Knife Bot"))     atY:y action:@selector(knifeBotTapped)      enabled:aimbot_knife_bot];      y+=32;
    _aimbotTeamCheckmark       = [self addToggle:@(OBF("Team Check"))    atY:y action:@selector(aimbotTeamTapped)    enabled:aimbot_team_check];     y+=32;
    [self addSectionHeader:@(OBF("Smooth")) atY:y]; y+=26; [self addSmoothSliderAtY:y]; y+=45;
    [self addSectionHeader:@(OBF("FOV")) atY:y]; y+=26; [self addFovSliderAtY:y]; y+=45;
    [self addSectionHeader:@(OBF("Trigger Delay")) atY:y]; y+=26; [self addTriggerDelaySliderAtY:y]; y+=45;
    [self addSectionHeader:@(OBF("Bone")) atY:y]; y+=26; [self addBoneSelectorAtY:y]; y+=36;
    { CGRect f=_aimContent.frame; f.size.height=y+10; _aimContent.frame=f; }

    // ── VISUAL tab (brazilix + antilose ESP Preview) ──────────────────────
    _innerContent = _visualContent;
    y = 4;
    [self addSectionHeader:@(OBF("ESP")) atY:y]; y+=26;
    _boxCheckmark             = [self addToggle:@(OBF("Box 2D"))       atY:y action:@selector(boxTapped)             enabled:esp_box_enabled];        y+=32;
    _boxOutlineCheckmark      = [self addToggle:@(OBF("Box Outline"))  atY:y action:@selector(boxOutlineTapped)      enabled:esp_box_outline];         y+=32;
    _boxFillCheckmark         = [self addToggle:@(OBF("Box Fill"))     atY:y action:@selector(boxFillTapped)         enabled:esp_box_fill];            y+=32;
    _boxCornerCheckmark       = [self addToggle:@(OBF("Box Corner"))   atY:y action:@selector(boxCornerTapped)       enabled:esp_box_corner];          y+=32;
    _box3DCheckmark           = [self addToggle:@(OBF("Box 3D"))       atY:y action:@selector(box3DTapped)           enabled:esp_box_3d];              y+=32;
    _lineCheckmark            = [self addToggle:@(OBF("Line"))         atY:y action:@selector(lineTapped)            enabled:esp_line_enabled];        y+=32;
    _lineOutlineCheckmark     = [self addToggle:@(OBF("Line Outline")) atY:y action:@selector(lineOutlineTapped)     enabled:esp_line_outline];        y+=32;
    _skeletonCheckmark        = [self addToggle:@(OBF("Skeleton"))     atY:y action:@selector(skeletonTapped)        enabled:esp_skeleton_enabled];    y+=32;
    _hitboxCheckmark          = [self addToggle:@(OBF("Hitbox OBB"))   atY:y action:@selector(hitboxTapped)          enabled:esp_hitbox_enabled];      y+=32;
    _teamCheckmark            = [self addToggle:@(OBF("Team Check"))   atY:y action:@selector(teamTapped)            enabled:esp_team_check];          y+=32;
    _nameCheckmark            = [self addToggle:@(OBF("Name"))         atY:y action:@selector(nameTapped)            enabled:esp_name_enabled];        y+=32;
    _healthCheckmark          = [self addToggle:@(OBF("HP"))           atY:y action:@selector(healthTapped)          enabled:esp_health_enabled];      y+=32;
    _healthBarCheckmark       = [self addToggle:@(OBF("Health Bar"))   atY:y action:@selector(healthBarTapped)       enabled:esp_health_bar_enabled];  y+=32;
    _healthBarOutlineCheckmark= [self addToggle:@(OBF("Bar Outline"))  atY:y action:@selector(healthBarOutlineTapped)enabled:esp_health_bar_outline];  y+=32;
    _weaponCheckmark          = [self addToggle:@(OBF("Weapon"))       atY:y action:@selector(weaponTapped)          enabled:esp_weapon_enabled];      y+=32;
    _weaponIconCheckmark      = [self addToggle:@(OBF("Weapon Icon"))  atY:y action:@selector(weaponIconTapped)      enabled:esp_weapon_icon_enabled]; y+=32;
    _platformCheckmark        = [self addToggle:@(OBF("Platform"))     atY:y action:@selector(platformTapped)        enabled:esp_platform_enabled];    y+=32;
    _avatarCheckmark          = [self addToggle:@(OBF("Avatars"))      atY:y action:@selector(avatarTapped)          enabled:esp_avatar_enabled];      y+=32;
    // antilose port: MenuConfig.EspPreview
    _espPreviewCheckmark      = [self addToggle:@(OBF("ESP Preview"))  atY:y action:@selector(espPreviewTapped)      enabled:g_espPreviewEnabled];     y+=32;
    [self addSectionHeader:@(OBF("VIEWMODEL")) atY:y]; y+=26;
    _viewmodelCheckmark = [self addToggle:@(OBF("Viewmodel")) atY:y action:@selector(viewmodelTapped) enabled:viewmodel_enabled]; y+=37;
    [self addSectionHeader:@(OBF("View X")) atY:y]; y+=26; [self addViewmodelXSliderAtY:y]; y+=45;
    [self addSectionHeader:@(OBF("View Y")) atY:y]; y+=26; [self addViewmodelYSliderAtY:y]; y+=45;
    [self addSectionHeader:@(OBF("View Z")) atY:y]; y+=26; [self addViewmodelZSliderAtY:y]; y+=45;
    { CGRect f=_visualContent.frame; f.size.height=y+10; _visualContent.frame=f; }

    // ── PLAYER tab (brazilix) ─────────────────────────────────────────────
    _innerContent = _playerContent;
    y = 4; [self addSectionHeader:@(OBF("PLAYER")) atY:y]; y+=26;
    _invisibleCheckmark = [self addToggle:@(OBF("Invisible"))  atY:y action:@selector(invisibleTapped)  enabled:esp_invisible];  y+=32;
    _addscoreCheckmark  = [self addToggle:@(OBF("Add Score"))  atY:y action:@selector(addskoreTapped)   enabled:esp_addscore];   y+=32;
    _infAmmoCheckmark   = [self addToggle:@(OBF("Inf Ammo"))   atY:y action:@selector(infAmmoTapped)    enabled:esp_inf_ammo];   y+=32;
    _noSpreadCheckmark  = [self addToggle:@(OBF("No Spread"))  atY:y action:@selector(noSpreadTapped)   enabled:esp_no_spread];  y+=32;
    _airJumpCheckmark   = [self addToggle:@(OBF("Air Jump"))   atY:y action:@selector(airJumpTapped)    enabled:esp_air_jump];   y+=32;
    _fastKnifeCheckmark = [self addToggle:@(OBF("Fast Knife")) atY:y action:@selector(fastKnifeTapped)  enabled:esp_fast_knife]; y+=32;
    _bunnyHopCheckmark  = [self addToggle:@(OBF("Bunny Hop"))  atY:y action:@selector(bunnyHopTapped)   enabled:esp_bunny_hop];  y+=32;
    [self addSectionHeader:@(OBF("Bunny Hop Speed")) atY:y]; y+=26; [self addBhopSliderAtY:y]; y+=45;
    _rcsCheckmark = [self addToggle:@(OBF("RCS")) atY:y action:@selector(rcsTapped) enabled:esp_rcs_enabled]; y+=37;
    [self addSectionHeader:@(OBF("RCS Horizontal")) atY:y]; y+=26; [self addRCSHSliderAtY:y]; y+=45;
    [self addSectionHeader:@(OBF("RCS Vertical"))   atY:y]; y+=26; [self addRCSVSliderAtY:y]; y+=45;
    _wallshotCheckmark = [self addToggle:@(OBF("Wallshot"))  atY:y action:@selector(wallshotTapped)  enabled:esp_wallshot];  y+=32;
    _fireRateCheckmark = [self addToggle:@(OBF("Fire Rate")) atY:y action:@selector(fireRateTapped)  enabled:esp_fire_rate]; y+=32;
    { CGRect f=_playerContent.frame; f.size.height=y+10; _playerContent.frame=f; }

    // ── CONFIG tab (brazilix + antilose: accent color presets + Unload) ───
    _innerContent = _configContent;
    y = 4; [self addSectionHeader:@(OBF("CONFIGS")) atY:y]; y+=26;
    CGFloat btnW = (_configContent.bounds.size.width-30)/3.0;
    NSString *btnTitles[] = {@(OBF("Create")), @(OBF("Delete")), @(OBF("Load"))};
    SEL      btnSels[]   = {@selector(createConfigFlow), @selector(deleteConfigFlow), @selector(loadConfigFlow)};
    for (int bi = 0; bi < 3; bi++) {
        UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(10+bi*(btnW+5), y, btnW, 30)];
        l.text = btnTitles[bi]; l.textAlignment = NSTextAlignmentCenter;
        l.font = [UIFont boldSystemFontOfSize:12]; l.textColor = GRAY(200);
        l.backgroundColor = GRAY(35); l.layer.cornerRadius = 4; l.layer.masksToBounds = YES;
        l.userInteractionEnabled = YES;
        [l addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:btnSels[bi]]];
        [_configContent addSubview:l];
    }
    y += 40; _configListStartY = y; [self refreshConfigList];

    // antilose port: accent color (StyledColorEdit4 → simple preset buttons)
    y = _configListStartY + 120; // approx below config list
    [self addSectionHeader:@(OBF("ACCENT COLOR")) atY:y]; y+=26;
    [self addAccentColorPickerAtY:y]; y+=36;

    // antilose port: Unload button
    [self addSectionHeader:@(OBF("DANGER")) atY:y]; y+=26;
    UILabel *unloadBtn = [[UILabel alloc] initWithFrame:CGRectMake(10, y, _configContent.bounds.size.width-20, 32)];
    unloadBtn.text = @(OBF("Unload")); unloadBtn.textAlignment = NSTextAlignmentCenter;
    unloadBtn.font = [UIFont boldSystemFontOfSize:13]; unloadBtn.textColor = Accent();
    unloadBtn.backgroundColor = [UIColor colorWithRed:0.4f green:0.05f blue:0.05f alpha:1];
    unloadBtn.layer.cornerRadius = 4; unloadBtn.layer.masksToBounds = YES;
    unloadBtn.userInteractionEnabled = YES;
    [unloadBtn addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(unloadTapped)]];
    [_configContent addSubview:unloadBtn]; y+=40;
    { CGRect f=_configContent.frame; f.size.height=y+10; _configContent.frame=f; }

    // ── OTHER tab (brazilix) ──────────────────────────────────────────────
    _innerContent = _otherContent;
    y = 4; [self addSectionHeader:@(OBF("OTHER")) atY:y]; y+=26;
    _screenshotSafeCheckmark = [self addToggle:@(OBF("Overlay")) atY:y action:@selector(screenshotSafeTapped) enabled:esp_screenshot_safe]; y+=32;
    { CGRect f=_otherContent.frame; f.size.height=y+10; _otherContent.frame=f; }

    _innerContent = nil;
    [self showViewForCapture];
    return self;
}

// ── antilose port: accent color preset picker (iOS UIKit) ─────────────────────
- (void)addAccentColorPickerAtY:(CGFloat)y {
    CGFloat w = _innerContent.bounds.size.width;
    // 6 preset accent colors (antilose uses configurable accentColor)
    NSArray *colors = @[
        [UIColor colorWithRed:1.0f green:0.1f blue:0.1f alpha:1],   // red (antilose default)
        [UIColor colorWithRed:0.1f green:0.6f blue:1.0f alpha:1],   // blue
        [UIColor colorWithRed:0.1f green:1.0f blue:0.3f alpha:1],   // green
        [UIColor colorWithRed:1.0f green:0.6f blue:0.1f alpha:1],   // orange
        [UIColor colorWithRed:0.8f green:0.1f blue:1.0f alpha:1],   // purple
        [UIColor colorWithRed:1.0f green:1.0f blue:1.0f alpha:1],   // white
    ];
    CGFloat sz = (w - 20 - 5*6) / 6.0f;
    for (int i = 0; i < 6; i++) {
        UIView *chip = [[UIView alloc] initWithFrame:CGRectMake(10+i*(sz+5), y, sz, 28)];
        chip.backgroundColor = colors[i];
        chip.layer.cornerRadius = 4;
        chip.layer.masksToBounds = YES;
        chip.userInteractionEnabled = YES;
        chip.tag = 9000 + i;
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(accentColorChipTapped:)];
        [chip addGestureRecognizer:tap];
        [_innerContent addSubview:chip];
    }
}

- (void)accentColorChipTapped:(UITapGestureRecognizer *)g {
    NSArray *colors = @[
        [UIColor colorWithRed:1.0f green:0.1f blue:0.1f alpha:1],
        [UIColor colorWithRed:0.1f green:0.6f blue:1.0f alpha:1],
        [UIColor colorWithRed:0.1f green:1.0f blue:0.3f alpha:1],
        [UIColor colorWithRed:1.0f green:0.6f blue:0.1f alpha:1],
        [UIColor colorWithRed:0.8f green:0.1f blue:1.0f alpha:1],
        [UIColor colorWithRed:1.0f green:1.0f blue:1.0f alpha:1],
    ];
    NSInteger idx = g.view.tag - 9000;
    if (idx >= 0 && idx < (NSInteger)colors.count)
        SetAccent(colors[idx]);
}

// antilose port: Unload — RequestUnload() → hide HUD window
- (void)unloadTapped {
    if (self.superview && self.superview.superview)
        self.superview.superview.hidden = YES;
}

// antilose port: ESP Preview — MenuConfig.EspPreview
- (void)espPreviewTapped {
    g_espPreviewEnabled = !g_espPreviewEnabled;
    [self animateCheckmark:_espPreviewCheckmark show:g_espPreviewEnabled];
    // Show/hide floating preview label on parent ESP_View
    if (g_espPreviewEnabled) {
        UIView *espView = self.superview;
        if (!g_espPreviewWindow && espView) {
            UIView *prev = [[UIView alloc] initWithFrame:CGRectMake(10, 50, 160, 90)];
            prev.backgroundColor = [UIColor colorWithWhite:0 alpha:0.7f];
            prev.layer.cornerRadius = 6; prev.layer.borderWidth = 1;
            prev.layer.borderColor = Accent().CGColor;
            UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(8, 8, 144, 74)];
            lbl.text = @"ESP Preview\n(live view)";
            lbl.textColor = Accent(); lbl.font = [UIFont boldSystemFontOfSize:11];
            lbl.numberOfLines = 0; lbl.textAlignment = NSTextAlignmentCenter;
            [prev addSubview:lbl];
            g_espPreviewWindow = prev;
            [espView addSubview:prev];
        } else if (g_espPreviewWindow) {
            g_espPreviewWindow.hidden = NO;
        }
    } else {
        g_espPreviewWindow.hidden = YES;
    }
}

// ── UI helpers ────────────────────────────────────────────────────────────────

- (void)addSectionHeader:(NSString *)title atY:(CGFloat)y {
    UILabel *h = [[UILabel alloc] initWithFrame:CGRectMake(12, y, _innerContent.bounds.size.width-24, 22)];
    h.text = title; h.textColor = GRAY(100);
    h.font = [UIFont boldSystemFontOfSize:9]; h.userInteractionEnabled = NO;
    [_innerContent addSubview:h];
    UIView *sep = [[UIView alloc] initWithFrame:CGRectMake(12, y+20, _innerContent.bounds.size.width-24, 1)];
    sep.backgroundColor = GRAY(38); sep.userInteractionEnabled = NO;
    [_innerContent addSubview:sep];
}

// antilose: AddCategoryButton → addToggle: accent color checkmark when enabled
- (CAShapeLayer *)addToggle:(NSString *)name atY:(CGFloat)y action:(SEL)action enabled:(BOOL)enabled {
    UIView *row = [[UIView alloc] initWithFrame:CGRectMake(0, y, _innerContent.bounds.size.width, 30)];
    row.userInteractionEnabled = YES; [_innerContent addSubview:row];
    UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(15, 0, _innerContent.bounds.size.width-50, 30)];
    lbl.text = name; lbl.textColor = GRAY(210);
    lbl.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
    lbl.userInteractionEnabled = NO; [row addSubview:lbl];
    UIView *box = [[UIView alloc] initWithFrame:CGRectMake(_innerContent.bounds.size.width-37, 4, 22, 22)];
    box.layer.borderWidth = 1.5; box.layer.borderColor = GRAY(70).CGColor;
    box.layer.cornerRadius = 3; box.backgroundColor = GRAY(20);
    box.userInteractionEnabled = NO; [row addSubview:box];
    CAShapeLayer *ck = [self createCheckmarkLayer:box.bounds];
    ck.opacity = enabled ? 1.0 : 0.0; [box.layer addSublayer:ck];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:action];
    tap.cancelsTouchesInView = NO; [row addGestureRecognizer:tap];
    return ck;
}

// antilose: style->Colors[ImGuiCol_CheckMark] = accentColor → red stroke
- (CAShapeLayer *)createCheckmarkLayer:(CGRect)rect {
    UIBezierPath *p = [UIBezierPath bezierPath];
    [p moveToPoint:CGPointMake(rect.size.width*0.20, rect.size.height*0.50)];
    [p addLineToPoint:CGPointMake(rect.size.width*0.42, rect.size.height*0.72)];
    [p addLineToPoint:CGPointMake(rect.size.width*0.80, rect.size.height*0.28)];
    CAShapeLayer *l = [CAShapeLayer layer];
    l.path = p.CGPath; l.strokeColor = Accent().CGColor;
    l.fillColor = [UIColor clearColor].CGColor;
    l.lineWidth = 2.5; l.lineCap = kCALineCapRound; l.lineJoin = kCALineJoinRound;
    return l;
}

- (void)animateCheckmark:(CAShapeLayer *)ck show:(BOOL)show {
    if (show) {
        ck.opacity = 1.0;
        CABasicAnimation *a = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
        a.fromValue = @0.0; a.toValue = @1.0; a.duration = 0.25;
        a.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
        ck.strokeEnd = 1.0; [ck addAnimation:a forKey:@"draw"];
    } else {
        CABasicAnimation *a = [CABasicAnimation animationWithKeyPath:@"opacity"];
        a.fromValue = @1.0; a.toValue = @0.0; a.duration = 0.15;
        a.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
        ck.opacity = 0.0; [ck addAnimation:a forKey:@"hide"];
    }
}

// ── Tab switching (brazilix + antilose AddCategoryButton accent style) ─────────

- (void)tabTapped:(UITapGestureRecognizer *)g {
    NSInteger tag = g.view.tag;
    for (int i = 0; i < (int)_tabLabels.count; i++) {
        UILabel *l = _tabLabels[i]; BOOL s = (i==tag);
        l.font = [UIFont systemFontOfSize:11 weight:(s?UIFontWeightBold:UIFontWeightRegular)];
        l.textColor = s ? Accent() : GRAY(160);  // antilose: accent if selected, gray if not
    }
    _aimContainer.hidden=(tag!=0); _visualContainer.hidden=(tag!=1); _playerContainer.hidden=(tag!=2);
    _configContainer.hidden=(tag!=3); _skinContainer.hidden=(tag!=4); _otherContainer.hidden=(tag!=5);
    if (tag==4) [self refreshSkinList];
}

// ── Toggle handlers (brazilix) ────────────────────────────────────────────────

- (void)boxTapped {
    esp_box_enabled = !esp_box_enabled; [self animateCheckmark:_boxCheckmark show:esp_box_enabled];
    if (!esp_box_enabled) [[NSNotificationCenter defaultCenter] postNotificationName:@"ESPClearBoxes" object:nil];
}
- (void)lineTapped        { esp_line_enabled      =!esp_line_enabled;      [self animateCheckmark:_lineCheckmark             show:esp_line_enabled]; }
- (void)infAmmoTapped     { esp_inf_ammo          =!esp_inf_ammo;          [self animateCheckmark:_infAmmoCheckmark          show:esp_inf_ammo]; }
- (void)noSpreadTapped    { esp_no_spread         =!esp_no_spread;         [self animateCheckmark:_noSpreadCheckmark         show:esp_no_spread]; }
- (void)airJumpTapped     { esp_air_jump          =!esp_air_jump;          [self animateCheckmark:_airJumpCheckmark          show:esp_air_jump]; }
- (void)fastKnifeTapped   { esp_fast_knife        =!esp_fast_knife;        [self animateCheckmark:_fastKnifeCheckmark        show:esp_fast_knife]; }
- (void)bunnyHopTapped    { esp_bunny_hop         =!esp_bunny_hop;         [self animateCheckmark:_bunnyHopCheckmark         show:esp_bunny_hop]; }
- (void)wallshotTapped    { esp_wallshot          =!esp_wallshot;          [self animateCheckmark:_wallshotCheckmark         show:esp_wallshot]; }
- (void)fireRateTapped    { esp_fire_rate         =!esp_fire_rate;         [self animateCheckmark:_fireRateCheckmark         show:esp_fire_rate]; }
- (void)addskoreTapped    { esp_addscore          =!esp_addscore;          [self animateCheckmark:_addscoreCheckmark         show:esp_addscore]; }
- (void)invisibleTapped   { esp_invisible         =!esp_invisible;         [self animateCheckmark:_invisibleCheckmark        show:esp_invisible]; }
- (void)boxOutlineTapped  { esp_box_outline       =!esp_box_outline;       [self animateCheckmark:_boxOutlineCheckmark       show:esp_box_outline]; }
- (void)boxFillTapped     { esp_box_fill          =!esp_box_fill;          [self animateCheckmark:_boxFillCheckmark          show:esp_box_fill]; }
- (void)boxCornerTapped   { esp_box_corner        =!esp_box_corner;        [self animateCheckmark:_boxCornerCheckmark        show:esp_box_corner]; }
- (void)box3DTapped       { esp_box_3d            =!esp_box_3d;            [self animateCheckmark:_box3DCheckmark            show:esp_box_3d]; }
- (void)lineOutlineTapped { esp_line_outline      =!esp_line_outline;      [self animateCheckmark:_lineOutlineCheckmark      show:esp_line_outline]; }
- (void)nameTapped        { esp_name_enabled      =!esp_name_enabled;      [self animateCheckmark:_nameCheckmark             show:esp_name_enabled]; }
- (void)nameOutlineTapped { esp_name_outline      =!esp_name_outline;      [self animateCheckmark:_nameOutlineCheckmark      show:esp_name_outline]; }
- (void)skeletonTapped    { esp_skeleton_enabled  =!esp_skeleton_enabled;  [self animateCheckmark:_skeletonCheckmark         show:esp_skeleton_enabled]; }
- (void)hitboxTapped      { esp_hitbox_enabled    =!esp_hitbox_enabled;    [self animateCheckmark:_hitboxCheckmark           show:esp_hitbox_enabled]; }
- (void)teamTapped        { esp_team_check        =!esp_team_check;        [self animateCheckmark:_teamCheckmark             show:esp_team_check]; }
- (void)healthTapped      { esp_health_enabled    =!esp_health_enabled;    [self animateCheckmark:_healthCheckmark           show:esp_health_enabled]; }
- (void)healthBarTapped   { esp_health_bar_enabled=!esp_health_bar_enabled;[self animateCheckmark:_healthBarCheckmark        show:esp_health_bar_enabled]; }
- (void)healthBarOutlineTapped{esp_health_bar_outline=!esp_health_bar_outline;[self animateCheckmark:_healthBarOutlineCheckmark show:esp_health_bar_outline];}
- (void)weaponTapped      { esp_weapon_enabled    =!esp_weapon_enabled;    [self animateCheckmark:_weaponCheckmark           show:esp_weapon_enabled]; }
- (void)weaponIconTapped  { esp_weapon_icon_enabled=!esp_weapon_icon_enabled;[self animateCheckmark:_weaponIconCheckmark     show:esp_weapon_icon_enabled]; }
- (void)platformTapped    { esp_platform_enabled  =!esp_platform_enabled;  [self animateCheckmark:_platformCheckmark         show:esp_platform_enabled]; }
- (void)avatarTapped      { esp_avatar_enabled    =!esp_avatar_enabled;    [self animateCheckmark:_avatarCheckmark           show:esp_avatar_enabled]; }
- (void)viewmodelTapped   { viewmodel_enabled     =!viewmodel_enabled;     [self animateCheckmark:_viewmodelCheckmark        show:viewmodel_enabled]; }
- (void)aimbotTapped      { aimbot_enabled        =!aimbot_enabled;        [self animateCheckmark:_aimbotCheckmark           show:aimbot_enabled]; }
- (void)triggerbotTapped  { aimbot_triggerbot     =!aimbot_triggerbot;     [self animateCheckmark:_triggerbotCheckmark       show:aimbot_triggerbot]; }
- (void)aimbotFovTapped   { aimbot_fov_visible    =!aimbot_fov_visible;    [self animateCheckmark:_aimbotFovVisibleCheckmark show:aimbot_fov_visible]; }
- (void)visibleCheckTapped{ aimbot_visible_check  =!aimbot_visible_check;  [self animateCheckmark:_visibleCheckCheckmark     show:aimbot_visible_check]; }
- (void)shootingCheckTapped{aimbot_shooting_check =!aimbot_shooting_check; [self animateCheckmark:_shootingCheckCheckmark    show:aimbot_shooting_check];}
- (void)knifeBotTapped    { aimbot_knife_bot      =!aimbot_knife_bot;      [self animateCheckmark:_knifeBotCheckmark         show:aimbot_knife_bot]; }
- (void)aimbotTeamTapped  { aimbot_team_check     =!aimbot_team_check;     [self animateCheckmark:_aimbotTeamCheckmark       show:aimbot_team_check]; }
- (void)rcsTapped         { esp_rcs_enabled       =!esp_rcs_enabled;       [self animateCheckmark:_rcsCheckmark              show:esp_rcs_enabled]; }
- (void)screenshotSafeTapped {
    esp_screenshot_safe = !esp_screenshot_safe;
    [self animateCheckmark:_screenshotSafeCheckmark show:esp_screenshot_safe];
    if (self.superview) [self.superview hideViewFromCapture:esp_screenshot_safe];
    else [self hideViewFromCapture:esp_screenshot_safe];
}

// ── Sliders (brazilix) ────────────────────────────────────────────────────────

- (void)addBoneSelectorAtY:(CGFloat)y {
    CGFloat w = _innerContent.bounds.size.width;
    _boneSelector = [[CustomSegmentedControl alloc] initWithFrame:CGRectMake(10,y,w-20,28)
                                                            items:@[@"Head",@"Neck",@"Spine",@"Hip"]
                                                          current:aimbot_bone_index];
    _boneSelector.valueChanged = ^(NSInteger i){ aimbot_bone_index=(int)i; };
    [_innerContent addSubview:_boneSelector];
}

#define MAKE_SLIDER(NAME, VAR, MIN, MAX, FMT, IVAR) \
- (void)add##NAME##SliderAtY:(CGFloat)y { \
    CGFloat w = _innerContent.bounds.size.width; \
    _ ##IVAR##ValueLabel = [[UILabel alloc] initWithFrame:CGRectMake(w-60,y-24,50,20)]; \
    _ ##IVAR##ValueLabel.textColor = GRAY(160); _ ##IVAR##ValueLabel.font = [UIFont systemFontOfSize:11]; \
    _ ##IVAR##ValueLabel.textAlignment = NSTextAlignmentRight; \
    _ ##IVAR##ValueLabel.text = [NSString stringWithFormat:FMT, VAR]; \
    [_innerContent addSubview:_ ##IVAR##ValueLabel]; \
    __weak MenuView *ws = self; \
    _ ##IVAR##Slider = [[CustomSliderView alloc] initWithFrame:CGRectMake(15,y,w-30,30) min:MIN max:MAX current:(float)VAR]; \
    _ ##IVAR##Slider.valueChanged = ^(float v){ VAR=v; __strong MenuView *s=ws; \
        if(s) s->_ ##IVAR##ValueLabel.text=[NSString stringWithFormat:FMT,v]; }; \
    [_innerContent addSubview:_ ##IVAR##Slider]; \
}

MAKE_SLIDER(Fov,          aimbot_fov,          10.f,  360.f, @"%.0f", fov)
MAKE_SLIDER(Smooth,       aimbot_smooth,        0.f,   20.f,  @"%.1f", smooth)
MAKE_SLIDER(TriggerDelay, aimbot_trigger_delay, 0.01f, 1.f,   @"%.2f", triggerDelay)
MAKE_SLIDER(RCSH,         esp_rcs_h,            0.f,   10.f,  @"%.1f", rcsH)
MAKE_SLIDER(RCSV,         esp_rcs_v,            0.f,   10.f,  @"%.1f", rcsV)
MAKE_SLIDER(Bhop,         esp_bhop_setting,     1.f,   10.f,  @"%.0f", bhop)
MAKE_SLIDER(ViewmodelX,   viewmodel_x,         -10.f,  10.f,  @"%.1f", viewmodelX)
MAKE_SLIDER(ViewmodelY,   viewmodel_y,         -10.f,  10.f,  @"%.1f", viewmodelY)
MAKE_SLIDER(ViewmodelZ,   viewmodel_z,         -10.f,  10.f,  @"%.1f", viewmodelZ)

// ── Config (brazilix) ─────────────────────────────────────────────────────────

- (void)refreshConfigList {
    for (UIView *v in [_configContent subviews])
        if (v.frame.origin.y >= _configListStartY && v.frame.origin.y < _configListStartY+120) [v removeFromSuperview];
    NSArray *configs = cfg_get_list(); CGFloat y = _configListStartY;
    for (NSString *name in configs) {
        UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(10,y,_configContent.bounds.size.width-20,30)];
        lbl.text = [NSString stringWithFormat:@"  %@", name];
        lbl.font = [UIFont systemFontOfSize:14]; lbl.textColor = GRAY(210);
        lbl.backgroundColor = [name isEqualToString:esp_selected_config] ? GRAY(50) : GRAY(30);
        lbl.layer.cornerRadius = 4; lbl.layer.masksToBounds = YES; lbl.userInteractionEnabled = YES;
        [lbl addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(selectConfigLbl:)]];
        [_configContent addSubview:lbl]; y+=35;
    }
}
- (void)selectConfigLbl:(UITapGestureRecognizer *)s {
    esp_selected_config = [[(UILabel *)s.view text] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    [self refreshConfigList];
}
- (void)createConfigFlow {
    NSDateFormatter *fmt = [[NSDateFormatter alloc] init]; [fmt setDateFormat:@"yyyyMMdd_HHmmss"];
    NSString *name = [NSString stringWithFormat:@"config_%@", [fmt stringFromDate:[NSDate date]]];
    cfg_create(name); esp_selected_config = name; [self refreshConfigList];
}
- (void)deleteConfigFlow {
    if (esp_selected_config.length>0) { cfg_delete(esp_selected_config); esp_selected_config=nil; [self refreshConfigList]; }
}
- (void)loadConfigFlow {
    if (!esp_selected_config.length) return;
    cfg_load(esp_selected_config);
    for (CAShapeLayer *ck in @[_boxCheckmark,_boxOutlineCheckmark,_boxFillCheckmark,_boxCornerCheckmark,
        _box3DCheckmark,_lineCheckmark,_lineOutlineCheckmark,_skeletonCheckmark,_hitboxCheckmark,
        _invisibleCheckmark,_addscoreCheckmark,_infAmmoCheckmark,_noSpreadCheckmark,_airJumpCheckmark,
        _fastKnifeCheckmark,_bunnyHopCheckmark,_wallshotCheckmark,_fireRateCheckmark,_teamCheckmark,
        _nameCheckmark,_nameOutlineCheckmark,_healthCheckmark,_healthBarCheckmark,_healthBarOutlineCheckmark,
        _weaponCheckmark,_weaponIconCheckmark,_platformCheckmark,_avatarCheckmark,_aimbotCheckmark,
        _visibleCheckCheckmark,_shootingCheckCheckmark,_knifeBotCheckmark,_rcsCheckmark,_triggerbotCheckmark,
        _aimbotFovVisibleCheckmark,_aimbotTeamCheckmark,_viewmodelCheckmark,_screenshotSafeCheckmark]) {
        // opacity will be set individually below
        (void)ck;
    }
    [self animateCheckmark:_boxCheckmark              show:esp_box_enabled];
    [self animateCheckmark:_boxOutlineCheckmark       show:esp_box_outline];
    [self animateCheckmark:_boxFillCheckmark          show:esp_box_fill];
    [self animateCheckmark:_boxCornerCheckmark        show:esp_box_corner];
    [self animateCheckmark:_box3DCheckmark            show:esp_box_3d];
    [self animateCheckmark:_lineCheckmark             show:esp_line_enabled];
    [self animateCheckmark:_lineOutlineCheckmark      show:esp_line_outline];
    [self animateCheckmark:_skeletonCheckmark         show:esp_skeleton_enabled];
    [self animateCheckmark:_hitboxCheckmark           show:esp_hitbox_enabled];
    [self animateCheckmark:_invisibleCheckmark        show:esp_invisible];
    [self animateCheckmark:_addscoreCheckmark         show:esp_addscore];
    [self animateCheckmark:_infAmmoCheckmark          show:esp_inf_ammo];
    [self animateCheckmark:_noSpreadCheckmark         show:esp_no_spread];
    [self animateCheckmark:_airJumpCheckmark          show:esp_air_jump];
    [self animateCheckmark:_fastKnifeCheckmark        show:esp_fast_knife];
    [self animateCheckmark:_bunnyHopCheckmark         show:esp_bunny_hop];
    [self animateCheckmark:_wallshotCheckmark         show:esp_wallshot];
    [self animateCheckmark:_fireRateCheckmark         show:esp_fire_rate];
    [self animateCheckmark:_teamCheckmark             show:esp_team_check];
    [self animateCheckmark:_nameCheckmark             show:esp_name_enabled];
    [self animateCheckmark:_nameOutlineCheckmark      show:esp_name_outline];
    [self animateCheckmark:_healthCheckmark           show:esp_health_enabled];
    [self animateCheckmark:_healthBarCheckmark        show:esp_health_bar_enabled];
    [self animateCheckmark:_healthBarOutlineCheckmark show:esp_health_bar_outline];
    [self animateCheckmark:_weaponCheckmark           show:esp_weapon_enabled];
    [self animateCheckmark:_weaponIconCheckmark       show:esp_weapon_icon_enabled];
    [self animateCheckmark:_platformCheckmark         show:esp_platform_enabled];
    [self animateCheckmark:_avatarCheckmark           show:esp_avatar_enabled];
    [self animateCheckmark:_aimbotCheckmark           show:aimbot_enabled];
    [self animateCheckmark:_visibleCheckCheckmark     show:aimbot_visible_check];
    [self animateCheckmark:_shootingCheckCheckmark    show:aimbot_shooting_check];
    [self animateCheckmark:_knifeBotCheckmark         show:aimbot_knife_bot];
    [self animateCheckmark:_rcsCheckmark              show:esp_rcs_enabled];
    [self animateCheckmark:_triggerbotCheckmark       show:aimbot_triggerbot];
    [self animateCheckmark:_aimbotFovVisibleCheckmark show:aimbot_fov_visible];
    [self animateCheckmark:_aimbotTeamCheckmark       show:aimbot_team_check];
    [self animateCheckmark:_viewmodelCheckmark        show:viewmodel_enabled];
    [self animateCheckmark:_screenshotSafeCheckmark   show:esp_screenshot_safe];
    if (self.superview) [self.superview hideViewFromCapture:esp_screenshot_safe];
    else [self hideViewFromCapture:esp_screenshot_safe];
    _fovValueLabel.text          = [NSString stringWithFormat:@"%.0f", aimbot_fov];          _fovSlider.value = aimbot_fov;
    _smoothValueLabel.text       = [NSString stringWithFormat:@"%.1f", aimbot_smooth];        _smoothSlider.value = aimbot_smooth;
    _triggerDelayValueLabel.text = [NSString stringWithFormat:@"%.2f", aimbot_trigger_delay]; _triggerDelaySlider.value = aimbot_trigger_delay;
    _rcsHValueLabel.text         = [NSString stringWithFormat:@"%.1f", esp_rcs_h];            _rcsHSlider.value = esp_rcs_h;
    _rcsVValueLabel.text         = [NSString stringWithFormat:@"%.1f", esp_rcs_v];            _rcsVSlider.value = esp_rcs_v;
    _bhopValueLabel.text         = [NSString stringWithFormat:@"%d", esp_bhop_setting];       _bhopSlider.value = esp_bhop_setting;
    _viewmodelXValueLabel.text   = [NSString stringWithFormat:@"%.1f", viewmodel_x];          _viewmodelXSlider.value = viewmodel_x;
    _viewmodelYValueLabel.text   = [NSString stringWithFormat:@"%.1f", viewmodel_y];          _viewmodelYSlider.value = viewmodel_y;
    _viewmodelZValueLabel.text   = [NSString stringWithFormat:@"%.1f", viewmodel_z];          _viewmodelZSlider.value = viewmodel_z;
    if (_boneSelector) [_boneSelector reloadUI:aimbot_bone_index];
}

// ── Skins (brazilix) ──────────────────────────────────────────────────────────

static __attribute__((unused)) std::string readUnityString(uintptr_t str_ptr, task_t task) {
    if (!str_ptr) return "";
    int length = Read<int>(str_ptr + 0x10, task);
    if (length <= 0 || length > 256) return "";
    std::string result; result.reserve(length);
    for (int i = 0; i < length; i++) {
        char16_t c = Read<char16_t>(str_ptr + 0x14 + i*2, task);
        result += (c < 128) ? (char)c : '?';
    }
    return result;
}

- (void)refreshSkinList {
    static pid_t c_pid = 0; static task_t c_task = 0; static mach_vm_address_t c_base = 0;
    pid_t pid = get_pid_by_name("Standoff2");
    if (pid <= 0) { c_pid=0; c_task=0; c_base=0; return; }
    if (pid != c_pid || !c_task || !c_base) {
        c_task = get_task_by_pid(pid);
        if (c_task) c_base = get_image_base_address(c_task, "UnityFramework");
        c_pid = pid;
    }
    if (!c_task || !c_base) return;
    uintptr_t ti = Read<uintptr_t>(c_base + 148490880, c_task); if (!ti) return;
    uintptr_t pti = Read<uintptr_t>(ti + 0x58, c_task); if (!pti) return;
    uintptr_t sf = Read<uintptr_t>(pti + 0xB8, c_task);
    if (!sf || sf < 0x1000000) sf = Read<uintptr_t>(pti + 0xB0, c_task);
    if (!sf) return;
    uintptr_t inv = Read<uintptr_t>(sf, c_task); if (!inv) return;
    if (_skinContainer.hidden) return;
    _ownedSkinsInfo.clear();
    NSMutableArray *ownedLabels = [NSMutableArray array];
    for (UIView *v in [_skinContent subviews]) [v removeFromSuperview];
    CGFloat y = 4;
    [self addSectionHeader:@"YOUR INVENTORY" atY:y]; y+=26;
    if (_ownedSkinsInfo.empty()) {
        UILabel *e = [[UILabel alloc] initWithFrame:CGRectMake(10,y,_skinContent.bounds.size.width-20,30)];
        e.text = @"Inventory empty"; e.textColor = GRAY(80); e.font = [UIFont italicSystemFontOfSize:12];
        [_skinContent addSubview:e]; y+=40;
    } else {
        for (int i = 0; i < (int)_ownedSkinsInfo.size(); i++) {
            UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(10,y,_skinContent.bounds.size.width-20,30)];
            lbl.text = [NSString stringWithFormat:@"  %@", ownedLabels[i]];
            lbl.font = [UIFont systemFontOfSize:13]; lbl.textColor = GRAY(210);
            lbl.backgroundColor = (i==_selectedOwnedIdx) ? GRAY(50) : GRAY(30);
            lbl.layer.cornerRadius=4; lbl.layer.masksToBounds=YES; lbl.userInteractionEnabled=YES; lbl.tag=1000+i;
            [lbl addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(ownedSkinTapped:)]];
            [_skinContent addSubview:lbl]; y+=35;
        }
    }
    y+=10; [self addSectionHeader:@"SELECT REPLACEMENT" atY:y]; y+=26;
    if (_allSkinsList.empty()) {
        UILabel *e = [[UILabel alloc] initWithFrame:CGRectMake(10,y,_skinContent.bounds.size.width-20,30)];
        e.text = @"No replacement skins found"; e.textColor = GRAY(80);
        [_skinContent addSubview:e]; y+=40;
    } else {
        for (int i = 0; i < (int)_allSkinsList.size(); i++) {
            UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(10,y,_skinContent.bounds.size.width-20,30)];
            lbl.text = [NSString stringWithFormat:@"  %@", [NSString stringWithUTF8String:_allSkinsList[i].second.c_str()]];
            lbl.font=[UIFont systemFontOfSize:13]; lbl.textColor=GRAY(210);
            lbl.backgroundColor=(i==_selectedReplaceIdx)?GRAY(50):GRAY(30);
            lbl.layer.cornerRadius=4; lbl.layer.masksToBounds=YES; lbl.userInteractionEnabled=YES; lbl.tag=2000+i;
            [lbl addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(replaceSkinTapped:)]];
            [_skinContent addSubview:lbl]; y+=35;
        }
    }
    CGRect f=_skinContent.frame; f.size.height=y+10; _skinContent.frame=f;
}
- (void)ownedSkinTapped:(UITapGestureRecognizer *)g { _selectedOwnedIdx=(int)g.view.tag-1000; [self refreshSkinList]; [self tryApplySkinPair]; }
- (void)replaceSkinTapped:(UITapGestureRecognizer *)g { _selectedReplaceIdx=(int)g.view.tag-2000; [self refreshSkinList]; [self tryApplySkinPair]; }
- (void)tryApplySkinPair {
    if (_selectedOwnedIdx<0||_selectedOwnedIdx>=(int)_ownedSkinsInfo.size()) return;
    if (_selectedReplaceIdx<0||_selectedReplaceIdx>=(int)_allSkinsList.size()) return;
    uintptr_t skinPtr = _ownedSkinsInfo[_selectedOwnedIdx].second;
    int newId = _allSkinsList[_selectedReplaceIdx].first;
    pid_t pid = get_pid_by_name("Standoff2");
    if (pid>0) { task_t task=get_task_by_pid(pid); if (task) Write<int>(skinPtr+0x10, newId, task); }
}

// ── Scroll & gesture (brazilix) ───────────────────────────────────────────────

- (void)handleScrollPan:(UIPanGestureRecognizer *)g {
    UIView *target=nil;
    if (!_aimContainer.hidden)    target=_aimContent;
    else if (!_visualContainer.hidden) target=_visualContent;
    else if (!_playerContainer.hidden) target=_playerContent;
    else if (!_configContainer.hidden) target=_configContent;
    else if (!_skinContainer.hidden)   target=_skinContent;
    else if (!_otherContainer.hidden)  target=_otherContent;
    if (!target) return;
    if (g.state==UIGestureRecognizerStateBegan||g.state==UIGestureRecognizerStateChanged) {
        CGPoint tr=[g translationInView:_contentView];
        CGRect f=target.frame; f.origin.y+=tr.y;
        if (f.origin.y>0) f.origin.y=0;
        CGFloat minY=_contentView.frame.size.height-f.size.height; if (minY>0) minY=0;
        if (f.origin.y<minY) f.origin.y=minY;
        [CATransaction begin]; [CATransaction setDisableActions:YES];
        target.frame=f; [CATransaction commit];
        [g setTranslation:CGPointZero inView:_contentView];
    }
}
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)g shouldReceiveTouch:(UITouch *)t {
    UIView *v=t.view;
    while (v) { if ([v isKindOfClass:[CustomSegmentedControl class]]||[v isKindOfClass:[CustomSliderView class]]) return NO; v=v.superview; }
    return YES;
}
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)g shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)o { return YES; }
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)g { return YES; }

- (void)handlePan:(UIPanGestureRecognizer *)gesture {
    CGPoint pt=[gesture locationInView:self.superview];
    if (gesture.state==UIGestureRecognizerStateBegan) _initialTouchPoint=pt;
    else if (gesture.state==UIGestureRecognizerStateChanged) {
        self.center=CGPointMake(self.center.x+pt.x-_initialTouchPoint.x, self.center.y+pt.y-_initialTouchPoint.y);
        _initialTouchPoint=pt;
    }
}

- (void)didMoveToSuperview { [super didMoveToSuperview]; [self centerMenu]; }
- (void)centerMenu {
    if (self.superview)
        self.center=CGPointMake(self.superview.bounds.size.width/2, self.superview.bounds.size.height/2);
}
- (void)dealloc {
    [_gradLink invalidate]; _gradLink=nil;
    [_skinTimer invalidate]; _skinTimer=nil;
}

@end
