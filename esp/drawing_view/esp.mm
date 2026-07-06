#import "esp.h"
#import "tt.h"
#import <UIKit/UIGestureRecognizerSubclass.h>
#import <AVFoundation/AVFoundation.h>
#import <objc/runtime.h>
#import <sys/sysctl.h>
#include "obfusheader.h"
#import "../../sources/UIView+SecureView.h"
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
volatile bool esp_skeleton_enabled = true;
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
@property (nonatomic, strong) CAShapeLayer      *espSkeletonLayer;
@property (nonatomic, strong) UILabel           *watermarkLabel;
@property (nonatomic, strong) CAShapeLayer      *fovCircleLayer;
@property (nonatomic, strong) CAShapeLayer      *fovCircleOutlineLayer;
@property (nonatomic, assign) uint64_t          aimbotCurrentTarget;
@property (nonatomic, assign) double            aimbotLastWriteTime;
@property (nonatomic, assign) BOOL              triggerbotShooting;
@property (nonatomic, assign) double            triggerbotLastShotTime;
@property (nonatomic, assign) BOOL              isESPCountEnabled;
@end

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
    self.espBoxLayer.strokeColor = [UIColor whiteColor].CGColor;
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
    self.espLineLayer.strokeColor = [UIColor whiteColor].CGColor;
    self.espLineLayer.fillColor   = [UIColor clearColor].CGColor;
    self.espLineLayer.lineWidth   = 1.0;
    [self.layer addSublayer:self.espLineLayer];

    self.espSkeletonLayer = [CAShapeLayer layer];
    self.espSkeletonLayer.strokeColor = [UIColor greenColor].CGColor;
    self.espSkeletonLayer.fillColor   = [UIColor clearColor].CGColor;
    self.espSkeletonLayer.lineWidth   = 2.0;
    self.espSkeletonLayer.zPosition   = 100;
    [self.layer addSublayer:self.espSkeletonLayer];

    self.fovCircleOutlineLayer = [CAShapeLayer layer];
    self.fovCircleOutlineLayer.fillColor   = [UIColor clearColor].CGColor;
    self.fovCircleOutlineLayer.strokeColor = [UIColor colorWithWhite:0 alpha:0.6].CGColor;
    self.fovCircleOutlineLayer.lineWidth   = 3.0;
    self.fovCircleOutlineLayer.hidden      = YES;
    [self.layer addSublayer:self.fovCircleOutlineLayer];

    self.fovCircleLayer = [CAShapeLayer layer];
    self.fovCircleLayer.fillColor   = [UIColor clearColor].CGColor;
    self.fovCircleLayer.strokeColor = [UIColor whiteColor].CGColor;
    self.fovCircleLayer.lineWidth   = 1.5;
    self.fovCircleLayer.hidden      = YES;
    [self.layer addSublayer:self.fovCircleLayer];

    UILabel *wm = [[UILabel alloc] init];
    wm.text = @"";
    wm.hidden = YES;
    wm.userInteractionEnabled = NO;
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

    self.menuView = [[MenuView alloc] initWithFrame:CGRectMake(0, 0, 270, 280)];
    self.menuView.center = CGPointMake(frame.size.width / 2, frame.size.height / 2);
    [self addSubview:self.menuView];

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
    if (self.menuView) {
        CGPoint pointInMenu = [self convertPoint:point toView:self.menuView];
        if ([self.menuView pointInside:pointInMenu withEvent:event]) {
            return [self.menuView hitTest:pointInMenu withEvent:event];
        }
    }
    return nil;
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
    self.espSkeletonLayer.path        = nil;
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
    if (!esp_box_enabled && !esp_box_3d && !esp_box_corner && !esp_line_enabled && !esp_name_enabled && !esp_health_enabled && !esp_health_bar_enabled && !esp_weapon_enabled && !esp_skeleton_enabled) {
        [self clearAllBoxes];
        self.watermarkLabel.text = @(OBF("t.me/projectios"));
        [self.watermarkLabel sizeToFit];
        return;
    }

    static pid_t cached_so2_pid = 0;
    static task_t cached_so2_task = 0;
    static mach_vm_address_t cached_unity_base = 0;
    static std::atomic<bool>     s_pm_scanning{false};
    static std::atomic<pid_t>    s_pm_scanned_pid{0};

    pid_t so2_pid = get_pid_by_name("Standoff2");

    if (so2_pid <= 0) {
        cached_so2_pid = 0;
        cached_so2_task = 0;
        cached_unity_base = 0;

        [self clearAllBoxes];

        self.playerCountLabel.text      = @"DBG: PID NOT FOUND (Standoff2)";
        self.playerCountLabel.textColor = [UIColor redColor];
        self.playerCountLabel.hidden    = NO;
        self.noPlayersLabel.hidden      = YES;
        self.watermarkLabel.text = @"DBG: game not detected";
        [self.watermarkLabel sizeToFit];

        if (!self.hasAttemptedLaunch) {
            [self launchGame];
            self.hasAttemptedLaunch = YES;
        }
        return;
    }

    if (so2_pid != cached_so2_pid || !cached_so2_task || !cached_unity_base) {
        // Try processor_set_tasks first, fall back to task_for_pid
        cached_so2_task = get_task_by_pid(so2_pid);
        if (!cached_so2_task || cached_so2_task == MACH_PORT_NULL)
            cached_so2_task = get_task_for_PID(so2_pid);

        if (cached_so2_task && cached_so2_task != MACH_PORT_NULL)
            cached_unity_base = get_image_base_address(cached_so2_task, "UnityFramework");

        cached_so2_pid = so2_pid;
        s_pm_scanned_pid = 0;
    }

    // Фоновый скан — запускаем сразу при новом PID
    if (cached_unity_base && cached_so2_task && !s_pm_scanning && get_scan_phase() != 2) {
        if (s_pm_scanned_pid != so2_pid || get_scan_phase() == -1) {
            s_pm_scanning    = true;
            s_pm_scanned_pid = so2_pid;
            task_t           scan_task = cached_so2_task;
            mach_vm_address_t scan_base = cached_unity_base;
            dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
                find_pm_typeinfo_offset(scan_task, scan_base);
                s_pm_scanning = false;
            });
        }
    }

    task_t so2_task = cached_so2_task;
    if (!so2_task) {
        self.watermarkLabel.text = [NSString stringWithFormat:@"DBG: no task (pid=%d)", so2_pid];
        goto CLEAR_BOXES;
    }

    {
        mach_vm_address_t unity_base = cached_unity_base;
        if (!unity_base) {
            self.watermarkLabel.text = @"DBG: no UnityFramework base";
            goto CLEAR_BOXES;
        }

        mach_vm_address_t typeInfo       = 0, staticFields  = 0;
        mach_vm_address_t playerManager  = 0, playersDict   = 0;
        mach_vm_address_t parentTypeInfo = 0;
        mach_vm_address_t dict28         = 0;
        int playersCount = 0, c18 = 0, c20 = 0, c40 = 0;
        static int cam_off_cache = -1, cam_p1_cache = -1, cam_p2_cache = -1, cam_m_cache = -1;
        static pid_t cached_chain_pid = 0;
        if (cached_chain_pid != so2_pid) {
            cached_chain_pid = so2_pid;
            cam_off_cache = -1;
        }

        // Ждём результат сканера
        if (get_scan_phase() != 2) {
            if (s_pm_scanning) {
                self.watermarkLabel.text = [NSString stringWithFormat:
                    @"SCANNING %llu/%llu...", get_scan_progress(), get_scan_total()];
            } else {
                self.watermarkLabel.text = @"Waiting...";
            }
            goto CLEAR_BOXES;
        }

        // Как в старой рабочей версии: typeInfo → parent(+0x58) → staticFields(+0xB8/+0xB0) → PM(+0x0)
        typeInfo = (mach_vm_address_t)get_found_class();
        if (!typeInfo || typeInfo < 0x1000000) goto CLEAR_BOXES;

        parentTypeInfo = Read<mach_vm_address_t>(typeInfo + 0x58, so2_task);
        if (parentTypeInfo > 0x1000000) {
            staticFields = Read<mach_vm_address_t>(parentTypeInfo + 0xB8, so2_task);
            if (!staticFields || staticFields < 0x1000000)
                staticFields = Read<mach_vm_address_t>(parentTypeInfo + 0xB0, so2_task);
        }
        if (!staticFields || staticFields < 0x1000000) {
            staticFields = Read<mach_vm_address_t>(typeInfo + 0xB8, so2_task);
            if (!staticFields || staticFields < 0x1000000)
                staticFields = Read<mach_vm_address_t>(typeInfo + 0xB0, so2_task);
        }
        if (!staticFields || staticFields < 0x1000000) goto CLEAR_BOXES;

        playerManager = Read<mach_vm_address_t>(staticFields + 0x0, so2_task);
        if (!playerManager || playerManager < 0x1000000) goto CLEAR_BOXES;

        dict28      = Read<mach_vm_address_t>(playerManager + 0x28, so2_task);
        playersDict = dict28;

        c20 = Read<int>(playersDict + 0x20, so2_task);
        c40 = Read<int>(playersDict + 0x40, so2_task);
        c18 = Read<int>(playersDict + 0x18, so2_task);

        if      (c20 > 0 && c20 <= 32) playersCount = c20;
        else if (c40 > 0 && c40 <= 32) playersCount = c40;
        else if (c18 > 0 && c18 <= 32) playersCount = c18;

        if (playersCount > 0 && playersCount <= 32) {
            mach_vm_address_t localPlayer = Read<mach_vm_address_t>(playerManager + 0x70, so2_task);
            if (localPlayer < 0x1000000 || Read<mach_vm_address_t>(localPlayer + 0xE0, so2_task) == 0)
                localPlayer = Read<mach_vm_address_t>(playerManager + 0x68, so2_task);


            // Не сбрасываем кэш камеры при смене localPlayer — цепочка 0xE8 проверяется каждый кадр

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
                        // v0.39.1: AmmoInMagazine=+0xA0, AmmoReserve=+0xA4 (plain int)
                        Write<int32_t>(ctrl + 0xA0, 999, so2_task);
                        Write<int32_t>(ctrl + 0xA4, 999, so2_task);
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
                        // v0.39.1: detect melee via SlotIndex byte at WeaponController+0x94 (slot 2 = melee)
                        uint8_t weaponSlot = Read<uint8_t>(ctrl + 0x94, so2_task);
                        if (weaponSlot == 2) {
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
                        // v0.39.1: FireRate field at +0x80 (float)
                        Write<float>(ctrl + 0x80, 0.001f, so2_task);
                    }
                }
            }

            SO2_Matrix viewMatrix = {0};
            bool matrixFound = false;
            static int last_good_cam = -1, last_good_p1 = -1, last_good_p2 = -1, last_good_m = -1;
            CGFloat sw = self.bounds.size.width, sh = self.bounds.size.height;

            // Собрать позиции нескольких врагов для валидации
            Vector3 valPositions[3] = {{0,0,0},{0,0,0},{0,0,0}};
            int valCount = 0;
            {
                mach_vm_address_t tdict = Read<mach_vm_address_t>(playerManager + 0x28, so2_task);
                if (tdict > 0x1000000) {
                    mach_vm_address_t tarr = Read<mach_vm_address_t>(tdict + 0x18, so2_task);
                    if (tarr > 0x1000000) {
                        for (int ti = 0; ti < 10 && valCount < 3; ti++) {
                            mach_vm_address_t tp = Read<mach_vm_address_t>(tarr + 0x20 + ti * 0x18 + 0x10, so2_task);
                            if (tp < 0x1000000 || tp == localPlayer) continue;
                            mach_vm_address_t mc = Read<mach_vm_address_t>(tp + 0x98, so2_task);
                            if (mc < 0x1000000) continue;
                            mach_vm_address_t md = Read<mach_vm_address_t>(mc + 0xB0, so2_task);
                            if (md < 0x1000000) continue;
                            Vector3 vp = Read<Vector3>(md + 0x44, so2_task);
                            if (vp.x != 0 || vp.y != 0 || vp.z != 0) {
                                valPositions[valCount++] = vp;
                            }
                        }
                    }
                }
            }

            auto validateMatrix = [&](SO2_Matrix &m) -> bool {
                if (fabsf(m.m11) < 0.001f || fabsf(m.m22) < 0.001f || fabsf(m.m33) < 0.001f) return false;
                if (fabsf(m.m11) > 100.0f || fabsf(m.m22) > 100.0f || fabsf(m.m33) > 100.0f) return false;
                float det = m.m11 * (m.m22 * m.m33 - m.m23 * m.m32)
                          - m.m12 * (m.m21 * m.m33 - m.m23 * m.m31)
                          + m.m13 * (m.m21 * m.m32 - m.m22 * m.m31);
                if (fabsf(det) < 0.0001f) return false;
                return true;
            };

            // Приоритет 1: известная рабочая цепочка 0xE8→0x20→0x10→0xF0
            if (localPlayer > 0x1000000 && !matrixFound) {
                mach_vm_address_t v1 = Read<mach_vm_address_t>(localPlayer + 0xE8, so2_task);
                if (v1 > 0x1000000) {
                    mach_vm_address_t v2 = Read<mach_vm_address_t>(v1 + 0x20, so2_task);
                    if (v2 > 0x1000000) {
                        mach_vm_address_t v3 = Read<mach_vm_address_t>(v2 + 0x10, so2_task);
                        if (v3 > 0x1000000) {
                            SO2_Matrix m = Read<SO2_Matrix>(v3 + 0xF0, so2_task);
                            if (validateMatrix(m)) {
                                viewMatrix = m;
                                matrixFound = true;
                                cam_off_cache = 0xE8;
                                cam_p1_cache = 0x20;
                                cam_p2_cache = 0x10;
                                cam_m_cache = 0xF0;
                            }
                        }
                    }
                }
            }

            // Приоритет 2: кэшированная цепочка (если отличается от основной)
            if (localPlayer > 0x1000000 && !matrixFound && cam_off_cache >= 0) {
                mach_vm_address_t v1 = Read<mach_vm_address_t>(localPlayer + cam_off_cache, so2_task);
                if (v1 > 0x1000000) {
                    mach_vm_address_t v2 = Read<mach_vm_address_t>(v1 + cam_p1_cache, so2_task);
                    if (v2 > 0x1000000) {
                        mach_vm_address_t v3 = Read<mach_vm_address_t>(v2 + cam_p2_cache, so2_task);
                        if (v3 > 0x1000000) {
                            SO2_Matrix m = Read<SO2_Matrix>(v3 + cam_m_cache, so2_task);
                            if (validateMatrix(m)) {
                                viewMatrix = m;
                                matrixFound = true;
                            }
                        }
                    }
                }
                if (!matrixFound) cam_off_cache = -1;
            }

            // Приоритет 3: полный скан (только если есть враги для валидации)
            if (localPlayer > 0x1000000 && !matrixFound && valCount > 0) {
                int camOffs[] = {0xE8, 0xE0, 0xF0, 0xD8, 0xD0};
                int p1s[] = {0x20, 0x18, 0x28, 0x10};
                int p2s[] = {0x10, 0x18, 0x08};
                int moffs[] = {0x100, 0xF0, 0xE0, 0xD0, 0xC0};

                for (int ci = 0; ci < 5 && !matrixFound; ci++) {
                    mach_vm_address_t v1 = Read<mach_vm_address_t>(localPlayer + camOffs[ci], so2_task);
                    if (v1 < 0x1000000) continue;
                    for (int pi = 0; pi < 4 && !matrixFound; pi++) {
                        mach_vm_address_t v2 = Read<mach_vm_address_t>(v1 + p1s[pi], so2_task);
                        if (v2 < 0x1000000) continue;
                        for (int qi = 0; qi < 3 && !matrixFound; qi++) {
                            mach_vm_address_t v3 = Read<mach_vm_address_t>(v2 + p2s[qi], so2_task);
                            if (v3 < 0x1000000) continue;
                            for (int mi = 0; mi < 5 && !matrixFound; mi++) {
                                SO2_Matrix m = Read<SO2_Matrix>(v3 + moffs[mi], so2_task);
                                if (validateMatrix(m)) {
                                    viewMatrix = m;
                                    matrixFound = true;
                                    cam_off_cache = camOffs[ci];
                                    cam_p1_cache = p1s[pi];
                                    cam_p2_cache = p2s[qi];
                                    cam_m_cache = moffs[mi];
                                }
                            }
                        }
                    }
                }
            }

            if (!matrixFound) goto CLEAR_BOXES;

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

            if (!drawBoxes && !drawLines && !esp_name_enabled && !esp_health_enabled && !esp_health_bar_enabled && !esp_weapon_enabled && !esp_weapon_icon_enabled && !esp_platform_enabled && !esp_skeleton_enabled) {
                [self clearAllBoxes];
                self.watermarkLabel.text = @"t.me/projectios";
                [self.watermarkLabel sizeToFit];
                return;
            }

            self.watermarkLabel.text = @"t.me/projectios";

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
            UIBezierPath *skeletonPath    = [UIBezierPath bezierPath];

            // Direct read: PlayerController+0x79 → team byte (новые офсеты)
            int localTeam = 0;
            if (esp_team_check) {
                localTeam = (int)Read<uint8_t>(localPlayer + 0x79, so2_task);
            }
            mach_vm_address_t *players = (mach_vm_address_t *)malloc(capacity * sizeof(mach_vm_address_t));
            for (int i = 0; i < capacity; i++) {
                players[i] = Read<mach_vm_address_t>(entries_arr + 0x20 + (i * 0x18) + 0x10, so2_task);
            }

            // HP: пока не найден способ чтения, отключаем поиск

            for (int i = 0; i < capacity; i++) {
                mach_vm_address_t player = players[i];
                if (player < 0x1000000 || player == localPlayer) continue;

                if (esp_team_check) {
                    if (GetPlayerTeamAim(player, so2_task) == localTeam) continue;
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
                                // v0.39.1: weapon name is a direct string field at WeaponController+0x98
                                mach_vm_address_t namePtr = Read<mach_vm_address_t>(ctrl + 0x98, so2_task);
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

                    if (esp_skeleton_enabled) {
                        mach_vm_address_t bm = FindBipedMapCached(player, so2_task);
                        if (bm) {
                            int boneOffsets[] = {
                                0x20, 0x28, 0x40, 0x88,
                                0x48, 0x50, 0x58, 0x60,
                                0x68, 0x70, 0x78, 0x80,
                                0x90, 0x98, 0xA0,
                                0xB0, 0xB8, 0xC0
                            };
                            Vector3 bones[18];
                            int validCount = 0;
                            for (int bi = 0; bi < 18; bi++) {
                                bones[bi] = GetBoneWorldPos(bm, boneOffsets[bi], so2_task);
                                if (bones[bi].x != 0 || bones[bi].y != 0 || bones[bi].z != 0) validCount++;
                            }
                            if (validCount >= 6) {
                                int skelLinks[][2] = {
                                    {0,1},{1,2},{2,3},
                                    {1,4},{4,5},{5,6},{6,7},
                                    {1,8},{8,9},{9,10},{10,11},
                                    {3,12},{12,13},{13,14},
                                    {3,15},{15,16},{16,17},
                                };
                                for (int li = 0; li < 17; li++) {
                                    Vector3 b1 = bones[skelLinks[li][0]];
                                    Vector3 b2 = bones[skelLinks[li][1]];
                                    if ((b1.x == 0 && b1.y == 0 && b1.z == 0) ||
                                        (b2.x == 0 && b2.y == 0 && b2.z == 0)) continue;
                                    Vector3 s1 = WorldToScreen(b1, viewMatrix, w, h);
                                    Vector3 s2 = WorldToScreen(b2, viewMatrix, w, h);
                                    if (s1.z <= 0 || s2.z <= 0) continue;
                                    [skeletonPath moveToPoint:CGPointMake(s1.x, s1.y)];
                                    [skeletonPath addLineToPoint:CGPointMake(s2.x, s2.y)];
                                }
                            }
                        }
                    }
                }
            }
            self.playerCountLabel.text = [NSString stringWithFormat:@"PastaWare | Players: %d", (int)validPlayers];
            self.playerCountLabel.hidden = YES;
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
            self.espSkeletonLayer.path = esp_skeleton_enabled ? skeletonPath.CGPath : nil;
            [CATransaction commit];
            [CATransaction flush];

            [self.watermarkLabel sizeToFit];
            return;
        }
    }

CLEAR_BOXES:
    [self clearAllBoxes];

    self.playerCountLabel.textColor = [[UIColor greenColor] colorWithAlphaComponent:0.5];
    self.playerCountLabel.text      = @"PLAYERS: 0";
    self.playerCountLabel.hidden    = !self.isESPCountEnabled;
    self.noPlayersLabel.hidden      = YES;
}

static mach_vm_address_t GetAimBoneOffset(int idx) {
    switch(idx) {
        case 0: return 0x20; // Head
        case 1: return 0x28; // Neck
        case 2: return 0x40; // Spine2
        case 3: return 0x88; // Hip
        default: return 0x20;
    }
}


static mach_vm_address_t FindBipedMapCached(mach_vm_address_t player, task_t task) {
    int cvOffsets[] = {0xD0, 0x48, 0x50, 0x58, 0xC8, 0xD8, 0xE0};
    int bmOffsets[] = {0x48, 0x50, 0x40, 0x58};
    for (int ci = 0; ci < 7; ci++) {
        mach_vm_address_t cv = Read<mach_vm_address_t>(player + cvOffsets[ci], task);
        if (cv < 0x1000000) continue;
        for (int bi = 0; bi < 4; bi++) {
            mach_vm_address_t bm = Read<mach_vm_address_t>(cv + bmOffsets[bi], task);
            if (bm < 0x1000000) continue;
            mach_vm_address_t headT = Read<mach_vm_address_t>(bm + 0x20, task);
            if (headT < 0x1000000) continue;
            Vector3 hp = get_position_by_transform(headT, task);
            if (hp.x != 0 || hp.y != 0 || hp.z != 0) return bm;
        }
    }
    return 0;
}

static Vector3 GetBoneWorldPos(mach_vm_address_t bipedMap, int boneOffset, task_t task) {
    if (!bipedMap) return {0,0,0};
    mach_vm_address_t t = Read<mach_vm_address_t>(bipedMap + boneOffset, task);
    if (t < 0x1000000) return {0,0,0};
    return get_position_by_transform(t, task);
}

static Vector3 GetBonePosition(mach_vm_address_t player, int boneIdx, task_t task) {
    mach_vm_address_t bm = FindBipedMapCached(player, task);
    if (bm) {
        Vector3 pos = GetBoneWorldPos(bm, GetAimBoneOffset(boneIdx), task);
        if (pos.x != 0 || pos.y != 0 || pos.z != 0) return pos;
    }

    mach_vm_address_t mc = Read<mach_vm_address_t>(player + 0x98, task);
    if (mc > 0x1000000) {
        mach_vm_address_t md = Read<mach_vm_address_t>(mc + 0xB0, task);
        if (md > 0x1000000) {
            Vector3 pos = Read<Vector3>(md + 0x44, task);
            if (boneIdx == 0) pos.y += 1.35f;
            else if (boneIdx == 1) pos.y += 1.2f;
            else pos.y += 0.85f;
            return pos;
        }
    }
    return {0,0,0};
}

static int GetPlayerTeamAim(mach_vm_address_t player, task_t task) {
    // Direct read: PlayerController+0x79 → team byte (новые офсеты)
    if (!player || player < 0x1000000) return -1;
    return (int)Read<uint8_t>(player + 0x79, task);
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
    if (!player || player < 0x1000000) return 100;

    mach_vm_address_t photonPlayer = Read<mach_vm_address_t>(player + 0x160, task);
    if (!photonPlayer || photonPlayer < 0x1000000) return 100;

    mach_vm_address_t props = Read<mach_vm_address_t>(photonPlayer + 0x38, task);
    if (!props || props < 0x1000000) return 100;

    int size = Read<int>(props + 0x20, task);
    mach_vm_address_t entries = Read<mach_vm_address_t>(props + 0x18, task);
    if (!entries || entries < 0x1000000 || size <= 0 || size > 64) return 100;

    for (int i = 0; i < size; i++) {
        mach_vm_address_t propkey = Read<mach_vm_address_t>(entries + 0x20 + 0x18 * i + 0x8, task);
        mach_vm_address_t propval = Read<mach_vm_address_t>(entries + 0x20 + 0x18 * i + 0x10, task);
        if (!propkey || !propval || propkey < 0x1000000 || propval < 0x1000000) continue;

        int strLen = Read<int>(propkey + 0x10, task);
        if (strLen == 6) {
            uint64_t part1 = Read<uint64_t>(propkey + 0x14, task);
            if (part1 == 0x006C006100650068ULL) { // "heal" UTF-16 LE
                uint32_t part2 = Read<uint32_t>(propkey + 0x1C, task);
                if (part2 == 0x00680074) { // "th" UTF-16 LE
                    int hp = Read<int>(propval + 0x10, task);
                    if (hp >= 0 && hp <= 200) return hp;
                }
            }
        }
    }
    return 100;
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
                uint8_t isFiringState = Read<uint8_t>(wctrl + 0x148, so2_task);
                if (isFiringState != 3) {
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
                // v0.39.1: detect melee via SlotIndex byte at WeaponController+0x94 (slot 2 = melee)
                uint8_t wid = Read<uint8_t>(wctrl + 0x94, so2_task);
                if (wid == 2) {
                    self.aimbotCurrentTarget = 0;
                    return;
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

    float currentPitch = Read<float>(aimingData + 0x18, so2_task);
    float currentYaw   = Read<float>(aimingData + 0x1C, so2_task);

    Vector3 screenTarget = WorldToScreen(closestBonePos, viewMatrix, (int)w, (int)h);
    if (screenTarget.z <= 0) return;

    float cx2 = w / 2.0f, cy2 = h / 2.0f;
    float errX = screenTarget.x - cx2;
    float errY = screenTarget.y - cy2;

    // w,h в поинтах UIKit (не пикселях), degPerPt = FOV / screenPoints
    float degPerPtY = 0.15f;
    float degPerPtX = 0.12f;

    float pitchDelta = errY * degPerPtY;
    float yawDelta   = errX * degPerPtX;

    float newPitch, newYaw;

    if (aimbot_smooth <= 1.0f) {
        newPitch = fmaxf(-89.0f, fminf(89.0f, currentPitch + pitchDelta));
        newYaw   = currentYaw + yawDelta;
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
    // Use a silent local audio loop to keep the process alive in background
    // No external URL dependency
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        // keepalive ping every 5s — just enough to stay alive
        while (1) {
            usleep(5000000);
        }
    });
}

- (void)playerItemDidReachEnd:(NSNotification *)notification {
    // no-op: local keepalive doesn't use AVPlayer anymore
}

@end