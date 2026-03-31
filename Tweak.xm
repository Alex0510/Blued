// Tweak.xm

// 引入所需框架（Theos 会自动导入 Foundation 和 objc/runtime，StoreKit 按需导入）
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <StoreKit/StoreKit.h>  // 如果需要处理内购相关可保留，否则可注释

// ==================== 修改闪照管理器 ====================
%hook BDBurnAfterReadManager

- (long long)flash_left_times {
    return 5;   // 将每日免费闪照次数改为 5 次
}

- (long long)free_times {
    return 5;
}

- (bool)is_enable {
    return YES; // 始终启用闪照功能
}

%end

// ==================== 修改键盘照片视图 ====================
%hook NewKeyBoardPhotoView

// 强制让闪照模式总是开启
- (void)setIsDestory:(bool)isDestory {
    %orig(YES); // 调用原始方法，但传入 YES
}

- (bool)isDestory {
    return YES; // 总是返回 YES，使闪照按钮默认选中
}

// 强制让交换照片模式总是可用（如果需要）
- (void)setIsSelectExchangePhoto:(bool)isSelectExchangePhoto {
    %orig(YES);
}

- (bool)isSelectExchangePhoto {
    return YES;
}

// 修改发送按钮的状态：即使没有选择照片也可以发送（用于测试）
- (void)actionSend:(id)sender {
    // 先调用原始发送逻辑，如果原始方法有限制，可能会失败
    // 可在此加入绕过逻辑，例如强制将 items 设为非空
    NSArray *items = %orig; // 如果原方法返回 items 数组
    if (!items || items.count == 0) {
        // 如果没有照片，可以模拟一个临时照片或者直接返回
        // 这里只是调用原方法，不额外处理
    }
    %orig;
}

// 修改销毁按钮标签配置，让闪照提示更明显
- (void)p_destroyLabelConfig {
    %orig;
    // 可以修改 label 文字，例如改为“闪照”
    // 但这里只是示例，实际需要找到具体的 label 对象
}

// 修改交换照片提示文案
- (void)p_exchangeLabelConfig {
    %orig;
    // 同样可修改文案
}

// 阻止发送照片时的校验限制（如果有）
- (bool)canSendDestroyVidoeOrPic:(bool)arg1 {
    // 始终允许发送闪照视频或图片
    return YES;
}

// 更新闪照剩余次数显示（如果 UI 中有显示）
- (void)updateBurnAfterRead {
    %orig;
    // 可以在更新后强制刷新显示，避免显示负数
    // 比如修改 mSendCountLabel 的文字
    // 但需要先获取该控件的引用
}

%end