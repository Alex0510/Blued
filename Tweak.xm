#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

__attribute__((constructor))
static void enableTracelessAccess() {
    @autoreleasepool {
        // 1. 获取 UserSetting 类
        Class userSettingClass = NSClassFromString(@"UserSetting");
        if (!userSettingClass) return;

        // 2. 强制 setter 将传入值改为 1
        SEL setterSel = @selector(setIs_traceless_access:);
        Method originalSetter = class_getInstanceMethod(userSettingClass, setterSel);
        if (originalSetter) {
            IMP newImp = imp_implementationWithBlock(^(id self, int value) {
                // 忽略传入值，强制设为 1
                ((void (*)(id, SEL, int))method_getImplementation(originalSetter))(self, setterSel, 1);
            });
            class_replaceMethod(userSettingClass, setterSel, newImp, method_getTypeEncoding(originalSetter));
        }

        // 3. 强制 getter 返回 1
        SEL getterSel = @selector(is_traceless_access);
        Method originalGetter = class_getInstanceMethod(userSettingClass, getterSel);
        if (originalGetter) {
            IMP newImp = imp_implementationWithBlock(^(id self) {
                return 1;
            });
            class_replaceMethod(userSettingClass, getterSel, newImp, method_getTypeEncoding(originalGetter));
        }

        // 4. 如果 UserSetting 存在单例，主动设置一次
        SEL sharedSel = NSSelectorFromString(@"shared");
        if ([userSettingClass respondsToSelector:sharedSel]) {
            id sharedInstance = [userSettingClass performSelector:sharedSel];
            if (sharedInstance) {
                [sharedInstance setValue:@1 forKey:@"is_traceless_access"];
            }
        }

        // 5. Hook 网络请求，确保提交到服务器的参数中也包含 is_traceless_access=1
        Class httpManagerClass = NSClassFromString(@"BDHTTPManager");
        if (httpManagerClass) {
            SEL updateSel = NSSelectorFromString(@"updateUserSetting:");
            Method originalUpdate = class_getInstanceMethod(httpManagerClass, updateSel);
            if (originalUpdate) {
                IMP newImp = imp_implementationWithBlock(^(id self, NSDictionary *params) {
                    NSMutableDictionary *newParams = [params mutableCopy];
                    newParams[@"is_traceless_access"] = @(1);
                    ((void (*)(id, SEL, id))method_getImplementation(originalUpdate))(self, updateSel, newParams);
                });
                class_replaceMethod(httpManagerClass, updateSel, newImp, method_getTypeEncoding(originalUpdate));
            }
        }

        // 6. 输出日志，便于调试
        NSLog(@"[Blued] 无痕访问已强制开启");
    }
}