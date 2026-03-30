#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <UIKit/UIKit.h>

// 需要拦截的 cell 类名列表
static NSArray<NSString *> *targetClassNames = @[
    @"BDMineServiceCollectionCell",      // 我的服务
    @"BDOtherServiceCollectionCell",     // 其他服务
    @"BDLiveServiceCollectionCell",      // 直播服务
    @"BDAudioServiceCollectionViewCell", // 聊天室服务
    @"BDHealthServiceCollectionCell"     // 健康服务
];

// 通用的 swizzle 方法
static void swizzleSelector(Class cls, SEL original, SEL swizzled) {
    Method originalMethod = class_getInstanceMethod(cls, original);
    Method swizzledMethod = class_getInstanceMethod(cls, swizzled);
    if (originalMethod && swizzledMethod) {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}

// 动态库初始化
__attribute__((constructor))
static void initialize_dylib() {
    for (NSString *className in targetClassNames) {
        Class cellClass = NSClassFromString(className);
        if (!cellClass) continue;

        // 拦截 layoutSubviews，将 frame 高度强制设为 0
        SEL originalLayout = @selector(layoutSubviews);
        SEL swizzledLayout = @selector(zeroHeight_layoutSubviews);
        swizzleSelector(cellClass, originalLayout, swizzledLayout);

        // 可选：拦截 setHidden: 防止外部再次显示
        SEL originalSetHidden = @selector(setHidden:);
        SEL swizzledSetHidden = @selector(zeroHeight_setHidden:);
        swizzleSelector(cellClass, originalSetHidden, swizzledSetHidden);
    }
}

// 类别，提供替换方法
@interface NSObject (ZeroHeightCell)
- (void)zeroHeight_layoutSubviews;
- (void)zeroHeight_setHidden:(BOOL)hidden;
@end

@implementation NSObject (ZeroHeightCell)

- (void)zeroHeight_layoutSubviews {
    // 先调用原方法（保证其他初始化执行）
    [self zeroHeight_layoutSubviews];

    // 如果当前对象确实是目标 cell 类型，强制将高度设为 0
    if ([self isKindOfClass:NSClassFromString(@"BDMineServiceCollectionCell")] ||
        [self isKindOfClass:NSClassFromString(@"BDOtherServiceCollectionCell")] ||
        [self isKindOfClass:NSClassFromString(@"BDLiveServiceCollectionCell")] ||
        [self isKindOfClass:NSClassFromString(@"BDAudioServiceCollectionViewCell")] ||
        [self isKindOfClass:NSClassFromString(@"BDHealthServiceCollectionCell")]) {

        CGRect frame = [self frame];
        if (frame.size.height > 0) {
            frame.size.height = 0;
            [self setFrame:frame];
            [self setHidden:YES];
        }
    }
}

- (void)zeroHeight_setHidden:(BOOL)hidden {
    // 强制保持隐藏，避免后续被显示
    [self zeroHeight_setHidden:YES];
}

@end