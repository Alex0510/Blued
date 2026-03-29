#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>

#pragma mark - 模型

@interface BDUserInfo : NSObject
@property (nonatomic, strong) NSString *name;
@property (nonatomic, assign) double latitude;
@property (nonatomic, assign) double longitude;
@end

@interface BDHomeViewController : UIViewController
@property (nonatomic, strong) BDUserInfo *userInfo;
@end

#pragma mark - 全局

static UIWindow *floatWindow;
static NSMutableArray *users;
static dispatch_queue_t userQueue;

#pragma mark - 安全获取 KeyWindow（iOS13+适配）

UIWindow *getKeyWindow() {
    UIWindow *key = nil;
    if (@available(iOS 13.0, *)) {
        for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
            if (scene.activationState == UISceneActivationStateForegroundActive &&
                [scene isKindOfClass:[UIWindowScene class]]) {
                for (UIWindow *w in ((UIWindowScene *)scene).windows) {
                    if (w.isKeyWindow) {
                        return w;
                    }
                }
            }
        }
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        key = UIApplication.sharedApplication.keyWindow;
#pragma clang diagnostic pop
    }
    return key;
}

#pragma mark - 安全打开地图（无废弃API）

void openMap(double lat, double lon) {
    NSString *urlStr = [NSString stringWithFormat:@"http://maps.apple.com/?ll=%f,%f", lat, lon];
    NSURL *url = [NSURL URLWithString:urlStr];
    [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
}

#pragma mark - 地图页面

@interface RadarVC : UIViewController
@end

@implementation RadarVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.whiteColor;
    MKMapView *map = [[MKMapView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:map];
    
    __block NSArray *snapshot = nil;
    if (userQueue) {
        dispatch_sync(userQueue, ^{
            snapshot = [users copy];
        });
    } else {
        snapshot = @[];
    }
    
    for (BDUserInfo *u in snapshot) {
        MKPointAnnotation *ann = [MKPointAnnotation new];
        ann.coordinate = CLLocationCoordinate2DMake(u.latitude, u.longitude);
        ann.title = u.name ?: @"User";
        [map addAnnotation:ann];
    }
}

@end

#pragma mark - UI

void showMap() {
    UIWindow *key = getKeyWindow();
    if (!key) return;
    UIViewController *root = key.rootViewController;
    while (root.presentedViewController) {
        root = root.presentedViewController;
    }
    RadarVC *vc = [RadarVC new];
    [root presentViewController:vc animated:YES completion:nil];
}

void createFloatUI() {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // 初始化队列
        userQueue = dispatch_queue_create("com.radar.userQueue", DISPATCH_QUEUE_SERIAL);
        users = [NSMutableArray new];
        
        // 在主线程创建 UI
        dispatch_async(dispatch_get_main_queue(), ^{
            // 获取当前活跃的场景（iOS 13+ 必须关联 scene）
            UIWindowScene *scene = nil;
            if (@available(iOS 13.0, *)) {
                for (UIScene *s in UIApplication.sharedApplication.connectedScenes) {
                    if (s.activationState == UISceneActivationStateForegroundActive && [s isKindOfClass:[UIWindowScene class]]) {
                        scene = (UIWindowScene *)s;
                        break;
                    }
                }
            }
            
            if (scene) {
                floatWindow = [[UIWindow alloc] initWithWindowScene:scene];
            } else {
                floatWindow = [[UIWindow alloc] initWithFrame:CGRectMake(40, 200, 60, 60)];
            }
            
            floatWindow.frame = CGRectMake(40, 200, 60, 60);
            floatWindow.windowLevel = UIWindowLevelStatusBar + 1; // 高于状态栏
            floatWindow.backgroundColor = [UIColor clearColor];
            floatWindow.hidden = NO;
            
            UIViewController *vc = [UIViewController new];
            vc.view.backgroundColor = [UIColor clearColor];
            floatWindow.rootViewController = vc;
            
            UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
            btn.frame = CGRectMake(0, 0, 60, 60);
            btn.layer.cornerRadius = 30;
            btn.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.8];
            [btn setTitle:@"雷达" forState:UIControlStateNormal];
            [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [btn addTarget:vc action:@selector(openMapAction) forControlEvents:UIControlEventTouchUpInside];
            [vc.view addSubview:btn];
            
            UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:vc action:@selector(pan:)];
            [btn addGestureRecognizer:pan];
            
            [floatWindow makeKeyAndVisible]; // 确保显示
        });
    });
}

#pragma mark - 事件扩展

@interface UIViewController (RadarAction)
@end

@implementation UIViewController (RadarAction)

- (void)openMapAction {
    showMap();
}

- (void)pan:(UIPanGestureRecognizer *)gesture {
    UIView *view = gesture.view;
    CGPoint t = [gesture translationInView:view.superview];
    view.center = CGPointMake(view.center.x + t.x, view.center.y + t.y);
    [gesture setTranslation:CGPointZero inView:view.superview];
}

@end

#pragma mark - 数据（线程安全）

void addUser(BDUserInfo *u) {
    if (!u) return;
    if (!userQueue) createFloatUI();
    
    dispatch_sync(userQueue, ^{
        @try {
            for (BDUserInfo *x in users) {
                if (x.latitude == u.latitude && x.longitude == u.longitude) return;
            }
            [users addObject:u];
            if (users.count > 200) {
                [users removeObjectsInRange:NSMakeRange(0, users.count - 200)];
            }
        } @catch (NSException *exception) {
            NSLog(@"[Radar] addUser error: %@", exception);
        }
    });
}

#pragma mark - Hook

%hook BDHomeViewController

- (void)setUserInfo:(BDUserInfo *)userInfo {
    %orig;
    if (userInfo) {
        createFloatUI();
        addUser(userInfo);
    }
}

- (void)viewDidLoad {
    %orig;
    if (self.userInfo) {
        createFloatUI();
        addUser(self.userInfo);
    }
}

%end