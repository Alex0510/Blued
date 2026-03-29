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
    
    // 获取 users 的快照副本，避免遍历过程中数据被修改
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
        // 初始化串行队列
        userQueue = dispatch_queue_create("com.radar.userQueue", DISPATCH_QUEUE_SERIAL);
        // 初始化数组（在队列外初始化即可，因为 dispatch_once 保证单线程）
        users = [NSMutableArray new];
        
        floatWindow = [[UIWindow alloc] initWithFrame:CGRectMake(40, 200, 60, 60)];
        floatWindow.windowLevel = UIWindowLevelAlert + 1;
        UIViewController *vc = [UIViewController new];
        floatWindow.rootViewController = vc;
        
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
        btn.frame = floatWindow.bounds;
        btn.layer.cornerRadius = 30;
        btn.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.8];
        [btn setTitle:@"雷达" forState:UIControlStateNormal];
        [btn addTarget:vc action:@selector(openMapAction) forControlEvents:UIControlEventTouchUpInside];
        [floatWindow addSubview:btn];
        
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:vc action:@selector(pan:)];
        [btn addGestureRecognizer:pan];
        
        floatWindow.hidden = NO;
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
    
    // 确保队列已存在（如果 createFloatUI 还未调用，则主动初始化）
    if (!userQueue) {
        createFloatUI();
    }
    
    // 在串行队列中执行添加和去重操作
    dispatch_sync(userQueue, ^{
        @try {
            // 去重
            for (BDUserInfo *x in users) {
                if (x.latitude == u.latitude && x.longitude == u.longitude) {
                    return;
                }
            }
            [users addObject:u];
            
            // 限制数组最大数量，防止内存无限增长（最多保留200个）
            if (users.count > 200) {
                NSRange removeRange = NSMakeRange(0, users.count - 200);
                [users removeObjectsInRange:removeRange];
            }
        } @catch (NSException *exception) {
            // 发生异常时静默处理，防止崩溃
            NSLog(@"[RadarPlugin] addUser exception: %@", exception);
        }
    });
}

#pragma mark - Hook

%hook BDHomeViewController

- (void)setUserInfo:(BDUserInfo *)userInfo {
    %orig;
    if (userInfo) {
        createFloatUI();   // 确保悬浮窗和队列已创建
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