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

        // 4. 如果 UserSetting 存在单例，在初始化时主动设置
        SEL sharedSel = NSSelectorFromString(@"shared");
        if ([userSettingClass respondsToSelector:sharedSel]) {
            id sharedInstance = ((id (*)(id, SEL))objc_msgSend)(userSettingClass, sharedSel);
            if (sharedInstance) {
                ((void (*)(id, SEL, int))objc_msgSend)(sharedInstance, setterSel, 1);
            }
        } else {
            // 尝试通过归档等方式获取当前设置实例，这里简化为遍历所有实例（效率较低，仅示例）
            // 通常单例模式更常见，若没有则忽略
        }

        // 5. 可选：Hook 网络请求，确保提交到服务器的参数中也包含 is_traceless_access=1
        // 这里假设设置通过 BDHTTPManager 的某个方法提交，例如 updateUserSetting:
        Class httpManagerClass = NSClassFromString(@"BDHTTPManager");
        if (httpManagerClass) {
            SEL updateSel = NSSelectorFromString(@"updateUserSetting:");
            Method originalUpdate = class_getInstanceMethod(httpManagerClass, updateSel);
            if (originalUpdate) {
                IMP newImp = imp_implementationWithBlock(^(id self, NSDictionary *params) {
                    // 修改参数
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