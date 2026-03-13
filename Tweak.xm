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
        view.hidden = YES;
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
        view.hidden = YES;
    }
}

%end