// Tweak.xm

%hook BDBurnAfterReadManager

- (long long)flash_left_times {
    return 5;               // 每日免费闪照次数改为5
}

- (long long)free_times {
    return 5;
}

- (bool)is_enable {
    return YES;             // 始终启用闪照功能
}

%end

%hook NewKeyBoardPhotoView

// 强制闪照模式始终开启
- (void)setIsDestory:(bool)isDestory {
    %orig(YES);
}

- (bool)isDestory {
    return YES;
}

// 强制交换照片模式始终开启
- (void)setIsSelectExchangePhoto:(bool)isSelectExchangePhoto {
    %orig(YES);
}

- (bool)isSelectExchangePhoto {
    return YES;
}

// 允许发送任何闪照内容
- (bool)canSendDestroyVidoeOrPic:(bool)arg1 {
    return YES;
}

// 更新闪照次数显示（可选）
- (void)updateBurnAfterRead {
    %orig;
    // 如需额外处理可在此添加
}

%end