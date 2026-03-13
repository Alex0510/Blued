#import <objc/runtime.h>

@implementation BDMineServiceCollectionCell (RemovePlaceholder)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // 交换 awakeFromNib 方法
        Method original = class_getInstanceMethod(self, @selector(awakeFromNib));
        Method swizzled = class_getInstanceMethod(self, @selector(hook_awakeFromNib));
        method_exchangeImplementations(original, swizzled);
    });
}

- (void)hook_awakeFromNib {
    // 先调用原始方法（保证原有初始化逻辑执行）
    [self hook_awakeFromNib];
    
    // 通过 KVC 获取需要移除的视图（属性名根据实际情况调整）
    UIView *shadowView = [self valueForKey:@"shadowView"];
    if (shadowView) {
        [shadowView removeFromSuperview];   // 直接移除
        // 或者设置为隐藏： shadowView.hidden = YES;
    }
    
    UIView *groupChatView = [self valueForKey:@"groupChatView"];
    if (groupChatView) {
        [groupChatView removeFromSuperview];
    }
    
    // 继续处理其他占位视图...
}

@end