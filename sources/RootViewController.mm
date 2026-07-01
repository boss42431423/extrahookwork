//
//  RootViewController.mm
//  extrahook
//

#import <notify.h>

#import "HUDHelper.h"
#import "MainApplication.h"
#import "RootViewController.h"
#import "UIApplication+Private.h"
#import "../esp/drawing_view/obfusheader.h"

// ─── Цвета темы ───────────────────────────────────────────────────────────────
#define BG_COLOR       [UIColor colorWithRed:0.05 green:0.05 blue:0.09 alpha:1.0]
#define CARD_COLOR     [UIColor colorWithRed:0.09 green:0.09 blue:0.14 alpha:1.0]
#define ACCENT_ON      [UIColor colorWithRed:0.0  green:0.85 blue:0.40 alpha:1.0]
#define ACCENT_OFF     [UIColor colorWithRed:0.85 green:0.20 blue:0.20 alpha:1.0]
#define TEXT_PRIMARY   [UIColor colorWithRed:0.95 green:0.95 blue:0.98 alpha:1.0]
#define TEXT_SECONDARY [UIColor colorWithRed:0.55 green:0.55 blue:0.65 alpha:1.0]
#define BORDER_COLOR   [UIColor colorWithRed:0.20 green:0.20 blue:0.28 alpha:1.0]

@implementation RootViewController {
    UIButton    *_mainButton;
    UIView      *_statusDot;
    UILabel     *_statusLabel;
    UILabel     *_titleLabel;
    UILabel     *_subtitleLabel;
    UILabel     *_versionLabel;
    UIView      *_cardView;
    UIView      *_glowView;
    UIImageView *_iconImageView;
    CALayer     *_glowLayer;
    BOOL         _isActive;
}

// ─── HUD helpers ──────────────────────────────────────────────────────────────
- (BOOL)isHUDEnabled  { return IsHUDEnabled(); }
- (void)setHUDEnabled:(BOOL)enabled { SetHUDEnabled(enabled); }

// ─── Верхний градиентный accent-strip ────────────────────────────────────────
- (CAGradientLayer *)makeAccentGradient {
    CAGradientLayer *g = [CAGradientLayer layer];
    g.colors = @[
        (id)[UIColor colorWithRed:0.0 green:0.85 blue:0.40 alpha:0.25].CGColor,
        (id)[UIColor colorWithRed:0.0 green:0.45 blue:0.90 alpha:0.10].CGColor,
        (id)[UIColor clearColor].CGColor
    ];
    g.locations = @[@0.0, @0.5, @1.0];
    g.startPoint = CGPointMake(0.5, 0.0);
    g.endPoint   = CGPointMake(0.5, 1.0);
    return g;
}

// ─── loadView ─────────────────────────────────────────────────────────────────
- (void)loadView {
    CGRect bounds = UIScreen.mainScreen.bounds;

    // Фон
    self.view = [[UIView alloc] initWithFrame:bounds];
    self.view.backgroundColor = BG_COLOR;

    self.backgroundView = [[UIView alloc] initWithFrame:bounds];
    self.backgroundView.autoresizingMask =
        UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.backgroundView.backgroundColor = BG_COLOR;
    [self.view addSubview:self.backgroundView];

    // Верхний accent-градиент
    CAGradientLayer *topGlow = [self makeAccentGradient];
    topGlow.frame = CGRectMake(0, 0, bounds.size.width, bounds.size.height * 0.45);
    [self.backgroundView.layer insertSublayer:topGlow atIndex:0];

    // ── Иконка ──────────────────────────────────────────────────────────────
    _iconImageView = [[UIImageView alloc] init];
    _iconImageView.contentMode = UIViewContentModeScaleAspectFit;
    _iconImageView.image = [UIImage imageNamed:@"icon.png"];
    _iconImageView.layer.cornerRadius = 22.0f;
    _iconImageView.layer.masksToBounds = YES;
    _iconImageView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.backgroundView addSubview:_iconImageView];

    // ── Название ────────────────────────────────────────────────────────────
    _titleLabel = [[UILabel alloc] init];
    _titleLabel.text = @"EXTRAHOOK";
    _titleLabel.textColor = TEXT_PRIMARY;
    _titleLabel.font = [UIFont systemFontOfSize:26.0f weight:UIFontWeightBold];
    _titleLabel.textAlignment = NSTextAlignmentCenter;
    _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.backgroundView addSubview:_titleLabel];

    // ── Подзаголовок ────────────────────────────────────────────────────────
    _subtitleLabel = [[UILabel alloc] init];
    _subtitleLabel.text = @"Standoff 2 • ESP";
    _subtitleLabel.textColor = TEXT_SECONDARY;
    _subtitleLabel.font = [UIFont systemFontOfSize:13.0f weight:UIFontWeightMedium];
    _subtitleLabel.textAlignment = NSTextAlignmentCenter;
    _subtitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.backgroundView addSubview:_subtitleLabel];

    // ── Карточка кнопки ─────────────────────────────────────────────────────
    _cardView = [[UIView alloc] init];
    _cardView.backgroundColor = CARD_COLOR;
    _cardView.layer.cornerRadius = 24.0f;
    _cardView.layer.borderWidth  = 1.0f;
    _cardView.layer.borderColor  = BORDER_COLOR.CGColor;
    _cardView.translatesAutoresizingMaskIntoConstraints = NO;

    // Тень карточки
    _cardView.layer.shadowColor   = [UIColor blackColor].CGColor;
    _cardView.layer.shadowOffset  = CGSizeMake(0, 8);
    _cardView.layer.shadowOpacity = 0.5f;
    _cardView.layer.shadowRadius  = 20.0f;
    [self.backgroundView addSubview:_cardView];

    // Glow под кнопкой
    _glowView = [[UIView alloc] init];
    _glowView.backgroundColor = [UIColor clearColor];
    _glowView.translatesAutoresizingMaskIntoConstraints = NO;
    [_cardView addSubview:_glowView];

    // ── Главная кнопка ──────────────────────────────────────────────────────
    _mainButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _mainButton.layer.cornerRadius = 16.0f;
    _mainButton.layer.masksToBounds = YES;
    _mainButton.translatesAutoresizingMaskIntoConstraints = NO;
    [_mainButton addTarget:self
                   action:@selector(tapMainButton:)
         forControlEvents:UIControlEventTouchUpInside];
    [_cardView addSubview:_mainButton];

    // ── Статус-индикатор ────────────────────────────────────────────────────
    _statusDot = [[UIView alloc] init];
    _statusDot.layer.cornerRadius = 5.0f;
    _statusDot.translatesAutoresizingMaskIntoConstraints = NO;
    [_cardView addSubview:_statusDot];

    _statusLabel = [[UILabel alloc] init];
    _statusLabel.font = [UIFont systemFontOfSize:13.0f weight:UIFontWeightSemibold];
    _statusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [_cardView addSubview:_statusLabel];

    // ── Версия iOS ──────────────────────────────────────────────────────────
    _versionLabel = [[UILabel alloc] init];
    _versionLabel.text = [NSString stringWithFormat:@"iOS %@",
                          [UIDevice currentDevice].systemVersion];
    _versionLabel.textColor = TEXT_SECONDARY;
    _versionLabel.font = [UIFont systemFontOfSize:12.0f weight:UIFontWeightRegular];
    _versionLabel.textAlignment = NSTextAlignmentCenter;
    _versionLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.backgroundView addSubview:_versionLabel];

    // ── Нижний тег ──────────────────────────────────────────────────────────
    UILabel *tagLabel = [[UILabel alloc] init];
    tagLabel.text = @"extrahook";
    tagLabel.textColor = [UIColor colorWithRed:0.35 green:0.35 blue:0.45 alpha:1.0];
    tagLabel.font = [UIFont systemFontOfSize:11.0f weight:UIFontWeightLight];
    tagLabel.textAlignment = NSTextAlignmentCenter;
    tagLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.backgroundView addSubview:tagLabel];

    // ── Разделительные линии в карточке ─────────────────────────────────────
    UIView *divider = [[UIView alloc] init];
    divider.backgroundColor = BORDER_COLOR;
    divider.translatesAutoresizingMaskIntoConstraints = NO;
    [_cardView addSubview:divider];

    // ── Auto Layout ─────────────────────────────────────────────────────────
    UILayoutGuide *safe = self.backgroundView.safeAreaLayoutGuide;

    [NSLayoutConstraint activateConstraints:@[
        // Иконка
        [_iconImageView.centerXAnchor constraintEqualToAnchor:safe.centerXAnchor],
        [_iconImageView.topAnchor constraintEqualToAnchor:safe.topAnchor constant:48.0f],
        [_iconImageView.widthAnchor  constraintEqualToConstant:84.0f],
        [_iconImageView.heightAnchor constraintEqualToConstant:84.0f],

        // Название
        [_titleLabel.centerXAnchor constraintEqualToAnchor:safe.centerXAnchor],
        [_titleLabel.topAnchor constraintEqualToAnchor:_iconImageView.bottomAnchor constant:16.0f],

        // Подзаголовок
        [_subtitleLabel.centerXAnchor constraintEqualToAnchor:safe.centerXAnchor],
        [_subtitleLabel.topAnchor constraintEqualToAnchor:_titleLabel.bottomAnchor constant:4.0f],

        // Карточка
        [_cardView.centerXAnchor constraintEqualToAnchor:safe.centerXAnchor],
        [_cardView.topAnchor constraintEqualToAnchor:_subtitleLabel.bottomAnchor constant:36.0f],
        [_cardView.widthAnchor constraintEqualToConstant:280.0f],

        // Glow (внутри карточки, за кнопкой)
        [_glowView.centerXAnchor constraintEqualToAnchor:_cardView.centerXAnchor],
        [_glowView.topAnchor constraintEqualToAnchor:_cardView.topAnchor constant:20.0f],
        [_glowView.widthAnchor  constraintEqualToConstant:220.0f],
        [_glowView.heightAnchor constraintEqualToConstant:64.0f],

        // Кнопка
        [_mainButton.centerXAnchor constraintEqualToAnchor:_cardView.centerXAnchor],
        [_mainButton.topAnchor constraintEqualToAnchor:_cardView.topAnchor constant:20.0f],
        [_mainButton.widthAnchor  constraintEqualToConstant:220.0f],
        [_mainButton.heightAnchor constraintEqualToConstant:56.0f],

        // Разделитель
        [divider.topAnchor constraintEqualToAnchor:_mainButton.bottomAnchor constant:16.0f],
        [divider.leadingAnchor constraintEqualToAnchor:_cardView.leadingAnchor constant:20.0f],
        [divider.trailingAnchor constraintEqualToAnchor:_cardView.trailingAnchor constant:-20.0f],
        [divider.heightAnchor constraintEqualToConstant:0.5f],

        // Статус-точка
        [_statusDot.widthAnchor  constraintEqualToConstant:10.0f],
        [_statusDot.heightAnchor constraintEqualToConstant:10.0f],
        [_statusDot.leadingAnchor constraintEqualToAnchor:_cardView.leadingAnchor constant:24.0f],
        [_statusDot.topAnchor constraintEqualToAnchor:divider.bottomAnchor constant:14.0f],

        // Статус-текст
        [_statusLabel.centerYAnchor constraintEqualToAnchor:_statusDot.centerYAnchor],
        [_statusLabel.leadingAnchor constraintEqualToAnchor:_statusDot.trailingAnchor constant:8.0f],

        // Нижняя граница карточки
        [_cardView.bottomAnchor constraintEqualToAnchor:_statusDot.bottomAnchor constant:18.0f],

        // Версия
        [_versionLabel.centerXAnchor constraintEqualToAnchor:safe.centerXAnchor],
        [_versionLabel.topAnchor constraintEqualToAnchor:_cardView.bottomAnchor constant:20.0f],

        // Тег
        [tagLabel.centerXAnchor constraintEqualToAnchor:safe.centerXAnchor],
        [tagLabel.bottomAnchor constraintEqualToAnchor:safe.bottomAnchor constant:-16.0f],
    ]];

    [self reloadMainButtonState];
}

// ─── Обновление внешнего вида кнопки ─────────────────────────────────────────
- (void)reloadMainButtonState {
    _isActive = [self isHUDEnabled];

    // Цвет кнопки
    UIColor *accentColor = _isActive ? ACCENT_ON : ACCENT_OFF;

    // Градиент кнопки
    CAGradientLayer *btnGrad = nil;
    for (CALayer *l in _mainButton.layer.sublayers) {
        if ([l isKindOfClass:[CAGradientLayer class]]) {
            btnGrad = (CAGradientLayer *)l;
            break;
        }
    }
    if (!btnGrad) {
        btnGrad = [CAGradientLayer layer];
        btnGrad.startPoint = CGPointMake(0, 0.5);
        btnGrad.endPoint   = CGPointMake(1, 0.5);
        [_mainButton.layer insertSublayer:btnGrad atIndex:0];
    }

    UIColor *colorA, *colorB;
    if (_isActive) {
        colorA = [UIColor colorWithRed:0.0  green:0.75 blue:0.35 alpha:1.0];
        colorB = [UIColor colorWithRed:0.0  green:0.50 blue:0.70 alpha:1.0];
    } else {
        colorA = [UIColor colorWithRed:0.80 green:0.15 blue:0.15 alpha:1.0];
        colorB = [UIColor colorWithRed:0.55 green:0.05 blue:0.35 alpha:1.0];
    }
    btnGrad.colors = @[(id)colorA.CGColor, (id)colorB.CGColor];
    btnGrad.frame  = CGRectMake(0, 0, 220.0f, 56.0f);

    // Текст и шрифт кнопки
    NSString *btnTitle = _isActive ? @"◼  STOP" : @"▶  INJECT";
    NSAttributedString *attrTitle = [[NSAttributedString alloc]
        initWithString:btnTitle
            attributes:@{
                NSFontAttributeName: [UIFont systemFontOfSize:17.0f weight:UIFontWeightBold],
                NSForegroundColorAttributeName: [UIColor whiteColor],
                NSKernAttributeName: @1.5
            }];
    [_mainButton setAttributedTitle:attrTitle forState:UIControlStateNormal];

    // Статус-точка
    _statusDot.backgroundColor = accentColor;
    _statusLabel.text      = _isActive ? @"Active" : @"Inactive";
    _statusLabel.textColor = accentColor;

    // Glow эффект
    [_glowLayer removeFromSuperlayer];
    _glowLayer = [CALayer layer];
    _glowLayer.frame       = CGRectIsEmpty(_glowView.bounds)
                             ? CGRectMake(0, 0, 220, 64)
                             : _glowView.bounds;
    _glowLayer.cornerRadius = 16.0f;
    _glowLayer.backgroundColor = [UIColor clearColor].CGColor;
    _glowLayer.shadowColor  = accentColor.CGColor;
    _glowLayer.shadowOffset = CGSizeZero;
    _glowLayer.shadowRadius = _isActive ? 18.0f : 6.0f;
    _glowLayer.shadowOpacity = _isActive ? 0.7f : 0.25f;
    [_glowView.layer addSublayer:_glowLayer];

    // Анимация пульса когда активен
    [_glowLayer removeAnimationForKey:@"pulse"];
    if (_isActive) {
        CABasicAnimation *pulse = [CABasicAnimation animationWithKeyPath:@"shadowRadius"];
        pulse.fromValue  = @10.0;
        pulse.toValue    = @24.0;
        pulse.duration   = 1.4;
        pulse.autoreverses = YES;
        pulse.repeatCount  = HUGE_VALF;
        pulse.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        [_glowLayer addAnimation:pulse forKey:@"pulse"];
    }

    // Иконка пульс
    [_iconImageView.layer removeAnimationForKey:@"iconPulse"];
    if (_isActive) {
        CABasicAnimation *iconPulse = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
        iconPulse.fromValue    = @1.0;
        iconPulse.toValue      = @1.06;
        iconPulse.duration     = 1.4;
        iconPulse.autoreverses = YES;
        iconPulse.repeatCount  = HUGE_VALF;
        iconPulse.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        [_iconImageView.layer addAnimation:iconPulse forKey:@"iconPulse"];
    }
}

// ─── Нажатие кнопки ───────────────────────────────────────────────────────────
- (void)tapMainButton:(UIButton *)sender {
    // Haptic feedback
    UIImpactFeedbackGenerator *haptic = [[UIImpactFeedbackGenerator alloc]
        initWithStyle:UIImpactFeedbackStyleMedium];
    [haptic prepare];
    [haptic impactOccurred];

    // Анимация нажатия
    [UIView animateWithDuration:0.08 animations:^{
        sender.transform = CGAffineTransformMakeScale(0.95, 0.95);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.12 animations:^{
            sender.transform = CGAffineTransformIdentity;
        }];
    }];

    BOOL isNowEnabled = [self isHUDEnabled];
    [self setHUDEnabled:!isNowEnabled];

    NSTimeInterval delay = 0.5;
    dispatch_queue_t q = isNowEnabled
        ? dispatch_get_main_queue()
        : dispatch_get_global_queue(QOS_CLASS_UTILITY, 0);

    [self.backgroundView setUserInteractionEnabled:NO];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), q, ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [self reloadMainButtonState];
            [self.backgroundView setUserInteractionEnabled:YES];
        });
    });
}

// ─── Прочее ───────────────────────────────────────────────────────────────────
- (void)viewDidLoad    { [super viewDidLoad]; }
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    // обновить glow после того как авто-лейаут выставит финальные размеры
    [self reloadMainButtonState];

    static dispatch_once_t once;
    dispatch_once(&once, ^{
        NSString *urlStr = @(OBF("https://extrahook"));
        NSURL *url = [NSURL URLWithString:urlStr];
        [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
    });
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    // Обновить frame градиента кнопки после layout
    for (CALayer *l in _mainButton.layer.sublayers) {
        if ([l isKindOfClass:[CAGradientLayer class]]) {
            l.frame = _mainButton.bounds;
        }
    }
}

- (void)traitCollectionDidChange:(UITraitCollection *)prev {
    [super traitCollectionDidChange:prev];
}

@end
