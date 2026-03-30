#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <objc/message.h>

// 通用强制设置函数，对任意对象批量设置属性
static void ForceSetProperties(id object, NSArray<NSString *> *keys, NSNumber *value) {
    for (NSString *key in keys) {
        @try {
            [object setValue:value forKey:key];
        } @catch (NSException *exception) {
            // 忽略无法设置的属性
        }
    }
}

// 批量修改 UserSetting 实例
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
    ForceSetProperties(setting, keys, @(1));
}

// 批量修改 BDVIPPrivilegeConfigModel 实例
static void ModifyVIPPrivilege(id vipModel) {
    NSArray<NSString *> *keys = @[
        @"is_global_view_secretly",
        @"is_traceless_access",
        @"is_hide_last_operate",
        @"is_hide_distance",
        @"is_hide_city_settled",
        @"is_invisible_half",
        @"is_invisible_all"
    ];
    ForceSetProperties(vipModel, keys, @(1));
}

// 批量修改 UserInformation 实例
static void ModifyUserInformation(id userInfo) {
    NSArray<NSString *> *keys = @[
        @"is_global_view_secretly",
        @"is_invisible_map",
        @"is_hide_follows_count",
        @"is_hide_followers_count",
        @"is_hide_last_operate",
        @"is_hide_distance",
        @"is_hide_city_settled"
    ];
    ForceSetProperties(userInfo, keys, @(1));
    
    // 个别属性可能是 uint 或 int，但 KVC 同样适用
}

// Hook UserSetting
%hook UserSetting
- (instancetype)init {
    id result = %orig;
    if (result) ModifyUserSetting(result);
    return result;
}
// 强制 getter 返回 1
- (long long)is_global_view_secretly { return 1; }
- (long long)is_traceless_access { return 1; }
- (long long)is_prohibit_chat_screenshot { return 1; }
- (int)is_hide_follows_count { return 1; }
- (int)is_hide_followers_count { return 1; }
- (int)is_hide_last_operate { return 1; }
- (int)is_hide_distance { return 1; }
- (long long)is_open_private_photos { return 1; }
%end

// Hook BDVIPPrivilegeConfigModel
%hook BDVIPPrivilegeConfigModel
- (instancetype)init {
    id result = %orig;
    if (result) ModifyVIPPrivilege(result);
    return result;
}
- (long long)is_global_view_secretly { return 1; }
- (long long)is_traceless_access { return 1; }
- (long long)is_hide_last_operate { return 1; }
- (long long)is_hide_distance { return 1; }
- (long long)is_hide_city_settled { return 1; }
- (long long)is_invisible_half { return 1; }
- (long long)is_invisible_all { return 1; }
%end

// Hook UserInformation
%hook UserInformation
- (instancetype)init {
    id result = %orig;
    if (result) ModifyUserInformation(result);
    return result;
}
- (uint)is_global_view_secretly { return 1; }
- (int)is_invisible_map { return 1; }
- (int)is_hide_follows_count { return 1; }
- (int)is_hide_followers_count { return 1; }
- (int)is_hide_last_operate { return 1; }
- (int)is_hide_distance { return 1; }
- (int)is_hide_city_settled { return 1; }
%end

// 构造函数：尽早修改已有的单例
__attribute__((constructor))
static void Initialize() {
    @autoreleasepool {
        // 处理 UserSetting 单例
        Class userSettingClass = objc_getClass("UserSetting");
        if (userSettingClass) {
            NSArray<NSString *> *selectors = @[@"sharedInstance", @"sharedSetting", @"defaultSetting", @"currentUserSetting"];
            for (NSString *selName in selectors) {
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
        
        // 处理 BDVIPPrivilegeConfigModel 单例（如果存在）
        Class vipClass = objc_getClass("BDVIPPrivilegeConfigModel");
        if (vipClass) {
            // 常见单例方法名可能不同，尝试遍历
            NSArray<NSString *> *vipSelectors = @[@"sharedInstance", @"defaultModel", @"currentModel"];
            for (NSString *selName in vipSelectors) {
                SEL sel = NSSelectorFromString(selName);
                if ([vipClass respondsToSelector:sel]) {
                    id (*msgSend)(id, SEL) = (id (*)(id, SEL))objc_msgSend;
                    id sharedModel = msgSend(vipClass, sel);
                    if (sharedModel) {
                        ModifyVIPPrivilege(sharedModel);
                        break;
                    }
                }
            }
        }
        
        // 处理 UserInformation 单例（如果存在）
        Class userInfoClass = objc_getClass("UserInformation");
        if (userInfoClass) {
            NSArray<NSString *> *infoSelectors = @[@"sharedInstance", @"currentUser", @"mainUser"];
            for (NSString *selName in infoSelectors) {
                SEL sel = NSSelectorFromString(selName);
                if ([userInfoClass respondsToSelector:sel]) {
                    id (*msgSend)(id, SEL) = (id (*)(id, SEL))objc_msgSend;
                    id sharedInfo = msgSend(userInfoClass, sel);
                    if (sharedInfo) {
                        ModifyUserInformation(sharedInfo);
                        break;
                    }
                }
            }
        }
    }
}