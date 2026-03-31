// Tweak.xm

%hook BDBurnAfterReadManager

- (long long)flash_left_times {
    return 5;   // 每日免费闪照次数改为5次
}

- (long long)free_times {
    return 5;
}

- (bool)is_enable {
    return YES; // 确保闪照功能始终可用
}

%end