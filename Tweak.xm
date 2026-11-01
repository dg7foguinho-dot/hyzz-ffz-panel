#import <UIKit/UIKit.h>
#import <substrate.h>

// ==========================================
// VARIÁVEIS DO CHEAT
// ==========================================
static bool g_Aimbot = false;
static bool g_ESP = false;
static bool g_FOV = false;
static float g_FOVRadius = 150.0f;

// ==========================================
// FOV OVERLAY
// ==========================================
@interface FOVOverlay : UIView
@end
@implementation FOVOverlay
- (void)drawRect:(CGRect)rect {
    if (!g_FOV) return;
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSetStrokeColorWithColor(ctx, [UIColor colorWithRed:0.0 green:1.0 blue:0.0 alpha:0.8].CGColor);
    CGContextSetLineWidth(ctx, 2.0);
    CGRect circleRect = CGRectMake(rect.size.width/2 - g_FOVRadius, rect.size.height/2 - g_FOVRadius, g_FOVRadius*2, g_FOVRadius*2);
    CGContextStrokeEllipseInRect(ctx, circleRect);
}
@end

// ==========================================
// ESP OVERLAY
// ==========================================
@interface ESPOverlay : UIView
@property (nonatomic, strong) CADisplayLink *displayLink;
@end
@implementation ESPOverlay
- (instancetype)init {
    self = [super init];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.userInteractionEnabled = NO;
        self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(update)];
        [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    }
    return self;
}
- (void)update { if (g_ESP) [self setNeedsDisplay]; }
- (void)drawRect:(CGRect)rect {
    if (!g_ESP) return;
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSetStrokeColorWithColor(ctx, [UIColor redColor].CGColor);
    CGContextSetLineWidth(ctx, 1.5);
    // Desenho de teste (Caixa no meio da tela)
    CGRect enemyBox = CGRectMake(rect.size.width/2 - 30, rect.size.height/2 - 80, 60, 160);
    CGContextStrokeRect(ctx, enemyBox);
    CGContextMoveToPoint(ctx, rect.size.width/2, rect.size.height);
    CGContextAddLineToPoint(ctx, rect.size.width/2, rect.size.height/2 + 80);
    CGContextStrokePath(ctx);
}
@end

// ==========================================
// PAINEL PRINCIPAL
// ==========================================
@interface HyzzPanel : UIWindow
@property (nonatomic, strong) UIView *mainView;
@property (nonatomic, strong) UIButton *openMenuBtn;
@end

@implementation HyzzPanel

- (instancetype)init {
    self = [super initWithFrame:[UIScreen mainScreen].bounds];
    if (!self) return nil;
    self.windowLevel = UIWindowLevelAlert + 100;
    self.backgroundColor = [UIColor clearColor];
    self.rootViewController = [UIViewController new];
    self.hidden = NO;

    FOVOverlay *fov = [[FOVOverlay alloc] initWithFrame:self.bounds];
    fov.userInteractionEnabled = NO;
    fov.backgroundColor = [UIColor clearColor];
    [self.rootViewController.view addSubview:fov];

    ESPOverlay *esp = [[ESPOverlay alloc] initWithFrame:self.bounds];
    [self.rootViewController.view addSubview:esp];

    // Botão flutuante (HYZ)
    self.openMenuBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.openMenuBtn.frame = CGRectMake(20, 100, 60, 60);
    self.openMenuBtn.backgroundColor = [UIColor colorWithRed:0.2 green:0.0 blue:0.3 alpha:0.9];
    self.openMenuBtn.layer.cornerRadius = 30;
    self.openMenuBtn.layer.borderWidth = 2;
    self.openMenuBtn.layer.borderColor = [UIColor magentaColor].CGColor;
    [self.openMenuBtn setTitle:@"HYZ" forState:UIControlStateNormal];
    self.openMenuBtn.titleLabel.font = [UIFont boldSystemFontOfSize:14];
    [self.openMenuBtn addTarget:self action:@selector(showMenu) forControlEvents:UIControlEventTouchUpInside];
    [self.rootViewController.view addSubview:self.openMenuBtn];

    // Suporte pra arrastar o botão
    UIPanGestureRecognizer *panBtn = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(dragBtn:)];
    [self.openMenuBtn addGestureRecognizer:panBtn];

    [self setupMenu];
    return self;
}

- (void)setupMenu {
    self.mainView = [[UIView alloc] initWithFrame:CGRectMake(20, 120, 320, 380)];
    self.mainView.backgroundColor = [UIColor colorWithRed:0.05 green:0.05 blue:0.08 alpha:0.95];
    self.mainView.layer.cornerRadius = 20;
    self.mainView.layer.borderWidth = 1;
    self.mainView.layer.borderColor = [UIColor colorWithWhite:0.3 alpha:0.5].CGColor;
    self.mainView.hidden = YES;
    self.mainView.alpha = 0.0;
    [self.rootViewController.view addSubview:self.mainView];

    // TÍTULO COM O TEU NOME
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(20, 20, 280, 30)];
    title.text = @"hyzz ffz // EXTERNAL";
    title.textColor = [UIColor whiteColor];
    title.font = [UIFont boldSystemFontOfSize:18];
    [self.mainView addSubview:title];

    UIButton *close = [UIButton buttonWithType:UIButtonTypeSystem];
    close.frame = CGRectMake(270, 15, 40, 30);
    [close setTitle:@"✕" forState:UIControlStateNormal];
    [close setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    close.titleLabel.font = [UIFont boldSystemFontOfSize:20];
    [close addTarget:self action:@selector(hideMenu) forControlEvents:UIControlEventTouchUpInside];
    [self.mainView addSubview:close];

    UIView *line = [[UIView alloc] initWithFrame:CGRectMake(20, 60, 280, 1)];
    line.backgroundColor = [UIColor colorWithWhite:0.2 alpha:1];
    [self.mainView addSubview:line];

    // BOTÕES
    [self addToggle:@"AIMBOT 100%" y:80 tag:1];
    [self addToggle:@"ESP BOX" y:150 tag:2];
    [self addToggle:@"FOV CIRCLE" y:220 tag:3];

    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(dragMenu:)];
    [self.mainView addGestureRecognizer:pan];
}

- (void)addToggle:(NSString *)title y:(CGFloat)y tag:(int)tag {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = CGRectMake(20, y, 280, 50);
    btn.backgroundColor = [UIColor colorWithWhite:0.12 alpha:1];
    btn.layer.cornerRadius = 10;
    btn.tag = tag;
    [btn setTitle:[NSString stringWithFormat:@"  %@  [ OFF ]", title] forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
    btn.titleLabel.font = [UIFont boldSystemFontOfSize:14];
    btn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [btn addTarget:self action:@selector(toggleAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.mainView addSubview:btn];
}

- (void)toggleAction:(UIButton *)sender {
    bool state = false;
    if (sender.tag == 1) { g_Aimbot = !g_Aimbot; state = g_Aimbot; }
    if (sender.tag == 2) { g_ESP = !g_ESP; state = g_ESP; }
    if (sender.tag == 3) { g_FOV = !g_FOV; state = g_FOV; }

    NSString *baseTitle = sender.tag == 1 ? @"AIMBOT 100%" : (sender.tag == 2 ? @"ESP BOX" : @"FOV CIRCLE");
    NSString *status = state ? @"[ ON ]" : @"[ OFF ]";
    [sender setTitle:[NSString stringWithFormat:@"  %@  %@", baseTitle, status] forState:UIControlStateNormal];
    sender.backgroundColor = state ? [UIColor colorWithRed:0.1 green:0.4 blue:0.1 alpha:1] : [UIColor colorWithWhite:0.12 alpha:1];
}

- (void)showMenu {
    self.mainView.hidden = NO;
    [UIView animateWithDuration:0.3 animations:^{
        self.mainView.alpha = 1.0;
        self.mainView.transform = CGAffineTransformMakeScale(1.0, 1.0);
    }];
}

- (void)hideMenu {
    [UIView animateWithDuration:0.3 animations:^{
        self.mainView.alpha = 0.0;
        self.mainView.transform = CGAffineTransformMakeScale(0.8, 0.8);
    } completion:^(BOOL finished) { self.mainView.hidden = YES; }];
}

- (void)dragMenu:(UIPanGestureRecognizer *)g {
    CGPoint p = [g translationInView:self];
    g.view.center = CGPointMake(g.view.center.x + p.x, g.view.center.y + p.y);
    [g setTranslation:CGPointZero inView:self];
}

- (void)dragBtn:(UIPanGestureRecognizer *)g {
    CGPoint p = [g translationInView:self];
    g.view.center = CGPointMake(g.view.center.x + p.x, g.view.center.y + p.y);
    [g setTranslation:CGPointZero inView:self];
}
@end

// ==========================================
// HOOKS
// ==========================================
static void (*orig_LookRotation)(void *quat, void *forward, void *up);
static void hook_LookRotation(void *quat, void *forward, void *up) {
    if (g_Aimbot) {
        // FILL: A lógica do Aimbot vai entrar aqui.
    }
    orig_LookRotation(quat, forward, up);
}

%ctor {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [[HyzzPanel new] makeKeyAndVisible];
    });
}
