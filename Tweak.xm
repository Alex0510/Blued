#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

__attribute__((constructor))
static void enableTracelessAccess() {
    @autoreleasepool {
        // 1. 强制 getter 返回 1
        Class userSettingClass = NSClassFromString(@"UserSetting");
        if (userSettingClass) {
            SEL getterSel = @selector(is_traceless_access);
            Method originalGetter = class_getInstanceMethod(userSettingClass, getterSel);
            if (originalGetter) {
                IMP newImp = imp_implementationWithBlock(^(id self) {
                    return 1;
                });
                class_replaceMethod(userSettingClass, getterSel, newImp, method_getTypeEncoding(originalGetter));
            }
        }

        // 2. Hook 网络请求，强制提交参数 is_traceless_access=1
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

        NSLog(@"[Blued] 无痕访问已强制开启（仅修改 getter 和网络请求）");
    }
}