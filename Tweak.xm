#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <objc/message.h>

// ============================================
// 通用设置函数：批量设置属性值
// ============================================
static void ForceSetProperties(id object, NSArray<NSString *> *keys, NSNumber *value) {
    for (NSString *key in keys) {
        @try {
            [object setValue:value forKey:key];
        } @catch (NSException *exception) {
            // 忽略不可设置的属性
        }
    }
}

// ============================================
// 已存在的三个类
// ============================================

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

%hook UserSetting
- (instancetype)init {
    id result = %orig;
    if (result) ModifyUserSetting(result);
    return result;
}
- (long long)is_global_view_secretly { return 1; }
- (long long)is_traceless_access { return 1; }
- (long long)is_prohibit_chat_screenshot { return 1; }
- (int)is_hide_follows_count { return 1; }
- (int)is_hide_followers_count { return 1; }
- (int)is_hide_last_operate { return 1; }
- (int)is_hide_distance { return 1; }
- (long long)is_open_private_photos { return 1; }
%end

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
}

%hook UserInformation
- (instancetype)init {
    id result = %orig;
    if (result) ModifyUserInformation(result);
    return result;
}
- (uint)is_global_view_secretly { return 1; }
- (int)is_invisible_map { return 1; }
- (int)is_hide_follows_count { return 0; }
- (int)is_hide_followers_count { return 0; }
- (int)is_hide_last_operate { return 0; }
- (int)is_hide_distance { return 0; }
- (int)is_hide_city_settled { return 1; }
%end

// ============================================
// 新增类 Hook（按用户要求）
// ============================================

#pragma mark - BDChatProtectionManager
static void ModifyBDChatProtectionManager(id manager) {
    NSArray<NSString *> *keys = @[
        @"is_prohibit_chat_screenshot"
    ];
    ForceSetProperties(manager, keys, @(1));
}

%hook BDChatProtectionManager
- (instancetype)init {
    id result = %orig;
    if (result) ModifyBDChatProtectionManager(result);
    return result;
}
- (long long)is_prohibit_chat_screenshot { return 1; }
%end

#pragma mark - BDChatProtectionModel
static void ModifyBDChatProtectionModel(id model) {
    NSArray<NSString *> *keys = @[
        @"is_prohibit_chat_screenshot"
    ];
    ForceSetProperties(model, keys, @(1));
}

%hook BDChatProtectionModel
- (instancetype)init {
    id result = %orig;
    if (result) ModifyBDChatProtectionModel(result);
    return result;
}
- (long long)is_prohibit_chat_screenshot { return 1; }
%end

#pragma mark - BDMessageViewController
static void ModifyBDMessageViewController(id vc) {
    NSArray<NSString *> *keys = @[
        @"is_prohibit_chat_screenshot"
    ];
    ForceSetProperties(vc, keys, @(1));
}

%hook BDMessageViewController
- (instancetype)init {
    id result = %orig;
    if (result) ModifyBDMessageViewController(result);
    return result;
}
- (long long)is_prohibit_chat_screenshot { return 1; }
%end

#pragma mark - GJIMMessageModel
static void ModifyGJIMMessageModel(id model) {
    NSArray<NSString *> *keys = @[
        @"is_prohibit_chat_screenshot"
    ];
    ForceSetProperties(model, keys, @(1));
}

%hook GJIMMessageModel
- (instancetype)init {
    id result = %orig;
    if (result) ModifyGJIMMessageModel(result);
    return result;
}
- (bool)is_prohibit_chat_screenshot { return YES; }
%end

#pragma mark - UserSettingModel
static void ModifyUserSettingModel(id model) {
    NSArray<NSString *> *keys = @[
        @"is_hide_last_operate",
        @"is_hide_distance",
        @"is_hide_city_settled",
        @"is_invisible_half",
        @"is_invisible_all",
        @"is_traceless_access"
    ];
    ForceSetProperties(model, keys, @(1));
}

%hook UserSettingModel
- (instancetype)init {
    id result = %orig;
    if (result) ModifyUserSettingModel(result);
    return result;
}
- (int)is_hide_last_operate { return 1; }
- (int)is_hide_distance { return 1; }
- (int)is_hide_city_settled { return 1; }
- (int)is_invisible_half { return 1; }
- (int)is_invisible_all { return 1; }
- (int)is_traceless_access { return 1; }
%end

#pragma mark - BaseModel
static void ModifyBaseModel(id model) {
    NSArray<NSString *> *keys = @[
        @"is_hide_last_operate",
        @"is_hide_distance",
        @"is_hide_city_settled",
        @"is_invisible_half",
        @"is_invisible_all",
        @"is_traceless_access"
    ];
    ForceSetProperties(model, keys, @(1));
}

%hook BaseModel
- (instancetype)init {
    id result = %orig;
    if (result) ModifyBaseModel(result);
    return result;
}
- (int)is_hide_last_operate { return 0; }
- (int)is_hide_distance { return 0; }
- (int)is_hide_city_settled { return 1; }
- (int)is_invisible_half { return 1; }
- (int)is_invisible_all { return 1; }
- (int)is_traceless_access { return 1; }
%end

#pragma mark - BDProfile
static void ModifyBDProfile(id profile) {
    NSArray<NSString *> *keys = @[
        @"is_hide_last_operate",
        @"is_hide_distance",
        @"is_hide_city_settled",
        @"is_invisible_half",
        @"is_invisible_all",
        @"is_traceless_access",
        @"is_prohibit_chat_screenshot"
    ];
    ForceSetProperties(profile, keys, @(1));
}

%hook BDProfile
- (instancetype)init {
    id result = %orig;
    if (result) ModifyBDProfile(result);
    return result;
}
- (int)is_hide_last_operate { return 0; }
- (int)is_hide_distance { return 0; }
- (int)is_hide_city_settled { return 1; }
- (int)is_invisible_half { return 1; }
- (int)is_invisible_all { return 1; }
- (int)is_traceless_access { return 1; }
- (int)is_prohibit_chat_screenshot { return 1; }
%end

#pragma mark - SearchUsersData
static void ModifySearchUsersData(id data) {
    NSArray<NSString *> *keys = @[
        @"is_hide_last_operate",
        @"is_hide_distance",
        @"is_hide_city_settled",
        @"is_invisible_half",
        @"is_invisible_all",
        @"is_traceless_access"
    ];
    ForceSetProperties(data, keys, @(1));
}

%hook SearchUsersData
- (instancetype)init {
    id result = %orig;
    if (result) ModifySearchUsersData(result);
    return result;
}
- (int)is_hide_last_operate { return 0; }
- (int)is_hide_distance { return 0; }
- (int)is_hide_city_settled { return 1; }
- (int)is_invisible_half { return 1; }
- (int)is_invisible_all { return 1; }
- (int)is_traceless_access { return 1; }
%end

// ============================================
// 构造函数：尝试修改已有的单例实例
// ============================================
__attribute__((constructor))
static void Initialize() {
    @autoreleasepool {
        // 处理 UserSetting 单例
        Class cls = objc_getClass("UserSetting");
        if (cls) {
            NSArray<NSString *> *selectors = @[@"sharedInstance", @"sharedSetting", @"defaultSetting", @"currentUserSetting"];
            for (NSString *selName in selectors) {
                SEL sel = NSSelectorFromString(selName);
                if ([cls respondsToSelector:sel]) {
                    id (*msgSend)(id, SEL) = (id (*)(id, SEL))objc_msgSend;
                    id instance = msgSend(cls, sel);
                    if (instance) {
                        ModifyUserSetting(instance);
                        break;
                    }
                }
            }
        }
        
        // 处理 BDVIPPrivilegeConfigModel 单例
        cls = objc_getClass("BDVIPPrivilegeConfigModel");
        if (cls) {
            NSArray<NSString *> *selectors = @[@"sharedInstance", @"defaultModel", @"currentModel"];
            for (NSString *selName in selectors) {
                SEL sel = NSSelectorFromString(selName);
                if ([cls respondsToSelector:sel]) {
                    id (*msgSend)(id, SEL) = (id (*)(id, SEL))objc_msgSend;
                    id instance = msgSend(cls, sel);
                    if (instance) {
                        ModifyVIPPrivilege(instance);
                        break;
                    }
                }
            }
        }
        
        // 处理 UserInformation 单例
        cls = objc_getClass("UserInformation");
        if (cls) {
            NSArray<NSString *> *selectors = @[@"sharedInstance", @"currentUser", @"mainUser"];
            for (NSString *selName in selectors) {
                SEL sel = NSSelectorFromString(selName);
                if ([cls respondsToSelector:sel]) {
                    id (*msgSend)(id, SEL) = (id (*)(id, SEL))objc_msgSend;
                    id instance = msgSend(cls, sel);
                    if (instance) {
                        ModifyUserInformation(instance);
                        break;
                    }
                }
            }
        }
        
        // 处理 BDChatProtectionManager 单例（如果存在）
        cls = objc_getClass("BDChatProtectionManager");
        if (cls) {
            NSArray<NSString *> *selectors = @[@"sharedManager", @"sharedInstance"];
            for (NSString *selName in selectors) {
                SEL sel = NSSelectorFromString(selName);
                if ([cls respondsToSelector:sel]) {
                    id (*msgSend)(id, SEL) = (id (*)(id, SEL))objc_msgSend;
                    id instance = msgSend(cls, sel);
                    if (instance) {
                        ModifyBDChatProtectionManager(instance);
                        break;
                    }
                }
            }
        }
        
        // 处理 BDProfile 单例（如果存在）
        cls = objc_getClass("BDProfile");
        if (cls) {
            NSArray<NSString *> *selectors = @[@"sharedProfile", @"sharedInstance", @"currentProfile"];
            for (NSString *selName in selectors) {
                SEL sel = NSSelectorFromString(selName);
                if ([cls respondsToSelector:sel]) {
                    id (*msgSend)(id, SEL) = (id (*)(id, SEL))objc_msgSend;
                    id instance = msgSend(cls, sel);
                    if (instance) {
                        ModifyBDProfile(instance);
                        break;
                    }
                }
            }
        }
        
        // 其他类一般没有单例，但 init Hook 已覆盖所有新建实例
    }
}