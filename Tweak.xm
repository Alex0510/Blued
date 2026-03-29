#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>

#pragma mark - 模型（假设与原应用一致）

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
static CLLocation *currentLocation;   // 存储当前用户位置（可选）

#pragma mark - 安全获取 KeyWindow

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

#pragma mark - 地图页面（自带定位与标注）

@interface RadarVC : UIViewController <MKMapViewDelegate, CLLocationManagerDelegate>
@property (nonatomic, strong) MKMapView *mapView;
@property (nonatomic, strong) CLLocationManager *locationManager;
@end

@implementation RadarVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    // 创建地图
    self.mapView = [[MKMapView alloc] initWithFrame:self.view.bounds];
    self.mapView.delegate = self;
    self.mapView.showsUserLocation = YES;   // 显示蓝点
    self.mapView.userTrackingMode = MKUserTrackingModeFollow;
    [self.view addSubview:self.mapView];
    
    // 请求定位权限（如果还没有）
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    [self.locationManager requestWhenInUseAuthorization];
    [self.locationManager startUpdatingLocation];
    
    // 获取所有其他用户的标注
    __block NSArray *snapshot = nil;
    if (userQueue) {
        dispatch_sync(userQueue, ^{
            snapshot = [users copy];
        });
    } else {
        snapshot = @[];
    }
    
    for (BDUserInfo *u in snapshot) {
        MKPointAnnotation *ann = [[MKPointAnnotation alloc] init];
        ann.coordinate = CLLocationCoordinate2DMake(u.latitude, u.longitude);
        ann.title = u.name ?: @"User";
        [self.mapView addAnnotation:ann];
    }
    
    // 添加关闭按钮
    UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    closeBtn.frame = CGRectMake(20, 60, 80, 40);
    [closeBtn setTitle:@"关闭" forState:UIControlStateNormal];
    [closeBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    closeBtn.backgroundColor = [UIColor darkGrayColor];
    closeBtn.layer.cornerRadius = 8;
    [closeBtn addTarget:self action:@selector(closeMap) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:closeBtn];
}

- (void)closeMap {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    CLLocation *loc = locations.lastObject;
    if (loc) {
        currentLocation = loc;
        // 可选：在地图上添加一个自定义的当前用户标注
        static BOOL hasUserAnnotation = NO;
        if (!hasUserAnnotation) {
            MKPointAnnotation *myAnn = [[MKPointAnnotation alloc] init];
            myAnn.coordinate = loc.coordinate;
            myAnn.title = @"我的位置";
            [self.mapView addAnnotation:myAnn];
            hasUserAnnotation = YES;
        }
        // 停止持续更新以节省电量
        [manager stopUpdatingLocation];
    }
}

// 可选：自定义标注视图
- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    if ([annotation isKindOfClass:[MKUserLocation class]]) {
        return nil; // 使用默认蓝点
    }
    static NSString *reuseId = @"pin";
    MKPinAnnotationView *pin = (MKPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:reuseId];
    if (!pin) {
        pin = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:reuseId];
        pin.canShowCallout = YES;
        pin.animatesDrop = NO;
    }
    return pin;
}

@end

#pragma mark - 悬浮窗管理

void showMap() {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *key = getKeyWindow();
        if (!key) {
            NSLog(@"[Radar] No key window");
            return;
        }
        UIViewController *root = key.rootViewController;
        while (root.presentedViewController) {
            root = root.presentedViewController;
        }
        RadarVC *vc = [[RadarVC alloc] init];
        vc.modalPresentationStyle = UIModalPresentationFullScreen;
        [root presentViewController:vc animated:YES completion:^{
            NSLog(@"[Radar] Map presented");
        }];
    });
}

void createFloatUI() {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        userQueue = dispatch_queue_create("com.radar.userQueue", DISPATCH_QUEUE_SERIAL);
        users = [NSMutableArray new];
        
        dispatch_async(dispatch_get_main_queue(), ^{
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
            floatWindow.windowLevel = UIWindowLevelStatusBar + 1;
            floatWindow.backgroundColor = [UIColor clearColor];
            floatWindow.hidden = NO;
            
            UIViewController *vc = [[UIViewController alloc] init];
            vc.view.backgroundColor = [UIColor clearColor];
            floatWindow.rootViewController = vc;
            
            UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
            btn.frame = CGRectMake(0, 0, 60, 60);
            btn.layer.cornerRadius = 30;
            btn.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.8];
            [btn setTitle:@"雷达" forState:UIControlStateNormal];
            [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [btn addTarget:self action:@selector(openMapAction) forControlEvents:UIControlEventTouchUpInside];
            [vc.view addSubview:btn];
            
            UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:vc action:@selector(pan:)];
            [btn addGestureRecognizer:pan];
            
            [floatWindow makeKeyAndVisible];
            NSLog(@"[Radar] Float window created");
        });
    });
}

#pragma mark - 按钮点击处理（通过响应链找到悬浮窗的 VC）

// 由于 Category 方法可能不被调用，这里直接在全局函数中实现点击逻辑，并通过通知或 block 调用
static void (^openMapBlock)(void) = ^{
    showMap();
};

// 扩展 UIViewController 添加方法，但确保其能被调用
@interface UIViewController (RadarFloat)
- (void)openMapAction;
- (void)pan:(UIPanGestureRecognizer *)gesture;
@end

@implementation UIViewController (RadarFloat)
- (void)openMapAction {
    NSLog(@"[Radar] openMapAction called");
    showMap();
}

- (void)pan:(UIPanGestureRecognizer *)gesture {
    UIView *view = gesture.view;
    CGPoint t = [gesture translationInView:view.superview];
    view.center = CGPointMake(view.center.x + t.x, view.center.y + t.y);
    [gesture setTranslation:CGPointZero inView:view.superview];
}
@end

#pragma mark - 数据收集（线程安全）

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
            NSLog(@"[Radar] Added user: %@ at (%f,%f)", u.name, u.latitude, u.longitude);
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