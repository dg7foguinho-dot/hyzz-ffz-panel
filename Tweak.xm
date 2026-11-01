#import <UIKit/UIKit.h>
#import <substrate.h>
#import <mach-o/dyld.h>
#import <string.h>

static bool g_Aimbot = false;
static bool g_ESP = false;
static bool g_FOV = false;
static float g_FOVRadius = 150.0f;

struct Vector3 { float x, y, z; };
struct Quaternion { float x, y, z, w; };

// ==========================================
// MODO FURTIVO (STEALTH)
// ==========================================
static const char* (*orig_dyld_get_image_name)(uint32_t image_index);
static const char* hook_dyld_get_image_name(uint32_t image_index) {
    const char* name = orig_dyld_get_image_name(image_index);
    if (name && (strstr(name, "HyzzFFZ") || strstr(name, "substrate") || strstr(name, "frida"))) {
        return "/usr/lib/libSystem.B.dylib"; // Engana o anti-cheat
    }
    return name;
}

// ==========================================
// UI
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

@interface HyzzPanel : UIWindow
@property (nonatomic, strong) UIView *mainView;
@property (nonatomic, strong) UIButton *openMenuBtn;
@end

@implementation HyzzPanel
- (instancetype)initWithWindowScene:(UIWindowScene *)windowScene {
    self = [super initWithWindowScene:windowScene];
    if (!self) return nil;
    self.frame = windowScene.coordinateSpace.bounds;
    self.windowLevel = UIWindowLevelAlert + 100;
    self.backgroundColor = [UIColor clearColor];
    self.rootViewController = [UIViewController new];
    self.hidden = NO;
    
    FOVOverlay *fov = [[FOVOverlay alloc] initWithFrame:self.bounds];
    fov.userInteractionEnabled = NO; fov.backgroundColor = [UIColor clearColor];
    [self.rootViewController.view addSubview:fov];
    ESPOverlay *esp = [[ESPOverlay alloc] initWithFrame:self.bounds];
    esp.userInteractionEnabled = NO; esp.backgroundColor = [UIColor clearColor];
    [self.rootViewController.view addSubview:esp];

    self.openMenuBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.openMenuBtn.frame = CGRectMake(20, 100, 60, 60);
    self.openMenuBtn.backgroundColor = [UIColor colorWithRed:0.5 green:0.0 blue:0.5 alpha:1.0];
    self.openMenuBtn.layer.cornerRadius = 30;
    [self.openMenuBtn setTitle:@"HYZ" forState:UIControlStateNormal];
    [self.openMenuBtn addTarget:self action:@selector(showMenu) forControlEvents:UIControlEventTouchUpInside];
    [self.rootViewController.view addSubview:self.openMenuBtn];

    UIPanGestureRecognizer *panBtn = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(dragBtn:)];
    [self.openMenuBtn addGestureRecognizer:panBtn];

    self.mainView = [[UIView alloc] initWithFrame:CGRectMake(20, 150, 300, 350)];
    self.mainView.backgroundColor = [UIColor blackColor];
    self.mainView.layer.cornerRadius = 15;
    self.mainView.layer.borderWidth = 2.0;
    self.mainView.layer.borderColor = [UIColor purpleColor].CGColor;
    self.mainView.hidden = YES; self.mainView.alpha = 0.0;
    [self.rootViewController.view addSubview:self.mainView];

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
// INICIALIZAÇÃO SEGURA
// ==========================================
%ctor {
    // Ativa o modo furtivo escondendo o nome da dylib
    MSHookFunction((void *)&_dyld_get_image_name, (void *)hook_dyld_get_image_name, (void **)&orig_dyld_get_image_name);

    // Espera o jogo carregar a cena para colocar o painel
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        UIWindowScene *activeScene = nil;
        for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if ([scene isKindOfClass:[UIWindowScene class]] && scene.activationState == UISceneActivationStateForegroundActive) {
                activeScene = (UIWindowScene *)scene;
                break;
            }
        }
        if (activeScene) {
            HyzzPanel *panel = [[HyzzPanel alloc] initWithWindowScene:activeScene];
            [panel makeKeyAndVisible];
        }
    });
}
