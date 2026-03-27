// Tweak.xm
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <objc/message.h>

#pragma mark - 工具函数
static void swizzleMethod(Class cls, SEL original, SEL replacement) {
    Method origMethod = class_getInstanceMethod(cls, original);
    Method newMethod = class_getInstanceMethod(cls, replacement);
    if (class_addMethod(cls, original, method_getImplementation(newMethod), method_getTypeEncoding(newMethod))) {
        class_replaceMethod(cls, replacement, method_getImplementation(origMethod), method_getTypeEncoding(origMethod));
    } else {
        method_exchangeImplementations(origMethod, newMethod);
    }
}

static void setPropertyIfExists(id obj, NSString *key, id value) {
    if (!obj) return;
    NSString *setterName = [NSString stringWithFormat:@"set%@:", [key capitalizedString]];
    SEL setter = NSSelectorFromString(setterName);
    if ([obj respondsToSelector:setter]) {
        ((void (*)(id, SEL, id))objc_msgSend)(obj, setter, value);
        printf("[BluedPrivacy] Set property via setter: %s -> %d\n", [key UTF8String], [value boolValue]);
    } else {
        @try {
            [obj setValue:value forKey:key];
            printf("[BluedPrivacy] Set property via KVC: %s -> %d\n", [key UTF8String], [value boolValue]);
        } @catch (NSException *e) {
            printf("[BluedPrivacy] KVC failed for %s: %s\n", [key UTF8String], [[e reason] UTF8String]);
        }
    }
}

#pragma mark - 要设置的隐私属性列表
static NSArray<NSString *> *privacyKeys(void) {
    static NSArray *keys = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        keys = @[
            @"isTracelessAccess",
            @"isGlobalViewSecretly",
            @"isAgeStealth",
            @"isRoleStealth",
            @"isStealthDistance",
            @"isHideLastOperate",
            @"isHideDistance"
        ];
    });
    return keys;
}

static void enableAllPrivacyFeatures(id model) {
    if (!model) return;
    printf("[BluedPrivacy] Enabling privacy for %s\n", class_getName([model class]));
    for (NSString *key in privacyKeys()) {
        setPropertyIfExists(model, key, @YES);
    }
}

#pragma mark - Hook BDMineUserModel 的初始化方法
static void hookBDMineUserModel(void) {
    Class cls = NSClassFromString(@"BDMineUserModel");
    if (!cls) {
        printf("[BluedPrivacy] BDMineUserModel not found\n");
        return;
    }
    
    // Hook init 方法（如果有）
    SEL initSel = @selector(init);
    if (class_getInstanceMethod(cls, initSel)) {
        __block IMP originalInit = NULL;
        IMP newInit = imp_implementationWithBlock(^(id self) {
            id result = ((id (*)(id, SEL))originalInit)(self, initSel);
            if (result) enableAllPrivacyFeatures(result);
            return result;
        });
        Method method = class_getInstanceMethod(cls, initSel);
        if (method) {
            originalInit = method_getImplementation(method);
            class_replaceMethod(cls, @selector(privacy_init), newInit, method_getTypeEncoding(method));
            swizzleMethod(cls, initSel, @selector(privacy_init));
        }
    }
    
    // Hook initWithCoder:
    SEL coderSel = @selector(initWithCoder:);
    if (class_getInstanceMethod(cls, coderSel)) {
        __block IMP originalCoder = NULL;
        IMP newCoder = imp_implementationWithBlock(^(id self, NSCoder *coder) {
            id result = ((id (*)(id, SEL, NSCoder*))originalCoder)(self, coderSel, coder);
            if (result) enableAllPrivacyFeatures(result);
            return result;
        });
        Method method = class_getInstanceMethod(cls, coderSel);
        if (method) {
            originalCoder = method_getImplementation(method);
            class_replaceMethod(cls, @selector(privacy_initWithCoder:), newCoder, method_getTypeEncoding(method));
            swizzleMethod(cls, coderSel, @selector(privacy_initWithCoder:));
        }
    }
}

#pragma mark - Hook BDActivityDetailUserInfo 的初始化方法
static void hookBDActivityDetailUserInfo(void) {
    Class cls = NSClassFromString(@"BDActivityDetailUserInfo");
    if (!cls) {
        printf("[BluedPrivacy] BDActivityDetailUserInfo not found\n");
        return;
    }
    
    // Hook initWithCoder: (最可能)
    SEL coderSel = @selector(initWithCoder:);
    if (class_getInstanceMethod(cls, coderSel)) {
        __block IMP originalCoder = NULL;
        IMP newCoder = imp_implementationWithBlock(^(id self, NSCoder *coder) {
            id result = ((id (*)(id, SEL, NSCoder*))originalCoder)(self, coderSel, coder);
            if (result) enableAllPrivacyFeatures(result);
            return result;
        });
        Method method = class_getInstanceMethod(cls, coderSel);
        if (method) {
            originalCoder = method_getImplementation(method);
            class_replaceMethod(cls, @selector(privacy_initWithCoder:), newCoder, method_getTypeEncoding(method));
            swizzleMethod(cls, coderSel, @selector(privacy_initWithCoder:));
        }
    }
}

#pragma mark - 截屏保护（保留）
static void enableScreenshotProtection(void) {
    Class managerClass = NSClassFromString(@"BDChatProtectionManager");
    if (managerClass) {
        SEL sharedSel = NSSelectorFromString(@"sharedInstance");
        if ([managerClass respondsToSelector:sharedSel]) {
            id manager = ((id (*)(id, SEL))objc_msgSend)(managerClass, sharedSel);
            if (manager) {
                setPropertyIfExists(manager, @"is_prohibit_chat_screenshot", @YES);
            }
        }
    }
    Class modelClass = NSClassFromString(@"BDChatProtectionModel");
    if (modelClass) {
        SEL sharedSel = NSSelectorFromString(@"sharedModel");
        if ([modelClass respondsToSelector:sharedSel]) {
            id model = ((id (*)(id, SEL))objc_msgSend)(modelClass, sharedSel);
            if (model) {
                setPropertyIfExists(model, @"is_prohibit_chat_screenshot", @YES);
            }
        }
    }
}

#pragma mark - 主动获取当前用户模型（登录后）
static void applyToCurrentUserModel(void) {
    id appDelegate = [UIApplication sharedApplication].delegate;
    if (!appDelegate) return;
    
    // 尝试获取 mineModel (BDMineUserModel)
    id mineModel = [appDelegate valueForKey:@"mineModel"];
    if (mineModel) {
        enableAllPrivacyFeatures(mineModel);
    }
    
    // 也可以尝试其他可能存储用户信息的属性
    id userInfo = [appDelegate valueForKey:@"userInfo"];
    if (userInfo) {
        enableAllPrivacyFeatures(userInfo);
    }
}

#pragma mark - 监听登录成功
static void observeLoginSuccess(void) {
    // 监听所有通知，找出登录成功的通知名（实际应用中可能是特定通知）
    [[NSNotificationCenter defaultCenter] addObserverForName:nil object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        // 打印通知名以便调试
        printf("[BluedPrivacy] Notification: %s\n", [note.name UTF8String]);
        // 常见的登录成功通知名可能是这些
        if ([note.name isEqualToString:@"BDLoginSuccessNotification"] ||
            [note.name isEqualToString:@"kBDLoginSuccessNotification"] ||
            [note.name isEqualToString:@"LoginSuccess"] ||
            [note.name isEqualToString:@"UserDidLoginNotification"]) {
            printf("[BluedPrivacy] Login success detected, applying privacy settings\n");
            applyToCurrentUserModel();
        }
    }];
}

#pragma mark - 入口
__attribute__((constructor))
static void initialize(void) {
    printf("[BluedPrivacy] dylib loaded\n");
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        hookBDMineUserModel();
        hookBDActivityDetailUserInfo();
        enableScreenshotProtection();
        applyToCurrentUserModel(); // 尝试立即设置（如果已登录）
        observeLoginSuccess();
    });
}