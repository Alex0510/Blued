#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

%hook BDMineServiceCollectionCell

- (void)awakeFromNib {
    %orig;
    // 隐藏所有占位视图
    NSArray *viewNames = @[
        @"privilegeView",
        @"shadowView",
        @"shadowView2",
        @"groupChatView",
        @"homePretectView",
        @"privilegeAnimationView",
        @"shadowAnimationView",
        @"groupChatAnimationView",
        @"homeAnimationView"
    ];
    for (NSString *name in viewNames) {
        UIView *view = [(id)self valueForKey:name];
        view.hidden = YES;
    }
}

- (void)layoutSubviews {
    %orig;
    // 再次确保隐藏（防止被重新显示）
    NSArray *viewNames = @[
        @"privilegeView",
        @"shadowView",
        @"shadowView2",
        @"groupChatView",
        @"homePretectView",
        @"privilegeAnimationView",
        @"shadowAnimationView",
        @"groupChatAnimationView",
        @"homeAnimationView"
    ];
    for (NSString *name in viewNames) {
        UIView *view = [(id)self valueForKey:name];
        view.hidden = YES;
    }
}

%end

%hook BDHealthServiceCollectionCell

- (void)awakeFromNib {
    %orig;
    NSArray *viewNames = @[
        @"publicBenefitView",
        @"hullHealthView",
        @"healthStoreView",
        @"productToPromotionView",
        @"publicBenefitView2",
        @"hullHealthView2"
    ];
    for (NSString *name in viewNames) {
        UIView *view = [(id)self valueForKey:name];
        view.hidden = YES;
    }
}

- (void)layoutSubviews {
    %orig;
    NSArray *viewNames = @[
        @"publicBenefitView",
        @"hullHealthView",
        @"healthStoreView",
        @"productToPromotionView",
        @"publicBenefitView2",
        @"hullHealthView2"
    ];
    for (NSString *name in viewNames) {
        UIView *view = [(id)self valueForKey:name];
        view.hidden = YES;
    }
}

%end