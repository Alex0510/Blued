#import <UIKit/UIKit.h>

%hook BDMineServiceCollectionCell
- (void)layoutSubviews {
    %orig;
    UIView *view = (UIView *)self;
    CGRect frame = view.frame;
    frame.size.height = 0;
    view.frame = frame;
    view.hidden = YES;
}
%end

%hook BDOtherServiceCollectionCell
- (void)layoutSubviews {
    %orig;
    UIView *view = (UIView *)self;
    CGRect frame = view.frame;
    frame.size.height = 0;
    view.frame = frame;
    view.hidden = YES;
}
%end

%hook BDLiveServiceCollectionCell
- (void)layoutSubviews {
    %orig;
    UIView *view = (UIView *)self;
    CGRect frame = view.frame;
    frame.size.height = 0;
    view.frame = frame;
    view.hidden = YES;
}
%end

%hook BDAudioServiceCollectionViewCell
- (void)layoutSubviews {
    %orig;
    UIView *view = (UIView *)self;
    CGRect frame = view.frame;
    frame.size.height = 0;
    view.frame = frame;
    view.hidden = YES;
}
%end

%hook BDHealthServiceCollectionCell
- (void)layoutSubviews {
    %orig;
    UIView *view = (UIView *)self;
    CGRect frame = view.frame;
    frame.size.height = 0;
    view.frame = frame;
    view.hidden = YES;
}
%end