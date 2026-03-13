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
        view.hidden = YES;
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
        view.hidden = YES;
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
        view.hidden = YES;
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
        view.hidden = YES;
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
        view.hidden = YES;
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
        view.hidden = YES;
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
        view.hidden = YES;
    }
}

%end