#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>

#pragma mark - 模型

@interface BDUserInfo : NSObject
@property NSString *name;
@property long long age;
@property long long role;
@property NSString *descriptionField;
@property double latitude;
@property double longitude;
@end

@interface BDHomeViewController : UIViewController
@property BDUserInfo *userInfo;
@end

#pragma mark - 全局

static UIWindow *floatWindow;
static UIButton *floatBtn;
static NSMutableArray *users;

#pragma mark - 安全打开URL（已修复废弃问题）

void openMap(double lat, double lon) {
    NSString *url = [NSString stringWithFormat:@"http://maps.apple.com/?ll=%f,%f", lat, lon];
    NSURL *nsurl = [NSURL URLWithString:url];

    [[UIApplication sharedApplication] openURL:nsurl
                                       options:@{}
                             completionHandler:nil];
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

    for (BDUserInfo *u in users) {
        MKPointAnnotation *ann = [MKPointAnnotation new];
        ann.coordinate = CLLocationCoordinate2DMake(u.latitude, u.longitude);
        ann.title = u.name;
        [map addAnnotation:ann];
    }
}

@end

#pragma mark - UI

void showMap() {
    UIWindow *key = UIApplication.sharedApplication.keyWindow;
    UIViewController *root = key.rootViewController;

    RadarVC *vc = [RadarVC new];
    [root presentViewController:vc animated:YES completion:nil];
}

void createFloat() {
    if (floatWindow) return;

    users = [NSMutableArray new];

    floatWindow = [[UIWindow alloc] initWithFrame:CGRectMake(50, 200, 60, 60)];
    floatWindow.windowLevel = UIWindowLevelAlert + 1;

    UIViewController *vc = [UIViewController new];
    floatWindow.rootViewController = vc;

    floatBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    floatBtn.frame = floatWindow.bounds;
    floatBtn.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.8];
    floatBtn.layer.cornerRadius = 30;
    [floatBtn setTitle:@"雷达" forState:UIControlStateNormal];

    [floatBtn addTarget:vc action:@selector(openMapAction) forControlEvents:UIControlEventTouchUpInside];

    [floatWindow addSubview:floatBtn];

    floatWindow.hidden = NO;

    // 拖动
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:vc action:@selector(pan:)];
    [floatBtn addGestureRecognizer:pan];
}

#pragma mark - 事件扩展

@interface UIViewController (Radar)
@end

@implementation UIViewController (Radar)

- (void)openMapAction {
    showMap();
}

- (void)pan:(UIPanGestureRecognizer *)p {
    UIView *v = p.view;
    CGPoint t = [p translationInView:v.superview];
    v.center = CGPointMake(v.center.x + t.x, v.center.y + t.y);
    [p setTranslation:CGPointZero inView:v.superview];
}

@end

#pragma mark - 数据处理

void addUser(BDUserInfo *u) {
    if (!u) return;

    for (BDUserInfo *x in users) {
        if (x.latitude == u.latitude && x.longitude == u.longitude) return;
    }

    [users addObject:u];
}

#pragma mark - Hook

%hook BDHomeViewController

- (void)setUserInfo:(BDUserInfo *)userInfo {
    %orig;

    if (userInfo) {
        createFloat();
        addUser(userInfo);
    }
}

- (void)viewDidLoad {
    %orig;

    if (self.userInfo) {
        createFloat();
        addUser(self.userInfo);
    }
}

%end