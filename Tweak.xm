// 文件名: ForceSettings.m
// 编译命令示例: clang -dynamiclib -framework Foundation -framework UIKit -framework Security -o ForceSettings.dylib ForceSettings.m
// 注意: 实际使用时需根据目标应用链接的框架调整，通常只需 Foundation 和 UIKit

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

static void ModifyUserSetting(id setting) {
    // 需要开启的属性列表（值为 1 表示开启）
    NSArray<NSString *> *keys = @[
        @"is_global_view_secretly",
        @"is_traceless_access",
        @"is_prohibit_chat_screenshot",
        @"is_hide_follows_count",
        @"is_hide_followers_count",
        @"is_hide_last_operate",
        @"is_hide_distance",
        @"is_open_private_photos"
    ];
    
    for (NSString *key in keys) {
        @try {
            [setting setValue:@(1) forKey:key];
            NSLog(@"[ForceSettings] Set %@ = 1", key);
        } @catch (NSException *exception) {
            NSLog(@"[ForceSettings] Failed to set %@: %@", key, exception);
        }
    }
}

// Hook 方法，用于拦截 UserSetting 的 init
static id SwizzledInit(id self, SEL _cmd) {
    // 调用原始 init 方法
    id (*originalInit)(id, SEL) = (id (*)(id, SEL))method_getImplementation(class_getInstanceMethod([self class], @selector(init)));
    id result = originalInit(self, _cmd);
    
    if (result) {
        ModifyUserSetting(result);
    }
    return result;
}

__attribute__((constructor))
static void Initialize() {
    @autoreleasepool {
        // 获取 UserSetting 类
        Class userSettingClass = objc_getClass("UserSetting");
        if (!userSettingClass) {
            NSLog(@"[ForceSettings] UserSetting class not found");
            return;
        }
        
        // 尝试获取常见的共享实例方法名
        NSArray<NSString *> *sharedSelectors = @[@"sharedInstance", @"sharedSetting", @"defaultSetting", @"currentUserSetting"];
        id sharedInstance = nil;
        for (NSString *selName in sharedSelectors) {
            SEL sel = NSSelectorFromString(selName);
            if ([userSettingClass respondsToSelector:sel]) {
                sharedInstance = [userSettingClass performSelector:sel];
                if (sharedInstance) break;
            }
        }
        
        if (sharedInstance) {
            // 如果找到共享实例，直接修改
            ModifyUserSetting(sharedInstance);
        } else {
            // 否则 Hook init 方法，确保后续创建的实例被修改
            Method originalInit = class_getInstanceMethod(userSettingClass, @selector(init));
            if (originalInit) {
                method_setImplementation(originalInit, (IMP)SwizzledInit);
                NSLog(@"[ForceSettings] Hooked -[UserSetting init]");
            } else {
                NSLog(@"[ForceSettings] -[UserSetting init] not found");
            }
        }
    }
}