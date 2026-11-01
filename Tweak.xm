#import <UIKit/UIKit.h>
#import <substrate.h>
#import <mach-o/dyld.h>
#import <string.h>
#import <sys/sysctl.h>
#import <objc/runtime.h>

// Fix pro erro do sys/ptrace.h no GitHub Actions
#define PT_DENY_ATTACH 31
extern int ptrace(int _request, pid_t _pid, caddr_t _addr, int _data);

static bool g_Aimbot = false;
static bool g_ESP = false;
static bool g_FOV = false;
static float g_FOVRadius = 150.0f;
struct Vector3 { float x, y, z; };
struct Quaternion { float x, y, z, w; };

// ==========================================
// 1. BYPASS EXTREMO (STEALTH)
// ==========================================
static const char* (*orig_dyld_get_image_name)(uint32_t);
static const char* hook_dyld_get_image_name(uint32_t index) {
    const char* name = orig_dyld_get_image_name(index);
    if (name && (strstr(name, "HyzzFFZ") || strstr(name, "substrate"))) return "/usr/lib/libSystem.B.dylib";
    return name;
}

static char** (*orig_objc_copyImageNames)(unsigned int*);
static char** hook_objc_copyImageNames(unsigned int* outCount) {
    char** images = orig_objc_copyImageNames(outCount);
    if (images && outCount) {
        for (unsigned int i = 0; i < *outCount; i++) {
            if (strstr(images[i], "HyzzFFZ") || strstr(images[i], "substrate")) images[i] = strdup("/usr/lib/libSystem.B.dylib");
        }
    }
    return images;
}

static int (*orig_ptrace)(int, pid_t, caddr_t, int);
static int hook_ptrace(int request, pid_t pid, caddr_t addr, int data) {
    if (request == PT_DENY_ATTACH) return 0;
    return orig_ptrace(request, pid, addr, data);
}

static int (*orig_sysctl)(int*, u_int, void*, size_t*, void*, size_t);
static int hook_sysctl(int* name, u_int namelen, void* oldp, size_t* oldlenp, void* newp, size_t newlen) {
    int ret = orig_sysctl(name, namelen, oldp, oldlenp, newp, newlen);
    if (ret == 0 && oldp && name[0] == CTL_KERN && name[1] == KERN_PROC && name[2] == KERN_PROC_PID) {
        ((struct kinfo_proc*)oldp)->kp_proc.p_flag &= ~P_TRACED;
    }
    return ret;
}

static char* (*orig_getenv)(const char*);
static char* hook_getenv(const char* name) {
    if (strstr(name, "DYLD_INSERT_LIBRARIES") || strstr(name, "DYLD_FRAMEWORK_PATH")) return NULL;
    return orig_getenv(name);
}

// ==========================================
// 2. UI DIRETAMENTE NA JANELA DO JOGO
// ==========================================
@interface FOVOverlay : UIView
@end
@implementation FOVOverlay
- (void)drawRect:(CGRect)rect {
    if (!g_FOV) return;
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSetStrokeColorWithColor(ctx, [UIColor greenColor].CGColor);
    CGContextSetLineWidth(ctx, 2.0);
    CGRect circle = CGRectMake(rect.size.width/2 - g_FOVRadius, rect.size.height/2 - g_FOVRadius, g_FOVRadius*2, g_FOVRadius*2);
    CGContextStrokeEllipseInRect(ctx, circle);
}
@end

@interface ESPOverlay : UIView
@end
@implementation ESPOverlay
- (void)drawRect:(CGRect)rect {
    if (!g_ESP) return;
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSetStrokeColorWithColor(ctx, [UIColor redColor].CGColor);
    CGContextSetLineWidth(ctx, 2.0);
    CGContextStrokeRect(ctx, CGRectMake(rect.size.width/2 - 30, rect.size.height/2 - 80, 60, 160));
}
@end

@interface HyzzPanel : UIView
@property (nonatomic, strong) UIView *mainView;
@property (nonatomic, strong) UIButton *openMenuBtn;
@end

@implementation HyzzPanel
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (!self) return nil;
    self.backgroundColor = [UIColor clearColor];
    self.userInteractionEnabled = YES;

    FOVOverlay *fov = [[FOVOverlay alloc] initWithFrame:self.bounds];
    fov.userInteractionEnabled = NO; fov.backgroundColor = [UIColor clearColor];
    [self addSubview:fov];
    ESPOverlay *esp = [[ESPOverlay alloc] initWithFrame:self.bounds];
    esp.userInteractionEnabled = NO; esp.backgroundColor = [UIColor clearColor];
    [self addSubview:esp];

    self.openMenuBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.openMenuBtn.frame = CGRectMake(20, 100, 60, 60);
    self.openMenuBtn.backgroundColor = [UIColor colorWithRed:0.5 green:0.0 blue:0.5 alpha:1.0];
    self.openMenuBtn.layer.cornerRadius = 30;
    [self.openMenuBtn setTitle:@"HYZ" forState:UIControlStateNormal];
    [self.openMenuBtn addTarget:self action:@selector(showMenu) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.openMenuBtn];

    UIPanGestureRecognizer *panBtn = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(dragBtn:)];
    [self.openMenuBtn addGestureRecognizer:panBtn];

    self.mainView = [[UIView alloc] initWithFrame:CGRectMake(20, 150, 300, 350)];
    self.mainView.backgroundColor = [UIColor blackColor];
    self.mainView.layer.cornerRadius = 15;
    self.mainView.layer.borderWidth = 2.0;
    self.mainView.layer.borderColor = [UIColor purpleColor].CGColor;
    self.mainView.hidden = YES; self.mainView.alpha = 0.0;
    [self addSubview:self.mainView];

    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(20, 20, 260, 30)];
    title.text = @"hyzz ffz // EXTERNAL";
    title.textColor = [UIColor magentaColor];
    title.font = [UIFont boldSystemFontOfSize:18];
    [self.mainView addSubview:title];

    UIButton *close = [UIButton buttonWithType:UIButtonTypeSystem];
    close.frame = CGRectMake(250, 15, 40, 30);
    [close setTitle:@"X" forState:UIControlStateNormal];
    [close addTarget:self action:@selector(hideMenu) forControlEvents:UIControlEventTouchUpInside];
    [self.mainView addSubview:close];

    [self addToggle:@"AIMBOT 100%" y:70 tag:1];
    [self addToggle:@"ESP BOX" y:140 tag:2];
    [self addToggle:@"FOV CIRCLE" y:210 tag:3];

    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(dragMenu:)];
    [self.mainView addGestureRecognizer:pan];
    return self;
}

- (void)addToggle:(NSString *)title y:(CGFloat)y tag:(int)tag {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = CGRectMake(20, y, 260, 45);
    btn.backgroundColor = [UIColor darkGrayColor];
    btn.layer.cornerRadius = 8; btn.tag = tag;
    [btn setTitle:[NSString stringWithFormat:@"%@ [OFF]", title] forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(toggleAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.mainView addSubview:btn];
}
- (void)toggleAction:(UIButton *)sender {
    bool state = false;
    if (sender.tag == 1) { g_Aimbot = !g_Aimbot; state = g_Aimbot; }
    if (sender.tag == 2) { g_ESP = !g_ESP; state = g_ESP; }
    if (sender.tag == 3) { g_FOV = !g_FOV; state = g_FOV; }
    NSString *base = sender.tag == 1 ? @"AIMBOT 100%" : (sender.tag == 2 ? @"ESP BOX" : @"FOV CIRCLE");
    [sender setTitle:[NSString stringWithFormat:@"%@ [%@]", base, state ? @"ON" : @"OFF"] forState:UIControlStateNormal];
    sender.backgroundColor = state ? [UIColor greenColor] : [UIColor darkGrayColor];
}
- (void)showMenu { self.mainView.hidden = NO; [UIView animateWithDuration:0.2 animations:^{ self.mainView.alpha = 1.0; }]; }
- (void)hideMenu { [UIView animateWithDuration:0.2 animations:^{ self.mainView.alpha = 0.0; } completion:^(BOOL finished) { self.mainView.hidden = YES; }]; }
- (void)dragMenu:(UIPanGestureRecognizer *)g { CGPoint p = [g translationInView:self]; g.view.center = CGPointMake(g.view.center.x + p.x, g.view.center.y + p.y); [g setTranslation:CGPointZero inView:self]; }
- (void)dragBtn:(UIPanGestureRecognizer *)g { CGPoint p = [g translationInView:self]; g.view.center = CGPointMake(g.view.center.x + p.x, g.view.center.y + p.y); [g setTranslation:CGPointZero inView:self]; }
@end

// ==========================================
// 3. HOOK DO AIMBOT
// ==========================================
static void (*orig_SetAimRotation)(void*, Quaternion);
static void hook_SetAimRotation(void* instance, Quaternion rotation) {
    if (g_Aimbot) {
        // FILL: A mira real vai aqui depois.
    }
    orig_SetAimRotation(instance, rotation);
}

// ==========================================
// 4. O LOOP QUE FAZ O PAINEL APARECER
// ==========================================
static void attachPanelToWindow() {
    UIWindow *keyWindow = nil;
    for (UIWindow *window in [UIApplication sharedApplication].windows) {
        if (window.isKeyWindow) { keyWindow = window; break; }
    }
    
    if (keyWindow) {
        if ([keyWindow viewWithTag:9999]) return;
        
        HyzzPanel *panel = [[HyzzPanel alloc] initWithFrame:keyWindow.bounds];
        panel.tag = 9999;
        [keyWindow addSubview:panel];
        [keyWindow bringSubviewToFront:panel];
    } else {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            attachPanelToWindow();
        });
    }
}

%ctor {
    MSHookFunction((void*)&_dyld_get_image_name, (void*)hook_dyld_get_image_name, (void**)&orig_dyld_get_image_name);
    MSHookFunction((void*)&objc_copyImageNames, (void*)hook_objc_copyImageNames, (void**)&orig_objc_copyImageNames);
    MSHookFunction((void*)&ptrace, (void*)hook_ptrace, (void**)&orig_ptrace);
    MSHookFunction((void*)&sysctl, (void*)hook_sysctl, (void**)&orig_sysctl);
    MSHookFunction((void*)&getenv, (void*)hook_getenv, (void**)&orig_getenv);

    uintptr_t unityBase = 0;
    for (int i = 0; i < _dyld_image_count(); i++) {
        const char* name = _dyld_get_image_name(i);
        if (name && strstr(name, "UnityFramework")) {
            unityBase = _dyld_get_image_vmaddr_slide(i);
            break;
        }
    }
    if (unityBase != 0) {
        uintptr_t setAimRotationAddr = unityBase + 0x11a5820;
        MSHookFunction((void*)setAimRotationAddr, (void*)hook_SetAimRotation, (void**)&orig_SetAimRotation);
    }

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        attachPanelToWindow();
    });
}
