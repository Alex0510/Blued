#import <UIKit/UIKit.h>

%hook BDMineServiceCollectionCell

// 在视图从 Nib 唤醒后立即移除占位视图
- (void)awakeFromNib {
    %orig; // 先执行原始初始化逻辑

    // 通过 KVC 获取各个占位视图并移除（可根据需要改为隐藏）
    UIView *shadowView = [self valueForKey:@"shadowView"];
    [shadowView removeFromSuperview];

    UIView *privilegeView = [self valueForKey:@"privilegeView"];
    [privilegeView removeFromSuperview];

    UIView *groupChatView = [self valueForKey:@"groupChatView"];
    [groupChatView removeFromSuperview];

    UIView *homePretectView = [self valueForKey:@"homePretectView"];
    [homePretectView removeFromSuperview];

    // 若还有其他占位视图，可继续添加
}

// 可选：在布局时再次确保占位视图被隐藏（适用于动态添加的情况）
- (void)layoutSubviews {
    %orig;

    // 再次检查并隐藏（防止被重新显示）
    UIView *shadowView = [self valueForKey:@"shadowView"];
    shadowView.hidden = YES;

    UIView *privilegeView = [self valueForKey:@"privilegeView"];
    privilegeView.hidden = YES;

    UIView *groupChatView = [self valueForKey:@"groupChatView"];
    groupChatView.hidden = YES;

    UIView *homePretectView = [self valueForKey:@"homePretectView"];
    homePretectView.hidden = YES;
}

%end