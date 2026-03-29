#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

#pragma mark - 模型

@interface BDUserInfo : NSObject
@property NSString *name;
@property long long age;
@property long long role;
@property NSString *descriptionField;
@property double height;
@property double weight;
@property double latitude;
@property double longitude;
@end

@interface BDHomeViewController : UIViewController
@property BDUserInfo *userInfo;
@end

#pragma mark - 全局

static UIWindow *floatBall;
static UIView *panelView;
static UILabel *infoLabel;

static NSMutableDictionary *geoCache;     // 地理缓存
static NSMutableArray *historyUsers;      // 历史用户

static BOOL isExpanded = NO;

#pragma mark - 工具

NSString *getAddress(double lat, double lon, void(^callback)(NSString *addr)) {
    NSString *key = [NSString stringWithFormat:@"%.4f,%.4f", lat, lon];

    if (geoCache[key]) {
        callback(geoCache[key]);
        return nil;
    }

    CLGeocoder *geo = [CLGeocoder new];
    CLLocation *loc = [[CLLocation alloc] initWithLatitude:lat longitude:lon];

    [geo reverseGeocodeLocation:loc completionHandler:^(NSArray *arr, NSError *err) {
        NSString *addr = @"未知";

        if (!err && arr.count) {
            CLPlacemark *p = arr.firstObject;
            addr = [NSString stringWithFormat:@"%@%@%@",
                    p.administrativeArea ?: @"",
                    p.locality ?: @"",
                    p.subLocality ?: @""];
        }

        geoCache[key] = addr;
        callback(addr);
    }];

    return nil;
}

void openMap(double lat, double lon) {
    NSString *url = [NSString stringWithFormat:
        @"http://maps.apple.com/?ll=%f,%f", lat, lon];

    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
}

#pragma mark - UI

void togglePanel() {
    isExpanded = !isExpanded;
    panelView.hidden = !isExpanded;
}

void clearHistory() {
    [historyUsers removeAllObjects];
    infoLabel.text = @"已清空";
}

void createUI() {
    if (floatBall) return;

    geoCache = [NSMutableDictionary new];
    historyUsers = [NSMutableArray new];

    floatBall = [[UIWindow alloc] initWithFrame:CGRectMake(30, 200, 60, 60)];
    floatBall.windowLevel = UIWindowLevelAlert + 1;

    UIViewController *vc = [UIViewController new];
    floatBall.rootViewController = vc;
    floatBall.backgroundColor = UIColor.clearColor;

    UIButton *ball = [UIButton buttonWithType:UIButtonTypeSystem];
    ball.frame = floatBall.bounds;
    ball.layer.cornerRadius = 30;
    ball.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.8];
    [ball setTitle:@"⚡️" forState:UIControlStateNormal];
    [ball addTarget:nil action:@selector(togglePanelAction) forControlEvents:UIControlEventTouchUpInside];

    [floatBall addSubview:ball];

    // 面板
    panelView = [[UIView alloc] initWithFrame:CGRectMake(0, 70, 260, 320)];
    panelView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.9];
    panelView.layer.cornerRadius = 12;
    panelView.hidden = YES;

    // 文本
    infoLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, 240, 240)];
    infoLabel.textColor = UIColor.whiteColor;
    infoLabel.numberOfLines = 0;
    infoLabel.font = [UIFont systemFontOfSize:12];

    [panelView addSubview:infoLabel];

    // 按钮
    UIButton *mapBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    mapBtn.frame = CGRectMake(10, 270, 70, 30);
    [mapBtn setTitle:@"地图" forState:UIControlStateNormal];
    [mapBtn addTarget:nil action:@selector(openMapAction) forControlEvents:UIControlEventTouchUpInside];

    UIButton *clearBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    clearBtn.frame = CGRectMake(90, 270, 70, 30);
    [clearBtn setTitle:@"清空" forState:UIControlStateNormal];
    [clearBtn addTarget:nil action:@selector(clearAction) forControlEvents:UIControlEventTouchUpInside];

    [panelView addSubview:mapBtn];
    [panelView addSubview:clearBtn];

    [floatBall addSubview:panelView];

    floatBall.hidden = NO;

    // 拖动
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:vc action:@selector(handlePan:)];
    [ball addGestureRecognizer:pan];
}

#pragma mark - 分类扩展

@interface UIViewController (HookAction)
@end

@implementation UIViewController (HookAction)

- (void)togglePanelAction {
    togglePanel();
}

- (void)clearAction {
    clearHistory();
}

- (void)openMapAction {
    if (historyUsers.count == 0) return;

    BDUserInfo *u = historyUsers.lastObject;
    openMap(u.latitude, u.longitude);
}

- (void)handlePan:(UIPanGestureRecognizer *)pan {
    UIView *v = pan.view;
    CGPoint t = [pan translationInView:v.superview];
    v.center = CGPointMake(v.center.x + t.x, v.center.y + t.y);
    [pan setTranslation:CGPointZero inView:v.superview];
}

@end

#pragma mark - 更新数据

void updateData(BDUserInfo *info) {
    if (!info) return;

    [historyUsers addObject:info];

    getAddress(info.latitude, info.longitude, ^(NSString *addr) {

        NSString *txt = [NSString stringWithFormat:
            @"昵称:%@\n年龄:%lld\n性别:%@\n\n📍%@\n%.6f,%.6f\n\n历史:%lu人",
            info.name,
            info.age,
            info.role==0?@"男":@"女",
            addr,
            info.latitude,
            info.longitude,
            (unsigned long)historyUsers.count];

        dispatch_async(dispatch_get_main_queue(), ^{
            infoLabel.text = txt;
        });
    });
}

#pragma mark - Hook

%hook BDHomeViewController

- (void)setUserInfo:(BDUserInfo *)userInfo {
    %orig;

    if (userInfo) {
        createUI();
        updateData(userInfo);
    }
}

- (void)viewDidLoad {
    %orig;

    if (self.userInfo) {
        createUI();
        updateData(self.userInfo);
    }
}

%end