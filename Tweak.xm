#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

%hook BDMineServiceCollectionCell

// 唤醒时移除占位视图
- (void)awakeFromNib {
    %orig; // 调用原始实现

    // 通过 KVC 获取视图，将 self 转为 id 避免不完整类型警告
    UIView *shadowView = [(id)self valueForKey:@"shadowView"];
    [shadowView removeFromSuperview];

    UIView *privilegeView = [(id)self valueForKey:@"privilegeView"];
    [privilegeView removeFromSuperview];

    UIView *groupChatView = [(id)self valueForKey:@"groupChatView"];
    [groupChatView removeFromSuperview];

    UIView *homePretectView = [(id)self valueForKey:@"homePretectView"];
    [homePretectView removeFromSuperview];
}

// 布局时再次隐藏（防止被重新显示）
- (void)layoutSubviews {
    %orig;

    UIView *shadowView = [(id)self valueForKey:@"shadowView"];
    shadowView.hidden = YES;

    UIView *privilegeView = [(id)self valueForKey:@"privilegeView"];
    privilegeView.hidden = YES;

    UIView *groupChatView = [(id)self valueForKey:@"groupChatView"];
    groupChatView.hidden = YES;

    UIView *homePretectView = [(id)self valueForKey:@"homePretectView"];
    homePretectView.hidden = YES;
}

%end