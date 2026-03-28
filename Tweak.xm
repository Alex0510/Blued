#import <objc/runtime.h>
#import <Foundation/Foundation.h>

static void SwizzleMethod(Class cls, SEL originalSelector, SEL swizzledSelector) {
    Method originalMethod = class_getInstanceMethod(cls, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(cls, swizzledSelector);
    
    BOOL didAddMethod = class_addMethod(cls, originalSelector,
                                        method_getImplementation(swizzledMethod),
                                        method_getTypeEncoding(swizzledMethod));
    if (didAddMethod) {
        class_replaceMethod(cls, swizzledSelector,
                            method_getImplementation(originalMethod),
                            method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}

// 替换 SVGAPlayer 的 startAnimation 方法
static void DummyStartAnimation(id self, SEL _cmd) {
    // 什么都不做，直接返回
}

// 替换 SVGAPlayer 的 startAnimationWithRange:reverse:
static void DummyStartAnimationWithRange(id self, SEL _cmd, struct NSRange range, BOOL reverse) {
    // 不执行任何动画
}

// 替换 BDSVGAAnimationView 的 playWithResource 相关方法
static void DummyPlayWithResource(id self, SEL _cmd, id resource, id bundle, id sizeBlock, id completion) {
    // 阻止播放
}

static void DummyPlayWithURLString(id self, SEL _cmd, id urlString, id completion) {
    // 阻止播放
}

static void DummyPlayWithResourceWithCompletion(id self, SEL _cmd, id resource, id bundle, id completion) {
    // 阻止播放
}

static void DummyPlayWithURLStringWithCompletion(id self, SEL _cmd, id urlString, id completion) {
    // 阻止播放
}

// 替换 BDSVGAAnimationView 的 startAnimation 方法
static void DummyStartAnimationForSVGAView(id self, SEL _cmd) {
    // 阻止动画开始
}

__attribute__((constructor))
static void disableSVGA() {
    @autoreleasepool {
        // 1. Hook SVGAPlayer
        Class svgaPlayerClass = NSClassFromString(@"SVGAPlayer");
        if (svgaPlayerClass) {
            // 替换 startAnimation
            SEL startSel = @selector(startAnimation);
            Method startMethod = class_getInstanceMethod(svgaPlayerClass, startSel);
            if (startMethod) {
                class_replaceMethod(svgaPlayerClass, startSel,
                                    imp_implementationWithBlock(^(id self) {}),
                                    method_getTypeEncoding(startMethod));
            }
            
            // 替换 startAnimationWithRange:reverse:
            SEL rangeSel = @selector(startAnimationWithRange:reverse:);
            Method rangeMethod = class_getInstanceMethod(svgaPlayerClass, rangeSel);
            if (rangeMethod) {
                class_replaceMethod(svgaPlayerClass, rangeSel,
                                    imp_implementationWithBlock(^(id self, struct NSRange range, BOOL reverse) {}),
                                    method_getTypeEncoding(rangeMethod));
            }
        }
        
        // 2. Hook BDSVGAAnimationView
        Class svgaViewClass = NSClassFromString(@"BDSVGAAnimationView");
        if (svgaViewClass) {
            // 替换 startAnimation
            SEL startSel = @selector(startAnimation);
            Method startMethod = class_getInstanceMethod(svgaViewClass, startSel);
            if (startMethod) {
                class_replaceMethod(svgaViewClass, startSel,
                                    imp_implementationWithBlock(^(id self) {}),
                                    method_getTypeEncoding(startMethod));
            }
            
            // 替换多个 playWithResource 方法
            SEL play1Sel = @selector(playWithResource:bundle:sizeBlock:completion:);
            Method play1Method = class_getInstanceMethod(svgaViewClass, play1Sel);
            if (play1Method) {
                class_replaceMethod(svgaViewClass, play1Sel,
                                    imp_implementationWithBlock(^(id self, id res, id bundle, id sizeBlock, id completion) {}),
                                    method_getTypeEncoding(play1Method));
            }
            
            SEL play2Sel = @selector(playWithURLString:sizeBlock:completion:);
            Method play2Method = class_getInstanceMethod(svgaViewClass, play2Sel);
            if (play2Method) {
                class_replaceMethod(svgaViewClass, play2Sel,
                                    imp_implementationWithBlock(^(id self, id url, id sizeBlock, id completion) {}),
                                    method_getTypeEncoding(play2Method));
            }
            
            SEL play3Sel = @selector(playWithResource:bundle:completion:);
            Method play3Method = class_getInstanceMethod(svgaViewClass, play3Sel);
            if (play3Method) {
                class_replaceMethod(svgaViewClass, play3Sel,
                                    imp_implementationWithBlock(^(id self, id res, id bundle, id completion) {}),
                                    method_getTypeEncoding(play3Method));
            }
            
            SEL play4Sel = @selector(playWithURLString:completion:);
            Method play4Method = class_getInstanceMethod(svgaViewClass, play4Sel);
            if (play4Method) {
                class_replaceMethod(svgaViewClass, play4Sel,
                                    imp_implementationWithBlock(^(id self, id url, id completion) {}),
                                    method_getTypeEncoding(play4Method));
            }
        }
    }
}