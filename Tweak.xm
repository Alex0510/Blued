// Tweak.xm

%hook BDBurnAfterReadManager

- (long long)flash_left_times {
    return 5;               // 将免费闪照次数改为5次
}

- (long long)free_times {
    return 5;
}

- (bool)is_enable {
    return YES;             // 始终启用闪照功能
}

%end