//Require standard library
#import <UIKit/UIKit.h>
#import <Metal/Metal.h>
#import <QuartzCore/CAMetalLayer.h>
#import <Foundation/Foundation.h>

// Import ImGui headers early so they're available for all code below
#import "IMGUI/imgui.h"
#import "IMGUI/imgui_impl_metal.h"
#import "IMGUI/Honkai.h"

// Minimal forward declarations for MTKView to avoid pulling in full MetalKit headers
@class MTKView;

@protocol MTKViewDelegate <NSObject>
- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size;
- (void)drawInMTKView:(MTKView *)view;
@end

@interface MTKView : UIView
@property (nullable, nonatomic, strong) id<MTLDevice> device;
@property (nullable, nonatomic, weak) id<MTKViewDelegate> delegate;
@property (nonatomic) MTLClearColor clearColor;
@property (nullable, nonatomic, readonly) id<CAMetalDrawable> currentDrawable;
@property (nullable, nonatomic, readonly) MTLRenderPassDescriptor *currentRenderPassDescriptor;
@property (nonatomic) NSInteger preferredFramesPerSecond;
@end

// Debug variables for touch tracking (declared early so TouchableMTKView can use them)
static char debugText[256] = "Waiting for touch...";
static int touchCount = 0;
static NSUInteger gLastChangedTouches = 0;
static NSUInteger gLastAllTouches = 0;
static CGPoint gInjectedPoint = {0.0, 0.0};
static BOOL gInjectedMouseDown = NO;
static BOOL gHasInjectedPoint = NO;
static __weak UIView *gImGuiHostView = nil;
static CGPoint gUIKitPoint = {0.0, 0.0};
static BOOL gUIKitMouseDown = NO;
static BOOL gHasUIKitPoint = NO;
static CFTimeInterval gLastUIKitTouchTime = 0.0;
static CFTimeInterval gLastInjectedTouchTime = 0.0;

// Main menu ImGui context. The ESP debug overlay runs a second context, so any
// code that touches ImGui IO outside that overlay's own draw must bind to this
// one first (touch handlers, AX injection, the menu draw).
ImGuiContext *gMainImGuiContext = nullptr;
extern "C" ImGuiContext *HUDMainImGuiContext(void) { return gMainImGuiContext; }

// Rect of the actual menu window in view-local coords, updated every render. The
// menu surface only captures touches over this rect; everything else passes
// through so you can tap things that are not under the checkbox window.
static CGRect gMenuWindowRect = CGRectZero;

// Custom MTKView that forwards touch events
@interface TouchableMTKView : MTKView
@property (nonatomic, weak) id touchDelegate;
@property (nonatomic, assign) BOOL shouldCaptureTouch;
@end

@implementation TouchableMTKView

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    if (!self.shouldCaptureTouch) return nil;

    // When menu is open: capture only the menu window rect.
    if (!CGRectIsEmpty(gMenuWindowRect)) {
        return CGRectContainsPoint(gMenuWindowRect, point) ? self : nil;
    }

    // When menu is closed: capture only the EH dot area (top-right corner ~40x40pt).
    CGFloat w = self.bounds.size.width;
    CGRect dotRect = CGRectMake(w - 56, 16, 40, 40);
    return CGRectContainsPoint(dotRect, point) ? self : nil;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    snprintf(debugText, sizeof(debugText), "MTKView: touchesBegan called!");
    
    if ([self.touchDelegate respondsToSelector:@selector(touchesBegan:withEvent:)]) {
        [self.touchDelegate touchesBegan:touches withEvent:event];
    }
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    if ([self.touchDelegate respondsToSelector:@selector(touchesMoved:withEvent:)]) {
        [self.touchDelegate touchesMoved:touches withEvent:event];
    }
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    
    if ([self.touchDelegate respondsToSelector:@selector(touchesEnded:withEvent:)]) {
        [self.touchDelegate touchesEnded:touches withEvent:event];
    }
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    if ([self.touchDelegate respondsToSelector:@selector(touchesCancelled:withEvent:)]) {
        [self.touchDelegate touchesCancelled:touches withEvent:event];
    }
}

@end

#import "Esp/CaptainHook.h"
#import "Esp/ImGuiDrawView.h"
#import "ESPImGuiView.h"

static const char *HUDPhaseName(NSInteger phase)
{
    switch (phase) {
        case UITouchPhaseBegan: return "beg";
        case UITouchPhaseMoved: return "mov";
        case UITouchPhaseStationary: return "sta";
        case UITouchPhaseEnded: return "end";
        case UITouchPhaseCancelled: return "can";
        default: return "unk";
    }
}

extern "C" void HUDInjectImGuiTouchAtWindowPoint(CGPoint point, NSInteger phase, UIWindow *window)
{
    if (!gImGuiHostView || !window) {
        return;
    }

    CGPoint localPoint = [gImGuiHostView convertPoint:point fromView:window];
    BOOL pointInside = CGRectContainsPoint(gImGuiHostView.bounds, localPoint);
    BOOL isActivePhase = (phase != UITouchPhaseEnded && phase != UITouchPhaseCancelled);

    if (!pointInside && !gInjectedMouseDown && !isActivePhase) {
        return;
    }

    gInjectedPoint = localPoint;
    gHasInjectedPoint = YES;
    gInjectedMouseDown = isActivePhase;
    gLastInjectedTouchTime = CACurrentMediaTime();
    snprintf(debugText, sizeof(debugText), "AX %s %.0f %.0f", HUDPhaseName(phase), localPoint.x, localPoint.y);

    if (gMainImGuiContext) {
        ImGui::SetCurrentContext(gMainImGuiContext);
        ImGuiIO &io = ImGui::GetIO();
        io.ConfigFlags |= ImGuiConfigFlags_IsTouchScreen;
        io.MousePos = ImVec2(localPoint.x, localPoint.y);
        io.MouseDown[0] = gInjectedMouseDown;
    }
}

// Bridge to HUD layer — ESP control
extern "C" void HUDSetESPEnabled(bool enabled);
extern "C" void HUDSetTracersEnabled(bool enabled);
extern "C" void HUDSetOverlayEnabled(bool enabled);
extern "C" void HUDSetStealthEnabled(bool enabled);
extern "C" void HUDHideMenu(void);

// Debug info from ESP pipeline (defined in HUDMainApplication.mm)
extern "C" pid_t    HUDGetDebugPID(void);
extern "C" uint64_t HUDGetDebugUnity(void);
extern "C" uint64_t HUDGetDebugTypeInfo(void);
extern "C" uint64_t HUDGetDebugPM(void);
extern "C" int      HUDGetDebugPlayers(void);

#define kWidth  [UIScreen mainScreen].bounds.size.width
#define kHeight [UIScreen mainScreen].bounds.size.height
#define kScale [UIScreen mainScreen].scale

@interface ImGuiDrawView () <MTKViewDelegate>
@property (nonatomic, strong) id <MTLDevice> device;
@property (nonatomic, strong) id <MTLCommandQueue> commandQueue;
@end

@implementation ImGuiDrawView

//I usually let the function for hooking in here...
void (*huy)(void *instance);
void _huy(void *instance)
{
    huy(instance);
}

static bool MenDeal = true;


- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];


    _device = MTLCreateSystemDefaultDevice();
    _commandQueue = [_device newCommandQueue];

    if (!self.device) {
        abort();
    }

    IMGUI_CHECKVERSION();
    ImGui::CreateContext();
    gMainImGuiContext = ImGui::GetCurrentContext();
    ImGuiIO& io = ImGui::GetIO(); (void)io;
    io.IniFilename = NULL;

    // GameSense-style dark theme: near-black bg, pink/purple accent
    ImGui::StyleColorsDark();

    ImFontConfig fontCfg;
    fontCfg.SizePixels = 15.0f;
    io.Fonts->AddFontDefault(&fontCfg);

    ImGuiStyle &style = ImGui::GetStyle();

    // Pink/magenta accent matching gamesense
    const ImVec4 accent    = ImVec4(0.78f, 0.18f, 0.84f, 1.00f);
    const ImVec4 accentDim = ImVec4(0.78f, 0.18f, 0.84f, 0.35f);
    const ImVec4 bgMain    = ImVec4(0.06f, 0.06f, 0.07f, 0.97f);
    const ImVec4 bgFrame   = ImVec4(0.10f, 0.10f, 0.12f, 1.00f);
    const ImVec4 bgFrameH  = ImVec4(0.14f, 0.14f, 0.17f, 1.00f);

    style.Colors[ImGuiCol_Text]             = ImVec4(0.88f, 0.88f, 0.90f, 1.00f);
    style.Colors[ImGuiCol_TextDisabled]     = ImVec4(0.42f, 0.42f, 0.46f, 1.00f);
    style.Colors[ImGuiCol_WindowBg]         = bgMain;
    style.Colors[ImGuiCol_ChildBg]          = ImVec4(0.05f, 0.05f, 0.06f, 1.00f);
    style.Colors[ImGuiCol_PopupBg]          = ImVec4(0.08f, 0.08f, 0.09f, 0.98f);
    style.Colors[ImGuiCol_FrameBg]          = bgFrame;
    style.Colors[ImGuiCol_FrameBgHovered]   = bgFrameH;
    style.Colors[ImGuiCol_FrameBgActive]    = accentDim;
    style.Colors[ImGuiCol_CheckMark]        = accent;
    style.Colors[ImGuiCol_SliderGrab]       = accent;
    style.Colors[ImGuiCol_SliderGrabActive] = ImVec4(0.90f, 0.30f, 0.95f, 1.00f);
    style.Colors[ImGuiCol_Button]           = bgFrame;
    style.Colors[ImGuiCol_ButtonHovered]    = bgFrameH;
    style.Colors[ImGuiCol_ButtonActive]     = accentDim;
    style.Colors[ImGuiCol_Header]           = accentDim;
    style.Colors[ImGuiCol_HeaderHovered]    = ImVec4(0.78f, 0.18f, 0.84f, 0.50f);
    style.Colors[ImGuiCol_HeaderActive]     = accent;
    style.Colors[ImGuiCol_Separator]        = ImVec4(0.15f, 0.15f, 0.18f, 1.00f);
    style.Colors[ImGuiCol_TitleBg]          = bgMain;
    style.Colors[ImGuiCol_TitleBgActive]    = bgMain;
    style.Colors[ImGuiCol_ScrollbarBg]      = ImVec4(0.04f, 0.04f, 0.05f, 1.00f);
    style.Colors[ImGuiCol_ScrollbarGrab]    = ImVec4(0.20f, 0.20f, 0.24f, 1.00f);

    style.WindowRounding    = 4.0f;
    style.ChildRounding     = 0.0f;
    style.FrameRounding     = 3.0f;
    style.GrabRounding      = 3.0f;
    style.WindowPadding     = ImVec2(0, 0);
    style.FramePadding      = ImVec2(8, 6);
    style.ItemSpacing       = ImVec2(8, 5);
    style.ItemInnerSpacing  = ImVec2(6, 4);
    style.TouchExtraPadding = ImVec2(8, 8);
    style.WindowBorderSize  = 0.0f;
    style.ChildBorderSize   = 0.0f;

    ImGui_ImplMetal_Init(_device);


    return self;
}

static bool gHUDMenuWasOpen = true;

+ (void)showChange:(BOOL)open
{
    MenDeal = open;
    if (open) {
        gHUDMenuWasOpen = true;
    }
}

- (MTKView *)mtkView
{
    return (MTKView *)self.view;
}

- (void)loadView
{

    UIWindow *window = [UIApplication sharedApplication].keyWindow ?: [UIApplication sharedApplication].windows.firstObject;
    CGFloat w = window.bounds.size.width;
    CGFloat h = window.bounds.size.height;
    TouchableMTKView *mtkView = [[TouchableMTKView alloc] initWithFrame:CGRectMake(0, 0, w, h)];
    mtkView.shouldCaptureTouch = NO; // Initially don't capture touches
    self.view = mtkView;
    self.view.multipleTouchEnabled = YES;
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    mtkView.touchDelegate = self;
    gImGuiHostView = self.view;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.mtkView.device = self.device;
    self.mtkView.delegate = self;
    self.mtkView.clearColor = MTLClearColorMake(0, 0, 0, 0);
    self.mtkView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0];
    self.mtkView.clipsToBounds = YES;
    self.view.clipsToBounds = YES;
    self.mtkView.userInteractionEnabled = YES;
    self.mtkView.multipleTouchEnabled = YES;
}



#pragma mark - Interaction

- (void)updateIOWithTouchEvent:(UIEvent *)event
{
    NSSet<UITouch *> *allTouches = event.allTouches;
    gLastAllTouches = allTouches.count;
    UITouch *anyTouch = allTouches.anyObject;
    if (!anyTouch) {
        return;
    }

    CGPoint touchLocation = [anyTouch locationInView:self.view];
    gUIKitPoint = touchLocation;
    gHasUIKitPoint = YES;
    gLastUIKitTouchTime = CACurrentMediaTime();
    if (gMainImGuiContext) ImGui::SetCurrentContext(gMainImGuiContext);
    ImGuiIO &io = ImGui::GetIO();
    io.ConfigFlags |= ImGuiConfigFlags_IsTouchScreen;
    io.MousePos = ImVec2(touchLocation.x, touchLocation.y);

    BOOL hasActiveTouch = NO;
    for (UITouch *touch in allTouches)
    {
        if (touch.phase != UITouchPhaseEnded && touch.phase != UITouchPhaseCancelled)
        {
            hasActiveTouch = YES;
            break;
        }
    }
    io.MouseDown[0] = hasActiveTouch;
    gUIKitMouseDown = hasActiveTouch;

    if (hasActiveTouch) {
        gHasInjectedPoint = NO;
    }
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    touchCount++;
    gLastChangedTouches = touches.count;
    gLastAllTouches = event.allTouches.count;
    snprintf(debugText, sizeof(debugText), "UI beg ch:%lu all:%lu", (unsigned long)gLastChangedTouches, (unsigned long)gLastAllTouches);
    [self updateIOWithTouchEvent:event];
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    gLastChangedTouches = touches.count;
    gLastAllTouches = event.allTouches.count;
    snprintf(debugText, sizeof(debugText), "UI mov ch:%lu all:%lu", (unsigned long)gLastChangedTouches, (unsigned long)gLastAllTouches);
    [self updateIOWithTouchEvent:event];
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    gLastChangedTouches = touches.count;
    gLastAllTouches = event.allTouches.count;
    snprintf(debugText, sizeof(debugText), "UI can ch:%lu all:%lu", (unsigned long)gLastChangedTouches, (unsigned long)gLastAllTouches);
    [self updateIOWithTouchEvent:event];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    gLastChangedTouches = touches.count;
    gLastAllTouches = event.allTouches.count;
    snprintf(debugText, sizeof(debugText), "UI end ch:%lu all:%lu", (unsigned long)gLastChangedTouches, (unsigned long)gLastAllTouches);
    [self updateIOWithTouchEvent:event];
}



#pragma mark - MTKViewDelegate

- (void)drawInMTKView:(MTKView*)view
{
    // The ESP overlay swaps the current context during its own draw, so make
    // sure the menu always renders into the main context.
    if (gMainImGuiContext) ImGui::SetCurrentContext(gMainImGuiContext);
    ImGuiIO& io = ImGui::GetIO();

    CFTimeInterval now = CACurrentMediaTime();
    BOOL preferUIKitTouch = gHasUIKitPoint && ((now - gLastUIKitTouchTime) < 0.35 || gUIKitMouseDown);

    if (preferUIKitTouch) {
        io.ConfigFlags |= ImGuiConfigFlags_IsTouchScreen;
        io.MousePos = ImVec2(gUIKitPoint.x, gUIKitPoint.y);
        io.MouseDown[0] = gUIKitMouseDown;
    } else if (gHasInjectedPoint) {
        io.ConfigFlags |= ImGuiConfigFlags_IsTouchScreen;
        io.MousePos = ImVec2(gInjectedPoint.x, gInjectedPoint.y);
        io.MouseDown[0] = gInjectedMouseDown;
    }

    io.DisplaySize.x = view.bounds.size.width;
    io.DisplaySize.y = view.bounds.size.height;

    CGFloat framebufferScale = view.window.screen.scale ?: UIScreen.mainScreen.scale;
    io.DisplayFramebufferScale = ImVec2(framebufferScale, framebufferScale);
    io.DeltaTime = 1.0f / float(view.preferredFramesPerSecond ?: 120);

    id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];

    static bool showBoxes   = false;
    static bool showTracers = false;
    static bool showHealthBar = false;
    static bool showName    = false;
    static bool showWeapon  = false;
    static bool teamCheck   = true;
    static float colLine[3]   = {1.0f, 1.0f, 1.0f};
    static float colBox[3]    = {1.0f, 1.0f, 1.0f};
    static float colHp[3]     = {0.20f, 0.90f, 0.30f};
    static float colName[3]   = {1.0f, 1.0f, 1.0f};
    static float colWeapon[3] = {1.0f, 1.0f, 1.0f};
    static bool  chamsEnabled = false;
    static int   chamsMaterialId = 0;       // 0 = solid purple "missing material"
    static bool  stealthEnabled = false;    // hide menu + ESP from screenshots/recording

    // Always capture so the EH dot is tappable when menu is closed too.
    // hitTest returns self only for gMenuWindowRect (menu) or the dot area (closed).
    TouchableMTKView *touchableView = (TouchableMTKView *)view;
    if ([touchableView isKindOfClass:[TouchableMTKView class]]) {
        touchableView.shouldCaptureTouch = YES;
    }

    if (MenDeal == true) {
        gHUDMenuWasOpen = true;
        [self.view setUserInteractionEnabled:YES];
    } else {
        if (gHUDMenuWasOpen) {
            HUDHideMenu();
            gHUDMenuWasOpen = false;
        }
        [self.view setUserInteractionEnabled:YES];
    }

    MTLRenderPassDescriptor* renderPassDescriptor = view.currentRenderPassDescriptor;
    if (!renderPassDescriptor) {
        [commandBuffer commit];
        return;
    }

    id<MTLRenderCommandEncoder> renderEncoder =
        [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
    [renderEncoder pushDebugGroup:@"ImGui Jane"];

    ImGui_ImplMetal_NewFrame(renderPassDescriptor);
    ImGui::NewFrame();
    
    if (MenDeal == true)
    {
        // GameSense-style: title bar kept (drag + close button), sidebar + content
        ImGuiWindowFlags flags = ImGuiWindowFlags_NoCollapse  |
                                 ImGuiWindowFlags_NoResize    |
                                 ImGuiWindowFlags_NoSavedSettings;
        // Fit inside portrait phone screen (~390pt wide), leave margin
        const float WIN_W = fminf(390.0f, io.DisplaySize.x - 20.0f);
        const float WIN_H = fminf(420.0f, io.DisplaySize.y - 60.0f);
        ImGui::SetNextWindowSize(ImVec2(WIN_W, WIN_H), ImGuiCond_Always);
        ImGui::SetNextWindowPos(ImVec2(io.DisplaySize.x * 0.5f, io.DisplaySize.y * 0.5f),
                                ImGuiCond_FirstUseEver, ImVec2(0.5f, 0.5f));
        // Style the title bar: dark + pink accent colour
        ImGui::PushStyleColor(ImGuiCol_TitleBg,       ImVec4(0.07f,0.07f,0.08f,1.0f));
        ImGui::PushStyleColor(ImGuiCol_TitleBgActive,  ImVec4(0.10f,0.07f,0.11f,1.0f));
        ImGui::PushStyleVar(ImGuiStyleVar_WindowPadding, ImVec2(0, 0));
        // &MenDeal shows the X close button automatically
        ImGui::Begin("ExtraHook", &MenDeal, flags);
        ImGui::PopStyleVar();
        ImGui::PopStyleColor(2);

        ImDrawList *dl = ImGui::GetWindowDrawList();
        ImVec2 winPos  = ImGui::GetWindowPos();
        ImVec2 winSize = ImGui::GetWindowSize();

        // ── Pink accent line below title bar ──────────────────────────────
        float titleH = ImGui::GetFrameHeight() + 2.0f;  // approximate title bar height
        dl->AddRectFilled(ImVec2(winPos.x, winPos.y + titleH - 1),
                          ImVec2(winPos.x + winSize.x, winPos.y + titleH + 1),
                          IM_COL32(200, 46, 214, 255));

        // ── Left sidebar (50px) ───────────────────────────────────────────
        static int activeSection = 0;
        const float SIDEBAR_W = 50.0f;

        // Sidebar background and border (drawn over client area starting at y=0)
        ImVec2 clientMin = ImVec2(winPos.x, winPos.y + titleH + 1);
        dl->AddRectFilled(clientMin,
                          ImVec2(winPos.x + SIDEBAR_W, winPos.y + winSize.y),
                          IM_COL32(10, 10, 12, 255));
        dl->AddRectFilled(ImVec2(winPos.x + SIDEBAR_W, winPos.y + titleH + 1),
                          ImVec2(winPos.x + SIDEBAR_W + 1, winPos.y + winSize.y),
                          IM_COL32(22, 22, 26, 255));

        ImGui::SetCursorPos(ImVec2(0, 0));
        ImGui::PushStyleVar(ImGuiStyleVar_ItemSpacing, ImVec2(0, 0));

        ImGui::BeginChild("##sidebar", ImVec2(SIDEBAR_W, -1), false,
                          ImGuiWindowFlags_NoScrollbar | ImGuiWindowFlags_NoScrollWithMouse);

        // Section labels  [E] [V] [M] [?]
        const char *secLabels[] = {"ESP", "VIS", "MISC", "INFO"};
        const int   secCount    = 4;

        for (int i = 0; i < secCount; i++) {
            bool sel = (activeSection == i);
            ImVec4 txtCol = sel ? ImVec4(0.80f, 0.20f, 0.86f, 1.0f)
                                : ImVec4(0.40f, 0.40f, 0.44f, 1.0f);
            ImVec4 btnBg  = sel ? ImVec4(0.10f, 0.10f, 0.13f, 1.0f)
                                : ImVec4(0.00f, 0.00f, 0.00f, 0.0f);

            ImGui::PushStyleColor(ImGuiCol_Button,        btnBg);
            ImGui::PushStyleColor(ImGuiCol_ButtonHovered, ImVec4(0.10f,0.10f,0.13f,0.8f));
            ImGui::PushStyleColor(ImGuiCol_ButtonActive,  ImVec4(0.12f,0.12f,0.16f,1.0f));
            ImGui::PushStyleColor(ImGuiCol_Text,          txtCol);

            if (ImGui::Button(secLabels[i], ImVec2(SIDEBAR_W, 52)))
                activeSection = i;

            ImGui::PopStyleColor(4);

            // Left accent bar for selected tab
            if (sel) {
                ImVec2 rMin = ImGui::GetItemRectMin();
                ImVec2 rMax = ImGui::GetItemRectMax();
                ImGui::GetWindowDrawList()->AddRectFilled(
                    rMin, ImVec2(rMin.x + 3, rMax.y), IM_COL32(200, 46, 214, 255));
            }
        }
        ImGui::EndChild();
        ImGui::PopStyleVar();

        // ── Right content ─────────────────────────────────────────────────
        ImGui::SetCursorPos(ImVec2(SIDEBAR_W + 1, 0));
        ImGui::PushStyleVar(ImGuiStyleVar_WindowPadding, ImVec2(12, 10));
        ImGui::PushStyleVar(ImGuiStyleVar_ItemSpacing,   ImVec2(8, 5));
        ImGui::BeginChild("##content", ImVec2(-1, -1), false);

        ImGuiColorEditFlags cflags = ImGuiColorEditFlags_NoInputs | ImGuiColorEditFlags_NoAlpha;

        // Helper: draw a grey section header like "Visuals" / "Settings"
        auto SectionHeader = [](const char *label) {
            ImGui::PushStyleColor(ImGuiCol_Text, ImVec4(0.45f,0.45f,0.50f,1.0f));
            ImGui::Text("%s", label);
            ImGui::PopStyleColor();
            ImGui::PushStyleColor(ImGuiCol_Separator, ImVec4(0.14f,0.14f,0.17f,1.0f));
            ImGui::Separator();
            ImGui::PopStyleColor();
            ImGui::Spacing();
        };

        // ── SECTION 0: ESP ────────────────────────────────────────────────
        if (activeSection == 0) {
            ImGui::Columns(2, "##espcols", false);

            SectionHeader("Boxes & Lines");
            ImGui::Checkbox("Box ESP",    &showBoxes);
            ImGui::SameLine(0,6); ImGui::ColorEdit3("##cbox",  colBox,  cflags);
            ImGui::Spacing();
            ImGui::Checkbox("Snap Lines", &showTracers);
            ImGui::SameLine(0,6); ImGui::ColorEdit3("##cline", colLine, cflags);
            ImGui::Spacing();
            ImGui::Checkbox("Health Bar", &showHealthBar);
            ImGui::SameLine(0,6); ImGui::ColorEdit3("##chp",   colHp,   cflags);

            ImGui::NextColumn();

            SectionHeader("Info");
            ImGui::Checkbox("Name",       &showName);
            ImGui::SameLine(0,6); ImGui::ColorEdit3("##cname", colName,   cflags);
            ImGui::Spacing();
            ImGui::Checkbox("Weapon",     &showWeapon);
            ImGui::SameLine(0,6); ImGui::ColorEdit3("##cwep",  colWeapon, cflags);
            ImGui::Spacing();
            ImGui::Checkbox("Team Check", &teamCheck);
            ImGui::PushStyleColor(ImGuiCol_Text, ImVec4(0.4f,0.4f,0.44f,1.0f));
            ImGui::Text("  skip teammates");
            ImGui::PopStyleColor();

            ImGui::Columns(1);
        }

        // ── SECTION 1: VIS ────────────────────────────────────────────────
        else if (activeSection == 1) {
            SectionHeader("Chams");
            ImGui::Checkbox("Enable Chams", &chamsEnabled);
            if (chamsEnabled) {
                ImGui::SetNextItemWidth(180);
                ImGui::SliderInt("Material ID", &chamsMaterialId, 0, 200);
                ImGui::PushStyleColor(ImGuiCol_Text, ImVec4(0.4f,0.4f,0.44f,1.0f));
                ImGui::Text("  experimental, may crash");
                ImGui::PopStyleColor();
            }
            ImGui::Spacing();
            SectionHeader("Stealth");
            ImGui::Checkbox("Hide from screen record", &stealthEnabled);
            ImGui::PushStyleColor(ImGuiCol_Text, ImVec4(0.4f,0.4f,0.44f,1.0f));
            ImGui::Text("  hides menu+ESP from screenshots");
            ImGui::PopStyleColor();
        }

        // ── SECTION 2: MISC ───────────────────────────────────────────────
        else if (activeSection == 2) {
            SectionHeader("ExtraHook v2.0");
            ImGui::Text("Standoff 2  0.39.2");
            ImGui::Text("iOS TrollStore overlay");
            ImGui::Spacing();
            SectionHeader("Controls");
            ImGui::PushStyleColor(ImGuiCol_Text, ImVec4(0.4f,0.4f,0.44f,1.0f));
            ImGui::Text("  Tap EH dot to open menu");
            ImGui::Text("  Drag title bar to reposition");
            ImGui::PopStyleColor();
        }

        // ── SECTION 3: INFO (debug) ───────────────────────────────────────
        else if (activeSection == 3) {
            SectionHeader("Pipeline Debug");

            pid_t    dbgPid  = HUDGetDebugPID();
            uint64_t dbgBase = HUDGetDebugUnity();
            uint64_t dbgTI   = HUDGetDebugTypeInfo();
            uint64_t dbgPM   = HUDGetDebugPM();
            int      dbgPlrs = HUDGetDebugPlayers();

            // PID row
            if (dbgPid > 0) {
                ImGui::PushStyleColor(ImGuiCol_Text, ImVec4(0.10f,0.85f,0.35f,1.0f));
                ImGui::Text("PID      %d  [OK]", (int)dbgPid);
            } else {
                ImGui::PushStyleColor(ImGuiCol_Text, ImVec4(0.85f,0.20f,0.20f,1.0f));
                ImGui::Text("PID      --- [game not found]");
            }
            ImGui::PopStyleColor();

            // Unity base row
            if (dbgBase) {
                ImGui::PushStyleColor(ImGuiCol_Text, ImVec4(0.10f,0.85f,0.35f,1.0f));
                ImGui::Text("Unity    0x%llX  [OK]", (unsigned long long)dbgBase);
            } else {
                ImGui::PushStyleColor(ImGuiCol_Text, ImVec4(0.85f,0.55f,0.10f,1.0f));
                ImGui::Text("Unity    0x0  [not found]");
            }
            ImGui::PopStyleColor();

            // TypeInfo row
            if (dbgTI) {
                ImGui::PushStyleColor(ImGuiCol_Text, ImVec4(0.10f,0.85f,0.35f,1.0f));
                ImGui::Text("TypeInfo 0x%llX  [OK]", (unsigned long long)dbgTI);
            } else {
                ImGui::PushStyleColor(ImGuiCol_Text, ImVec4(0.85f,0.55f,0.10f,1.0f));
                ImGui::Text("TypeInfo 0x0  [read failed]");
            }
            ImGui::PopStyleColor();

            // PlayerManager row
            if (dbgPM) {
                ImGui::PushStyleColor(ImGuiCol_Text, ImVec4(0.10f,0.85f,0.35f,1.0f));
                ImGui::Text("PM       0x%llX  [OK]", (unsigned long long)dbgPM);
            } else {
                ImGui::PushStyleColor(ImGuiCol_Text, ImVec4(0.85f,0.55f,0.10f,1.0f));
                ImGui::Text("PM       0x0  [read failed]");
            }
            ImGui::PopStyleColor();

            // Players count
            if (dbgPlrs > 0) {
                ImGui::PushStyleColor(ImGuiCol_Text, ImVec4(0.10f,0.85f,0.35f,1.0f));
                ImGui::Text("Players  %d", dbgPlrs);
            } else {
                ImGui::PushStyleColor(ImGuiCol_Text, ImVec4(0.85f,0.55f,0.10f,1.0f));
                ImGui::Text("Players  0  [in lobby / bad ptr]");
            }
            ImGui::PopStyleColor();

            ImGui::Spacing();
            ImGui::PushStyleColor(ImGuiCol_Text, ImVec4(0.4f,0.4f,0.44f,1.0f));
            ImGui::Text("Open game + match for non-zero values");
            ImGui::PopStyleColor();
        }

        ImGui::EndChild();
        ImGui::PopStyleVar(2);

        // ── Propagate state to ESP pipeline ──────────────────────────────
        [ESPImGuiView setLineColor:[UIColor colorWithRed:colLine[0] green:colLine[1] blue:colLine[2] alpha:1.0]];
        [ESPImGuiView setBoxColor:[UIColor colorWithRed:colBox[0] green:colBox[1] blue:colBox[2] alpha:1.0]];
        [ESPImGuiView setHpColor:[UIColor colorWithRed:colHp[0] green:colHp[1] blue:colHp[2] alpha:1.0]];
        [ESPImGuiView setNameColor:[UIColor colorWithRed:colName[0] green:colName[1] blue:colName[2] alpha:1.0]];
        [ESPImGuiView setWeaponColor:[UIColor colorWithRed:colWeapon[0] green:colWeapon[1] blue:colWeapon[2] alpha:1.0]];
        [ESPImGuiView setChamsEnabled:chamsEnabled];
        [ESPImGuiView setChamsMaterialId:chamsMaterialId];
        [ESPImGuiView setStealthEnabled:stealthEnabled];

        static bool prevStealth = false;
        if (stealthEnabled != prevStealth) {
            prevStealth = stealthEnabled;
            HUDSetStealthEnabled(stealthEnabled);
        }

        BOOL espOn = (showBoxes || showHealthBar || showName || showWeapon || showTracers || chamsEnabled);
        [ESPImGuiView setESPEnabled:espOn];
        [ESPImGuiView setTracersEnabled:espOn];
        [ESPImGuiView setShowLines:showTracers];
        [ESPImGuiView setShowBox:showBoxes];
        [ESPImGuiView setShowHealthBar:showHealthBar];
        [ESPImGuiView setShowName:showName];
        [ESPImGuiView setShowWeapon:showWeapon];
        [ESPImGuiView setTeamCheck:teamCheck];

        HUDSetESPEnabled(espOn);
        HUDSetTracersEnabled(espOn);

        ImVec2 wpos  = ImGui::GetWindowPos();
        ImVec2 wsize = ImGui::GetWindowSize();
        gMenuWindowRect = CGRectMake(wpos.x, wpos.y, wsize.x, wsize.y);

        ImGui::End();
    } else {
        gMenuWindowRect = CGRectZero;
        // Closed-menu indicator: pink pill in top-right — tap anywhere on it to open
        ImDrawList *fg = ImGui::GetForegroundDrawList();
        float bx = io.DisplaySize.x - 36, by = 36;
        fg->AddCircleFilled(ImVec2(bx, by), 20, IM_COL32(12, 12, 15, 220));
        fg->AddCircle(ImVec2(bx, by), 20, IM_COL32(200, 46, 214, 230), 32, 2.0f);
        fg->AddText(ImVec2(bx - 9, by - 6), IM_COL32(210, 60, 225, 255), "EH");
        // Tap on dot to reopen
        if (ImGui::IsMouseHoveringRect(ImVec2(bx-20,by-20), ImVec2(bx+20,by+20)) &&
            ImGui::IsMouseClicked(0)) {
            MenDeal = true;
        }
    }

    ImGui::Render();
    ImDrawData* draw_data = ImGui::GetDrawData();
    ImGui_ImplMetal_RenderDrawData(draw_data, commandBuffer, renderEncoder);
  
    [renderEncoder popDebugGroup];
    [renderEncoder endEncoding];

    [commandBuffer presentDrawable:view.currentDrawable];
    [commandBuffer commit];
}

- (void)mtkView:(MTKView*)view drawableSizeWillChange:(CGSize)size
{
    
}

@end
