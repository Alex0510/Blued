#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

%hook BDMineServiceCollectionCell

- (void)awakeFromNib {
    %orig;
    [self hidePlaceholderViews];
}

- (void)layoutSubviews {
    %orig;
    [self hidePlaceholderViews];
}

- (void)prepareForReuse {
    %orig;
    [self hidePlaceholderViews];
}

- (void)hidePlaceholderViews {
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
        if (view) {
            view.hidden = YES;
            // 延迟执行确保不被其他代码覆盖
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                view.hidden = YES;
            });
        }
    }
}

%end

%hook BDHealthServiceCollectionCell

- (void)awakeFromNib {
    %orig;
    [self hidePlaceholderViews];
}

- (void)layoutSubviews {
    %orig;
    [self hidePlaceholderViews];
}

- (void)prepareForReuse {
    %orig;
    [self hidePlaceholderViews];
}

- (void)hidePlaceholderViews {
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
        if (view) {
            view.hidden = YES;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                view.hidden = YES;
            });
        }
    }
}

%end

%hook BDOtherServiceCollectionCell

- (void)awakeFromNib {
    %orig;
    [self hidePlaceholderViews];
}

- (void)layoutSubviews {
    %orig;
    [self hidePlaceholderViews];
}

- (void)prepareForReuse {
    %orig;
    [self hidePlaceholderViews];
}

- (void)hidePlaceholderViews {
    NSArray *viewNames = @[
        @"rainBowView",
        @"helpView",
        @"emojiView",
        @"bannerView"
    ];
    for (NSString *name in viewNames) {
        UIView *view = [(id)self valueForKey:name];
        if (view) {
            view.hidden = YES;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                view.hidden = YES;
            });
        }
    }
}

%end

%hook BDLiveServiceCollectionCell

- (void)awakeFromNib {
    %orig;
    [self hidePlaceholderViews];
}

- (void)layoutSubviews {
    %orig;
    [self hidePlaceholderViews];
}

- (void)prepareForReuse {
    %orig;
    [self hidePlaceholderViews];
}

- (void)hidePlaceholderViews {
    NSArray *viewNames = @[
        @"anchorLevelView",
        @"fansClubView",
        @"richLevelView"
    ];
    for (NSString *name in viewNames) {
        UIView *view = [(id)self valueForKey:name];
        if (view) {
            view.hidden = YES;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                view.hidden = YES;
            });
        }
    }
}

%end

%hook BDAudioServiceCollectionViewCell

- (void)awakeFromNib {
    %orig;
    [self hidePlaceholderViews];
}

- (void)layoutSubviews {
    %orig;
    [self hidePlaceholderViews];
}

- (void)prepareForReuse {
    %orig;
    [self hidePlaceholderViews];
}

- (void)hidePlaceholderViews {
    NSArray *viewNames = @[
        @"anchorLevelView",
        @"fansClubView",
        @"richLevelView"
    ];
    for (NSString *name in viewNames) {
        UIView *view = [(id)self valueForKey:name];
        if (view) {
            view.hidden = YES;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                view.hidden = YES;
            });
        }
    }
}

%end