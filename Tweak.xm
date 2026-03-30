#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <objc/message.h>

static void ModifyUserSetting(id setting) {
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
            NSLog(@"[Bluedmap] Set %@ = 1", key);
        } @catch (NSException *exception) {
            NSLog(@"[Bluedmap] Failed to set %@: %@", key, exception);
        }
    }
}

%hook UserSetting
- (instancetype)init {
    id result = %orig;
    if (result) {
        ModifyUserSetting(result);
    }
    return result;
}
%end

__attribute__((constructor))
static void Initialize() {
    @autoreleasepool {
        Class userSettingClass = objc_getClass("UserSetting");
        if (!userSettingClass) {
            NSLog(@"[Bluedmap] UserSetting class not found");
            return;
        }
        
        // 尝试获取常见的共享实例方法名，使用 objc_msgSend 避免 performSelector 警告
        NSArray<NSString *> *sharedSelectors = @[@"sharedInstance", @"sharedSetting", @"defaultSetting", @"currentUserSetting"];
        for (NSString *selName in sharedSelectors) {
            SEL sel = NSSelectorFromString(selName);
            if ([userSettingClass respondsToSelector:sel]) {
                id (*msgSend)(id, SEL) = (id (*)(id, SEL))objc_msgSend;
                id sharedInstance = msgSend(userSettingClass, sel);
                if (sharedInstance) {
                    ModifyUserSetting(sharedInstance);
                    break;
                }
            }
        }
    }
}