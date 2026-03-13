#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

%hook BDMineServiceCollectionCell

- (void)awakeFromNib {
    %orig;
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
        [view removeFromSuperview];
    }
}

- (void)layoutSubviews {
    %orig;
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
        [view removeFromSuperview];
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
        [view removeFromSuperview];
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
        [view removeFromSuperview];
    }
}

%end

%hook BDOtherServiceCollectionCell

- (void)awakeFromNib {
    %orig;
    NSArray *viewNames = @[
        @"rainBowView",
        @"helpView",
        @"emojiView",
        @"bannerView"
    ];
    for (NSString *name in viewNames) {
        UIView *view = [(id)self valueForKey:name];
        [view removeFromSuperview];
    }
}

- (void)layoutSubviews {
    %orig;
    NSArray *viewNames = @[
        @"rainBowView",
        @"helpView",
        @"emojiView",
        @"bannerView"
    ];
    for (NSString *name in viewNames) {
        UIView *view = [(id)self valueForKey:name];
        [view removeFromSuperview];
    }
}

- (void)didMoveToWindow {
    %orig;
    // 当视图被加入窗口时，再次检查并移除（防止被重新添加）
    NSArray *viewNames = @[
        @"rainBowView",
        @"helpView",
        @"emojiView",
        @"bannerView"
    ];
    for (NSString *name in viewNames) {
        UIView *view = [(id)self valueForKey:name];
        if (view.superview) {
            [view removeFromSuperview];
        }
    }
}

%end

%hook BDLiveServiceCollectionCell

- (void)awakeFromNib {
    %orig;
    NSArray *viewNames = @[
        @"anchorLevelView",
        @"fansClubView",
        @"richLevelView"
    ];
    for (NSString *name in viewNames) {
        UIView *view = [(id)self valueForKey:name];
        [view removeFromSuperview];
    }
}

- (void)layoutSubviews {
    %orig;
    NSArray *viewNames = @[
        @"anchorLevelView",
        @"fansClubView",
        @"richLevelView"
    ];
    for (NSString *name in viewNames) {
        UIView *view = [(id)self valueForKey:name];
        [view removeFromSuperview];
    }
}

- (void)didMoveToWindow {
    %orig;
    NSArray *viewNames = @[
        @"anchorLevelView",
        @"fansClubView",
        @"richLevelView"
    ];
    for (NSString *name in viewNames) {
        UIView *view = [(id)self valueForKey:name];
        if (view.superview) {
            [view removeFromSuperview];
        }
    }
}

%end

%hook BDAudioServiceCollectionViewCell

- (void)awakeFromNib {
    %orig;
    NSArray *viewNames = @[
        @"anchorLevelView",
        @"fansClubView",
        @"richLevelView"
    ];
    for (NSString *name in viewNames) {
        UIView *view = [(id)self valueForKey:name];
        [view removeFromSuperview];
    }
}

- (void)layoutSubviews {
    %orig;
    NSArray *viewNames = @[
        @"anchorLevelView",
        @"fansClubView",
        @"richLevelView"
    ];
    for (NSString *name in viewNames) {
        UIView *view = [(id)self valueForKey:name];
        [view removeFromSuperview];
    }
}

- (void)didMoveToWindow {
    %orig;
    NSArray *viewNames = @[
        @"anchorLevelView",
        @"fansClubView",
        @"richLevelView"
    ];
    for (NSString *name in viewNames) {
        UIView *view = [(id)self valueForKey:name];
        if (view.superview) {
            [view removeFromSuperview];
        }
    }
}

%end