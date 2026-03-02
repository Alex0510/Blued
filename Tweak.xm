#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

// ---- 广告相关 ----
@interface AppDelegateModel : NSObject
- (void)showSplashAd:(BOOL)isColdLaunch;
@end

@interface BDIndexPageCoversManager : NSObject
+ (instancetype)manager;
- (void)showSplashAd:(id)adModel currentWinAdModel:(id)winAdModel isColdLaunch:(BOOL)isColdLaunch finished:(id)finished;
@end


@interface BDNearbyDataAdapter : NSObject
- (void)insertBigMapAndOperationWithModel:(id)model
                               originalAd:(id)originalAd
                                 adBanner:(id)adBanner
                                 sortType:(id)sortType
                                isRefresh:(BOOL)isRefresh;
- (void)setAdmsArray:(id)arr;
- (void)setOriginUserAdsArray:(id)arr;
@end

// 附近交友列表数据管理器（含广告过滤用）
@interface BDNearbyMakeFriendsSubPageManager : NSObject
- (NSMutableArray *)listDataSources;
- (NSMutableArray *)gridDataSources;
@end

// 底栏配置（titles/normalImages/selectedImages 各含 5 个元素）
@interface BDTabBarConfig : NSObject
+ (NSArray *)titles;
+ (NSArray *)normalImages;
+ (NSArray *)selectedImages;
@end

// 底栏视图（含气泡方法）
@interface BluedTabBar : UIView
- (void)p_showFindBubble;
- (void)p_showLiveBubbble;
- (void)setBadgeValue:(unsigned long long)value atItemIndex:(long long)index;
@end

@interface GJIMMessageModel : NSObject
@property (nonatomic, assign) unsigned long long msgId;
@property (nonatomic, assign) unsigned long long type;
@property (nonatomic, assign) int fromId;
@property (nonatomic, assign) int sendTime;
@property (nonatomic, copy)   NSString *content;
@property (nonatomic, strong) NSDictionary *msgExtra;
@end

@interface GJIMSessionToken : NSObject
@property (nonatomic, assign) char sessionType;
@property (nonatomic, assign) long long sessionId;
+ (instancetype)gji_sessionTokenWithId:(long long)sessionId type:(char)type;
@end

@interface GJIMDBService : NSObject
+ (void)gji_getMessagesWithToken:(GJIMSessionToken *)token
                     isTempChat:(BOOL)isTempChat
                       complete:(void (^)(NSArray *))complete;
+ (void)gji_updateMessage:(GJIMMessageModel *)message;
@end

@interface GJIMSessionService : NSObject
+ (instancetype)sharedInstance;
- (void)addMessage:(GJIMMessageModel *)message;
- (void)updateMessage:(GJIMMessageModel *)message;
@end

@interface PushPackage : NSObject
@property (nonatomic, assign) unsigned long long messageType;
@property (nonatomic, assign) unsigned long long messageId;
@property (nonatomic, assign) int sessionId;
@property (nonatomic, assign) int from;
@property (nonatomic, assign) int timestamp;
@property (nonatomic, copy)   NSString *contents;
@property (nonatomic, copy)   NSString *name;
@property (nonatomic, strong) NSDictionary *msgExtra;
@end

@interface BDEncrypt : NSObject
+ (NSString *)decryptVideoUrl:(NSString *)url;
@end

@interface BDChatBasicCell : UITableViewCell
- (GJIMMessageModel *)message;
@end

// ============================================================
// Hook 1 — 拦截撤回消息 / 闪照推送
// ============================================================

%hook GJIMSessionService

- (id)p_handlePushPackage:(PushPackage *)pkg {
    NSLog(@"[BLUEDHOOK] Received push package: name: %@ type:%llu msgID:%llu from:%d content:%@",
          pkg.name, pkg.messageType, pkg.messageId, pkg.from, pkg.contents);

    switch (pkg.messageType) {

        // type 55: 对方发起撤回
        case 55: {
            NSLog(@"[BLUEDHOOK] %@ 撤回消息已被拦截。", pkg.name);

            GJIMSessionToken *token = [objc_getClass("GJIMSessionToken")
                gji_sessionTokenWithId:(long long)pkg.sessionId
                                  type:2];

            [objc_getClass("GJIMDBService")
                gji_getMessagesWithToken:token
                             isTempChat:NO
                               complete:^(NSArray *data) {

                GJIMMessageModel *targetMsg = nil;
                for (GJIMMessageModel *msg in data) {
                    if (msg.msgId == pkg.messageId) {
                        targetMsg = msg;
                        break;
                    }
                }

                if (targetMsg == nil) {
                    NSLog(@"[BLUEDHOOK] Warning: cannot find msgid %llu from %d, canceled tagging.",
                          pkg.messageId, pkg.from);
                    // 找不到原消息时，构造占位消息
                    for (GJIMMessageModel *msg in data) {
                        if (msg.fromId == pkg.from) {
                            targetMsg = msg;
                            break;
                        }
                    }
                    targetMsg.type    = 1;
                    targetMsg.msgId   = pkg.messageId;
                    targetMsg.sendTime = pkg.timestamp;
                    targetMsg.msgExtra = @{@"BLUED_HOOK_IS_RECALLED": @1};
                    targetMsg.content = @"对方撤回了一条消息，但已错过接收原始消息无法复原。";
                    [self addMessage:targetMsg];
                    return;
                }

                targetMsg.msgExtra = @{@"BLUED_HOOK_IS_RECALLED": @1};
                [self updateMessage:targetMsg];
            }];

            return nil; // 阻止原始撤回逻辑
        }

        // type 24: 闪照推送 → 转换为普通图片
        case 24: {
            NSLog(@"[BLUEDHOOK] 解密后URL: %@", [objc_getClass("BDEncrypt") decryptVideoUrl:pkg.contents]);
            pkg.messageType = 2;
            pkg.contents = [objc_getClass("BDEncrypt") decryptVideoUrl:pkg.contents];
            pkg.msgExtra  = @{@"BLUEDHOOK_IS_SNAPIMG": @1};
            break;
        }

        default:
            break;
    }

    return %orig(pkg);
}

%end

// ============================================================
// Hook 2 — 渲染时为撤回 / 闪照消息追加提示标签
// ============================================================

%hook UITableViewCell

- (UIView *)contentView {
    NSString *cellClassName = NSStringFromClass(self.class);
    if (![cellClassName containsString:@"PrivateOther"]) {
        return %orig;
    }

    UIView *cv = %orig;

    GJIMMessageModel *msg = [[(BDChatBasicCell *)self message] copy];
    if (msg == nil) {
        return cv;
    }

    NSLog(@"[BLUEDHOOK] type:%llu msgID:%llu content:%@  SNAPIMG:%@  RECALLED:%@",
          msg.type, msg.msgId, msg.content,
          [msg.msgExtra objectForKey:@"BLUEDHOOK_IS_SNAPIMG"],
          [msg.msgExtra objectForKey:@"BLUED_HOOK_IS_RECALLED"]);

    // 历史消息中未被处理的闪照（type==24）→ 实时转换
    if (msg.type == 24) {
        msg.type    = 2;
        msg.content = [objc_getClass("BDEncrypt") decryptVideoUrl:msg.content];
        msg.msgExtra = @{@"BLUEDHOOK_IS_SNAPIMG": @1};
        GJIMSessionService *svc = [objc_getClass("GJIMSessionService") sharedInstance];
        [svc updateMessage:msg];
        return cv;
    }

    NSArray *keys = [msg.msgExtra allKeys];
    if (msg.msgId == 0 || keys.count == 0) {
        return cv;
    }

    NSString *labelText = nil;
    if ([keys containsObject:@"BLUEDHOOK_IS_SNAPIMG"]) {
        labelText = @"该照片由闪照转换而成。";
    } else if ([keys containsObject:@"BLUED_HOOK_IS_RECALLED"]) {
        if ([msg.content containsString:@"burn-chatfiles"]) {
            labelText = @"该闪照已被对方撤回。";
        } else {
            labelText = @"对方尝试撤回此消息，已被阻止。";
        }
    }

    if (labelText == nil) {
        return cv;
    }

    // 计算标签位置
    CGFloat labelPosTop  = cv.frame.size.height - 12;
    CGFloat labelPosLeft = ([cv subviews].count > 2) ? [cv subviews][2].frame.origin.x : 0;

    switch (msg.type) {
        case 1:  labelPosTop -= 8; labelPosLeft += 12; break;
        case 3:  labelPosLeft += 12;                   break;
        default: break;
    }

    CGRect labelFrame = CGRectMake(labelPosLeft, labelPosTop, cv.frame.size.width, 12);

    NSInteger labelTag = 1069;
    UILabel *label = (UILabel *)[self viewWithTag:labelTag];
    if (label == nil) {
        label = [[UILabel alloc] init];
        label.tag          = labelTag;
        label.font         = [UIFont systemFontOfSize:9];
        label.textColor    = [UIColor grayColor];
        label.numberOfLines = 1;
    }
    label.frame = labelFrame;
    label.text  = labelText;
    [self addSubview:label];

    return cv;
}

%end

// ============================================================
// Hook 3 — 屏蔽开屏广告 (Splash Ad)
// ============================================================

// 入口层：无论冷启动还是热启动均经过此方法
%hook AppDelegateModel

- (void)showSplashAd:(BOOL)isColdLaunch {
    NSLog(@"[BLUEDHOOK] 开屏广告已被拦截 (isColdLaunch=%d)。", isColdLaunch);
    // 模拟 isIosForbiddenSplashAd==YES 的清理路径，防止启动页卡死
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [NSClassFromString(@"LaunchView") performSelector:NSSelectorFromString(@"splashUseFinish")];
    id server = [NSClassFromString(@"BDAdvertisementLoadingServer")
                    performSelector:NSSelectorFromString(@"sharedInstance")];
    [server performSelector:NSSelectorFromString(@"releaseTimerForSplashAdForbidden")];
    [server performSelector:NSSelectorFromString(@"dealSplashAdsFinish")];
#pragma clang diagnostic pop
}

%end

// 展示层兜底：直接跳过各渠道开屏展示，回调 finished
%hook BDIndexPageCoversManager

- (void)showSplashAd:(id)adModel
   currentWinAdModel:(id)winAdModel
        isColdLaunch:(BOOL)isColdLaunch
            finished:(id)finished {
    NSLog(@"[BLUEDHOOK] BDIndexPageCoversManager showSplashAd 已被拦截。");
    if (finished) ((void (^)(void))finished)();
}

%end

// ============================================================
// Hook 4 — 去除附近/交友列表 ADX 插屏广告及服务端原生广告
// ============================================================

%hook BDNearbyDataAdapter

// 屏蔽 ADX 广告插入：将 originalAd & adBanner 替换为 nil
- (void)insertBigMapAndOperationWithModel:(id)model
                               originalAd:(id)originalAd
                                 adBanner:(id)adBanner
                                 sortType:(id)sortType
                                isRefresh:(BOOL)isRefresh {
    %orig(model, nil, nil, sortType, isRefresh);
}

// 屏蔽服务端下发的 adms native 广告数组
- (void)setAdmsArray:(id)arr {
    // 拦截，不存储广告数组
}

// 屏蔽原生广告用户数组
- (void)setOriginUserAdsArray:(id)arr {
    // 拦截，不存储广告用户数组
}

%end

// ============================================================
// Hook 5 — 去除交友页 Banner 广告（BDDatingListHeaderView）
// ============================================================

%hook _TtC5Blued22BDDatingListHeaderView

// 隐藏 Banner 容器视图
- (void)setBannerContainerView:(UIView *)view {
    if (view) {
        view.hidden = YES;
    }
    %orig(view);
}

// 将 Banner 高度约束设为 0
- (void)setBannerContainerViewHeightCons:(NSLayoutConstraint *)cons {
    if (cons) {
        cons.constant = 0;
    }
    %orig(cons);
}

%end

// ============================================================
// Hook 6 — 去除广告轮播图（BDAdPicturesCarouselView）
// ============================================================

%hook _TtC5Blued24BDAdPicturesCarouselView

// 拦截广告数据加载，传入空数组
- (void)setAdDataArray:(NSArray *)arr {
    // 不加载广告数据
}

%end

// ============================================================
// Hook 7 — 过滤附近/交友列表广告条目
// 广告标识：
//   1. class = BDNearbyInsertFloor → 广告插入占位
//   2. class = SearchUsersData 且 is_ads != 0 → 原生广告用户
// ============================================================

static void BDHook_FilterNearbyListAds(BDNearbyMakeFriendsSubPageManager *mgr) {
    NSMutableArray *list = [mgr listDataSources];
    if (!list.count) return;

    Class insertFloorClass = NSClassFromString(@"BDNearbyInsertFloor");
    NSMutableIndexSet *toRemove = [NSMutableIndexSet indexSet];

    for (NSUInteger i = 0; i < list.count; i++) {
        id item = list[i];

        // 广告占位条目
        if (insertFloorClass && [item isKindOfClass:insertFloorClass]) {
            [toRemove addIndex:i];
            continue;
        }

        // SearchUsersData 原生广告用户（is_ads != 0）
        @try {
            NSNumber *isAds = [item valueForKey:@"is_ads"];
            if (isAds && [isAds integerValue] != 0) {
                [toRemove addIndex:i];
            }
        } @catch (...) {}
    }

    if (toRemove.count) {
        NSLog(@"[BLUEDHOOK] 过滤附近列表广告 %lu 条", (unsigned long)toRemove.count);
        [list removeObjectsAtIndexes:toRemove];
    }
}

%hook BDNearbyMakeFriendsSubPageManager

- (void)p_constructWithModel:(id)model {
    %orig;
    BDHook_FilterNearbyListAds(self);
}

- (void)insertNewUerListWithModel:(id)model {
    %orig;
    BDHook_FilterNearbyListAds(self);
}

%end

// ============================================================
// Hook 9 — 强制超级VIP (Blued X) 状态
// 分析结论：
//   vip_grade  0=非VIP  1=普通VIP  2=SVIP(Blued X)
//   is_vip_annual: 是否年费VIP
//   vip_exp_lvl:   VIP经验等级(SVIP最高档通常为5)
//   BDGlobalConfig.vip_type: 1=VIP在线  2=VIP即将过期  3=SVIP在线
//   LoginData 继承自 BDProfile，sharedInstance == 当前登录用户
//   只 hook LoginData 而非 BDProfile，避免影响其他用户的数据展示
// ============================================================

@interface BDProfile : NSObject
- (unsigned int)vip_grade;
- (BOOL)is_vip_annual;
- (unsigned long long)vip_exp_lvl;
- (long long)expire_type;
@end

@interface LoginData : BDProfile
+ (instancetype)sharedInstance;
@end

// 只 hook LoginData —— 它是当前登录用户的单例，继承自 BDProfile
%hook LoginData

- (unsigned int)vip_grade {
    return 2; // 2 = SVIP / Blued X
}

- (BOOL)is_vip_annual {
    return YES; // 年费 Blued X
}

- (unsigned long long)vip_exp_lvl {
    return 5; // 最高经验等级
}

- (long long)expire_type {
    return 0; // 0 = 未过期，不显示续费提示
}

%end

%hook BDGlobalConfig

// vip_type: 3 表示 SVIP/Blued X 状态（用于 flash 限制判定等）
- (long long)vip_type {
    return 3;
}

%end

// ============================================================
// Hook 11 — 绕过来访页 VIP 权限校验
// 分析结论：
//   RecentlyVisitorViewController.p_needToBuyVip 调用
//   [BDPrivilegeService isHavingThePrivilege: 12]
//   privilege 12 = 来访详情权限（查看具体來访用户）
//   与 vip_grade 是两套体系，必须单独 hook
// ============================================================

@interface BDPrivilegeService : NSObject
+ (BOOL)isHavingThePrivilege:(long long)privilegeId;
@end

%hook BDPrivilegeService

+ (BOOL)isHavingThePrivilege:(long long)privilegeId {
    return YES; // 直接放行所有权限检查
    // if (privilegeId == 12) {
    //     return YES; // 来访查看权限
    // }
    // return %orig(privilegeId);
}

%end

// ============================================================
// Hook 12 — 绕过图片相册保护（长按保存被禁止）
// 分析结论：
//   BDPhotoBrowserBasicCell.handleLongpress: 检查
//   [BDGlobalConfig shared].is_open_pic_ban_save
//   若为 YES → 发网络请求拿目标用户的 album_ban_save / feed_pic_ban_save
//   sheetViewShow 读取这两个标志位：=1 时改变保存按钮标题为"对方已开启相册保护"
//   三重绕过：is_open_pic_ban_save→NO，两个 ban 标志 getter→0
// ============================================================

@interface BDGlobalConfig : NSObject
+ (instancetype)shared;
- (BOOL)is_open_pic_ban_save;
@end

@interface BDPhotoBrowserBasicCell : UIView
- (unsigned int)album_ban_save;
- (unsigned int)feed_pic_ban_save;
@end

%hook BDGlobalConfig

- (BOOL)is_open_pic_ban_save {
    return NO; // 关闭相册保护功能开关，跳过网络检查，直接进入保存流程
}

%end

%hook BDPhotoBrowserBasicCell

// 相册来源的保护标志（isSelf 视图下的私密相册保护）
- (unsigned int)album_ban_save {
    return 0;
}

// 动态/个人页 Feed 图片保护标志
- (unsigned int)feed_pic_ban_save {
    return 0;
}

%end

// ============================================================
// Hook 10 — 过滤来访页面广告
// 广告条目类型：BDAdvertisementPlaceholder（混入 visitorArray）
// 策略：刷新/加载更多后，从 visitorArray 移除广告占位对象
// ============================================================

@interface RecentlyVisitorViewController : UIViewController
- (NSMutableArray *)visitorArray;
- (void)p_processWithNewVisitors:(id)visitors;
@end

// 过滤标准：uid == 0 的 UserVisitorData 条目即为广告占位
// （广告类名也是 UserVisitorData，与真实用户同类，但 uid=0）
static void BDHook_FilterVisitorAds(RecentlyVisitorViewController *vc) {
    NSMutableArray *arr = [vc visitorArray];
    if (!arr.count) return;

    NSMutableIndexSet *toRemove = [NSMutableIndexSet indexSet];
    for (NSUInteger i = 0; i < arr.count; i++) {
        id item = arr[i];
        long long uid = 0;
        @try { uid = [[item valueForKey:@"uid"] longLongValue]; } @catch (...) {}
        if (uid == 0) {
            NSLog(@"[BLUEDHOOK] 移除来访广告条目 [%lu] class=%@", i, NSStringFromClass([item class]));
            [toRemove addIndex:i];
        }
    }
    if (toRemove.count) {
        [arr removeObjectsAtIndexes:toRemove];
        NSLog(@"[BLUEDHOOK] 来访广告已过滤 %lu 条，剩余 %lu 条", (unsigned long)toRemove.count, (unsigned long)arr.count);
    }
}

%hook RecentlyVisitorViewController

// 网络回调数据到达后的处理入口，是最可靠的 hook 点
- (void)p_processWithNewVisitors:(id)visitors {
    %orig(visitors);
    BDHook_FilterVisitorAds(self);
}

- (void)refreshVisitor {
    %orig;
    BDHook_FilterVisitorAds(self);
}

- (void)loadMoreVisitor {
    %orig;
    BDHook_FilterVisitorAds(self);
}

%end

// ============================================================
// Hook 8 — 底栏净化：去除「直播」和「发现」标签页
// Tab 顺序：[身边(0), 直播(1), 发现(2), 消息(3), 我的(4)]
// 策略：
//   1. BDTabBarConfig titles/normalImages/selectedImages 只保留索引 0,3,4
//   2. UITabBarController setViewControllers:animated: 过滤对应 VC
// ============================================================

// 工具：从 5 元素数组中保留索引 0, 3, 4
static NSArray *BDHook_KeepMainTabs(NSArray *orig) {
    if (orig.count != 5) return orig;
    return @[orig[0], orig[3], orig[4]];
}

%hook BDTabBarConfig

+ (NSArray *)titles {
    return BDHook_KeepMainTabs(%orig);
}

+ (NSArray *)normalImages {
    return BDHook_KeepMainTabs(%orig);
}

+ (NSArray *)selectedImages {
    return BDHook_KeepMainTabs(%orig);
}

%end

// 过滤 VC 数组：去除根控制器为直播/发现的 NavigationController
%hook UITabBarController

- (void)setViewControllers:(NSArray *)vcs animated:(BOOL)animated {
    if (![NSStringFromClass(self.class) isEqualToString:@"BluedBaseTabbarController"]) {
        %orig;
        return;
    }

    Class liveClass = NSClassFromString(@"BDLiveTabController");
    Class findClass = NSClassFromString(@"BDNewFindListViewController");

    NSMutableArray *filtered = [NSMutableArray arrayWithCapacity:vcs.count];
    for (UIViewController *vc in vcs) {
        // 取 NavigationController 的根 VC 来判断
        UIViewController *root = vc;
        if ([vc isKindOfClass:[UINavigationController class]]) {
            root = ((UINavigationController *)vc).viewControllers.firstObject ?: vc;
        }
        if ((liveClass && [root isKindOfClass:liveClass]) ||
            (findClass && [root isKindOfClass:findClass])) {
            NSLog(@"[BLUEDHOOK] 移除 Tab: %@", NSStringFromClass(root.class));
            continue;
        }
        [filtered addObject:vc];
    }
    %orig(filtered, animated);
}

%end

// 拦截「发现」和「直播」上方的热门气泡，并修复消息徽章索引
// 移除直播(原1)和发现(原2)之后，Tab 顺序变为：
//   [身边(0), 消息(1), 我的(2)]
// 原始调用方仍按原始索引 3(消息)/4(我的) 传参 → 越界 → 气泡不显示
// 在此重映射：3→1，4→2
%hook BluedTabBar

// 发现热门气泡（bubble_position == 1）
- (void)p_showFindBubble {
    // 已移除发现 Tab，不显示气泡
}

// 直播气泡（bubble_position == 2）
- (void)p_showLiveBubbble {
    // 已移除直播 Tab，不显示气泡
}

// 修复消息/我的 Tab 徽章：原始索引 3→1，4→2
- (void)setBadgeValue:(unsigned long long)value atItemIndex:(long long)index {
    if (index == 3)      index = 1; // 消息 Tab
    else if (index == 4) index = 2; // 我的 Tab
    // 索引 0(身边) 不变；索引 1/2(已删除的直播/发现)调用方不会传来
    %orig(value, index);
}

%end

// %ctor {
//     NSLog(@"[BLUEDHOOK] Loaded.");

//     dispatch_after(
//         dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)),
//         dispatch_get_main_queue(),
//         ^{
//             UIWindow *window = nil;
//             if (@available(iOS 13.0, *)) {
//                 for (UIWindowScene *scene in UIApplication.sharedApplication.connectedScenes) {
//                     if ([scene isKindOfClass:[UIWindowScene class]] &&
//                         scene.activationState == UISceneActivationStateForegroundActive) {
//                         window = scene.windows.firstObject;
//                         break;
//                     }
//                 }
//             }
//             if (!window) {
//                 window = UIApplication.sharedApplication.keyWindow;
//             }

//             UIAlertController *alert = [UIAlertController
//                 alertControllerWithTitle:@"✅ BluedHook 注入成功"
//                 message:@"撤回拦截 & 闪照保存已启用"
//                 preferredStyle:UIAlertControllerStyleAlert];

//             [alert addAction:[UIAlertAction
//                 actionWithTitle:@"确定"
//                 style:UIAlertActionStyleDefault
//                 handler:nil]];

//             [window.rootViewController presentViewController:alert animated:YES completion:nil];
//         }
//     );
// }

