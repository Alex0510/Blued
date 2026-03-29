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

#pragma mark - 安全打开地图

void openMap(double lat, double lon) {
    NSString *urlStr = [NSString stringWithFormat:@"http://maps.apple.com/?ll=%f,%f", lat, lon];
    NSURL *url = [NSURL URLWithString:urlStr];
    [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
}

#pragma mark - 地图页面

@interface RadarVC : UIViewController <MKMapViewDelegate, CLLocationManagerDelegate>
@end

@implementation RadarVC {
    MKMapView *_mapView;
    CLLocationManager *_locationManager;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.whiteColor;
    
    _mapView = [[MKMapView alloc] initWithFrame:self.view.bounds];
    _mapView.delegate = self;
    _mapView.showsUserLocation = YES;
    _mapView.userTrackingMode = MKUserTrackingModeFollow;
    [self.view addSubview:_mapView];
    
    // 定位管理器
    _locationManager = [CLLocationManager new];
    _locationManager.delegate = self;
    [_locationManager requestWhenInUseAuthorization];
    [_locationManager startUpdatingLocation];
    
    // 获取其他用户标注
    __block NSArray *snapshot = nil;
    if (userQueue) {
        dispatch_sync(userQueue, ^{
            snapshot = [users copy];
        });
    }
    for (BDUserInfo *u in snapshot) {
        MKPointAnnotation *ann = [MKPointAnnotation new];
        ann.coordinate = CLLocationCoordinate2DMake(u.latitude, u.longitude);
        ann.title = u.name ?: @"User";
        [_mapView addAnnotation:ann];
    }
    
    // 关闭按钮
    UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    closeBtn.frame = CGRectMake(20, 60, 80, 40);
    [closeBtn setTitle:@"关闭" forState:UIControlStateNormal];
    [closeBtn setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    closeBtn.backgroundColor = UIColor.darkGrayColor;
    closeBtn.layer.cornerRadius = 8;
    [closeBtn addTarget:self action:@selector(closeMap) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:closeBtn];
}

- (void)closeMap {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    [manager stopUpdatingLocation];
    CLLocation *loc = locations.lastObject;
    if (loc) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            MKPointAnnotation *myAnn = [MKPointAnnotation new];
            myAnn.coordinate = loc.coordinate;
            myAnn.title = @"我的位置";
            [_mapView addAnnotation:myAnn];
        });
    }
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    if ([annotation isKindOfClass:[MKUserLocation class]]) return nil;
    static NSString *pid = @"pin";
    MKPinAnnotationView *pin = (MKPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:pid];
    if (!pin) {
        pin = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:pid];
        pin.canShowCallout = YES;
    }
    return pin;
}

@end

#pragma mark - 悬浮窗管理

void showMap() {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *key = getKeyWindow();
        if (!key) return;
        UIViewController *root = key.rootViewController;
        while (root.presentedViewController) root = root.presentedViewController;
        RadarVC *vc = [RadarVC new];
        vc.modalPresentationStyle = UIModalPresentationFullScreen;
        [root presentViewController:vc animated:YES completion:nil];
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
            
            if (scene) floatWindow = [[UIWindow alloc] initWithWindowScene:scene];
            else floatWindow = [[UIWindow alloc] initWithFrame:CGRectMake(40, 200, 60, 60)];
            
            floatWindow.frame = CGRectMake(40, 200, 60, 60);
            floatWindow.windowLevel = UIWindowLevelStatusBar + 1;
            floatWindow.backgroundColor = UIColor.clearColor;
            floatWindow.hidden = NO;
            
            UIViewController *vc = [UIViewController new];
            vc.view.backgroundColor = UIColor.clearColor;
            floatWindow.rootViewController = vc;
            
            UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
            btn.frame = CGRectMake(0, 0, 60, 60);
            btn.layer.cornerRadius = 30;
            btn.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.8];
            [btn setTitle:@"雷达" forState:UIControlStateNormal];
            [btn setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
            // 修正 target：指向 vc，并实现 openMapAction 方法
            [btn addTarget:vc action:@selector(openMapAction) forControlEvents:UIControlEventTouchUpInside];
            [vc.view addSubview:btn];
            
            UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:vc action:@selector(pan:)];
            [btn addGestureRecognizer:pan];
            
            [floatWindow makeKeyAndVisible];
        });
    });
}

#pragma mark - UIViewController 扩展（实现拖拽和地图打开）

@interface UIViewController (RadarFloat)
- (void)openMapAction;
- (void)pan:(UIPanGestureRecognizer *)gesture;
@end

@implementation UIViewController (RadarFloat)

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
            if (users.count > 200) [users removeObjectsInRange:NSMakeRange(0, users.count - 200)];
        } @catch (NSException *e) {
            NSLog(@"[Radar] addUser error: %@", e);
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