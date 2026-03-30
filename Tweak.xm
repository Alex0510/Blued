#import <UIKit/UIKit.h>

%hook BDMineServiceCollectionCell
- (void)layoutSubviews {
    %orig;
    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, 0);
    self.hidden = YES;
}
%end

%hook BDOtherServiceCollectionCell
- (void)layoutSubviews {
    %orig;
    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, 0);
    self.hidden = YES;
}
%end

%hook BDLiveServiceCollectionCell
- (void)layoutSubviews {
    %orig;
    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, 0);
    self.hidden = YES;
}
%end

%hook BDAudioServiceCollectionViewCell
- (void)layoutSubviews {
    %orig;
    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, 0);
    self.hidden = YES;
}
%end

%hook BDHealthServiceCollectionCell
- (void)layoutSubviews {
    %orig;
    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, 0);
    self.hidden = YES;
}
%end