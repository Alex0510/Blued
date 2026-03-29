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
static NSMutableArray<BDUserInfo *> *users;
static dispatch_queue_t userQueue;
static CLLocation *currentLocation; // 存储当前用户位置

#pragma mark - 安全获取 KeyWindow

UIWindow *getKeyWindow() {
    UIWindow *key = nil;
    if (@available(iOS 13.0, *)) {
        for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
            if (scene.activationState == UISceneActivationStateForegroundActive &&
                [scene isKindOfClass:[UIWindowScene class]]) {
                for (UIWindow *w in ((UIWindowScene *)scene).windows) {
                    if (w.isKeyWindow) return w;
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

#pragma mark - 自定义标注（显示用户名和距离）

@interface UserAnnotation : MKPointAnnotation
@property (nonatomic, strong) BDUserInfo *userInfo;
@property (nonatomic, assign) CLLocationDistance distance;
@end

@implementation UserAnnotation
@end

#pragma mark - 地图页面

@interface RadarVC : UIViewController <MKMapViewDelegate, CLLocationManagerDelegate>
@end

@implementation RadarVC {
    MKMapView *_mapView;
    CLLocationManager *_locationManager;
    BOOL _hasCentered;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.whiteColor;
    
    _mapView = [[MKMapView alloc] initWithFrame:self.view.bounds];
    _mapView.delegate = self;
    _mapView.showsUserLocation = YES;
    _mapView.userTrackingMode = MKUserTrackingModeNone; // 避免自动跟随
    [self.view addSubview:_mapView];
    
    // 定位管理器
    _locationManager = [CLLocationManager new];
    _locationManager.delegate = self;
    [_locationManager requestWhenInUseAuthorization];
    [_locationManager startUpdatingLocation];
    
    // 从全局数组获取用户标注
    __block NSArray<BDUserInfo *> *snapshot = nil;
    if (userQueue) {
        dispatch_sync(userQueue, ^{
            snapshot = [users copy];
        });
    }
    [self addUserAnnotations:snapshot];
    
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

- (void)addUserAnnotations:(NSArray<BDUserInfo *> *)userList {
    for (BDUserInfo *u in userList) {
        UserAnnotation *ann = [UserAnnotation new];
        ann.coordinate = CLLocationCoordinate2DMake(u.latitude, u.longitude);
        ann.title = u.name ?: @"用户";
        ann.userInfo = u;
        // 距离稍后计算（等定位更新后）
        [_mapView addAnnotation:ann];
    }
}

- (void)updateDistancesAndRegion {
    if (!currentLocation) return;
    
    // 更新所有自定义标注的距离
    for (id<MKAnnotation> ann in _mapView.annotations) {
        if ([ann isKindOfClass:[UserAnnotation class]]) {
            UserAnnotation *userAnn = (UserAnnotation *)ann;
            CLLocation *userLoc = [[CLLocation alloc] initWithLatitude:userAnn.coordinate.latitude longitude:userAnn.coordinate.longitude];
            userAnn.distance = [currentLocation distanceFromLocation:userLoc];
            // 动态修改 subtitle 显示距离
            if (userAnn.distance < 1000) {
                userAnn.subtitle = [NSString stringWithFormat:@"%.0f米", userAnn.distance];
            } else {
                userAnn.subtitle = [NSString stringWithFormat:@"%.1f公里", userAnn.distance / 1000.0];
            }
        }
    }
    
    // 刷新标注视图（重新加载 subtitle）
    for (id<MKAnnotation> ann in _mapView.annotations) {
        if (![ann isKindOfClass:[MKUserLocation class]]) {
            MKAnnotationView *view = [_mapView viewForAnnotation:ann];
            [view.annotation setCoordinate:view.annotation.coordinate]; // 触发更新
        }
    }
    
    // 调整地图区域以包含所有标注和用户位置（只执行一次）
    if (!_hasCentered && _mapView.annotations.count > 0) {
        _hasCentered = YES;
        MKMapRect zoomRect = MKMapRectNull;
        for (id<MKAnnotation> ann in _mapView.annotations) {
            MKMapPoint point = MKMapPointForCoordinate(ann.coordinate);
            MKMapRect pointRect = MKMapRectMake(point.x, point.y, 0.1, 0.1);
            zoomRect = MKMapRectUnion(zoomRect, pointRect);
        }
        // 添加当前用户位置
        if (_mapView.userLocation.coordinate.latitude != 0) {
            MKMapPoint userPoint = MKMapPointForCoordinate(_mapView.userLocation.coordinate);
            MKMapRect userRect = MKMapRectMake(userPoint.x, userPoint.y, 0.1, 0.1);
            zoomRect = MKMapRectUnion(zoomRect, userRect);
        }
        [_mapView setVisibleMapRect:zoomRect edgePadding:UIEdgeInsetsMake(50, 50, 50, 50) animated:YES];
    }
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    CLLocation *loc = locations.lastObject;
    if (loc && !currentLocation) {
        currentLocation = loc;
        [self updateDistancesAndRegion];
        [manager stopUpdatingLocation]; // 一次即可
    }
}

#pragma mark - MKMapViewDelegate

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    if ([annotation isKindOfClass:[MKUserLocation class]]) {
        return nil; // 使用系统蓝点
    }
    static NSString *reuseId = @"UserAnnotation";
    MKPinAnnotationView *pin = (MKPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:reuseId];
    if (!pin) {
        pin = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:reuseId];
        pin.canShowCallout = YES;
        pin.animatesDrop = NO;
        pin.pinTintColor = [UIColor redColor]; // 其他用户用红色
        // 添加右侧详细信息按钮
        UIButton *detailBtn = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
        pin.rightCalloutAccessoryView = detailBtn;
    } else {
        pin.annotation = annotation;
    }
    return pin;
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control {
    if ([view.annotation isKindOfClass:[UserAnnotation class]]) {
        UserAnnotation *userAnn = (UserAnnotation *)view.annotation;
        NSString *message = [NSString stringWithFormat:@"昵称：%@\n经纬度：%.6f, %.6f\n距离：%@",
                             userAnn.userInfo.name ?: @"未知",
                             userAnn.coordinate.latitude,
                             userAnn.coordinate.longitude,
                             userAnn.subtitle ?: @"未知"];
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"用户详情" message:message preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"关闭" style:UIAlertActionStyleCancel handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

// 当地图显示用户位置后，再次尝试调整区域
- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation {
    if (!_hasCentered) {
        [self updateDistancesAndRegion];
    }
}

- (void)closeMap {
    [self dismissViewControllerAnimated:YES completion:nil];
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
            [btn addTarget:vc action:@selector(openMapAction) forControlEvents:UIControlEventTouchUpInside];
            [vc.view addSubview:btn];
            
            UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:vc action:@selector(pan:)];
            [btn addGestureRecognizer:pan];
            
            [floatWindow makeKeyAndVisible];
        });
    });
}

#pragma mark - UIViewController 扩展

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
            NSLog(@"[Radar] 已添加用户: %@ (%.6f, %.6f)", u.name, u.latitude, u.longitude);
        } @catch (NSException *e) {
            NSLog(@"[Radar] 添加用户失败: %@", e);
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