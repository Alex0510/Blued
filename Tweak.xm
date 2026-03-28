#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

__attribute__((constructor))
static void disableSVGA() {
    @autoreleasepool {
        // Hook SVGAPlayer
        Class svgaPlayer = NSClassFromString(@"SVGAPlayer");
        if (svgaPlayer) {
            // startAnimation
            SEL startSel = @selector(startAnimation);
            Method startMethod = class_getInstanceMethod(svgaPlayer, startSel);
            if (startMethod) {
                class_replaceMethod(svgaPlayer, startSel,
                                    imp_implementationWithBlock(^(id self) {}),
                                    method_getTypeEncoding(startMethod));
            }

            // startAnimationWithRange:reverse:
            SEL rangeSel = @selector(startAnimationWithRange:reverse:);
            Method rangeMethod = class_getInstanceMethod(svgaPlayer, rangeSel);
            if (rangeMethod) {
                class_replaceMethod(svgaPlayer, rangeSel,
                                    imp_implementationWithBlock(^(id self, NSRange range, BOOL reverse) {}),
                                    method_getTypeEncoding(rangeMethod));
            }
        }

        // Hook BDSVGAAnimationView
        Class svgaView = NSClassFromString(@"BDSVGAAnimationView");
        if (svgaView) {
            // startAnimation
            SEL startSel = @selector(startAnimation);
            Method startMethod = class_getInstanceMethod(svgaView, startSel);
            if (startMethod) {
                class_replaceMethod(svgaView, startSel,
                                    imp_implementationWithBlock(^(id self) {}),
                                    method_getTypeEncoding(startMethod));
            }

            // playWithResource:bundle:sizeBlock:completion:
            SEL play1Sel = @selector(playWithResource:bundle:sizeBlock:completion:);
            Method play1Method = class_getInstanceMethod(svgaView, play1Sel);
            if (play1Method) {
                class_replaceMethod(svgaView, play1Sel,
                                    imp_implementationWithBlock(^(id self, id res, id bundle, id sizeBlock, id completion) {}),
                                    method_getTypeEncoding(play1Method));
            }

            // playWithURLString:sizeBlock:completion:
            SEL play2Sel = @selector(playWithURLString:sizeBlock:completion:);
            Method play2Method = class_getInstanceMethod(svgaView, play2Sel);
            if (play2Method) {
                class_replaceMethod(svgaView, play2Sel,
                                    imp_implementationWithBlock(^(id self, id url, id sizeBlock, id completion) {}),
                                    method_getTypeEncoding(play2Method));
            }

            // playWithResource:bundle:completion:
            SEL play3Sel = @selector(playWithResource:bundle:completion:);
            Method play3Method = class_getInstanceMethod(svgaView, play3Sel);
            if (play3Method) {
                class_replaceMethod(svgaView, play3Sel,
                                    imp_implementationWithBlock(^(id self, id res, id bundle, id completion) {}),
                                    method_getTypeEncoding(play3Method));
            }

            // playWithURLString:completion:
            SEL play4Sel = @selector(playWithURLString:completion:);
            Method play4Method = class_getInstanceMethod(svgaView, play4Sel);
            if (play4Method) {
                class_replaceMethod(svgaView, play4Sel,
                                    imp_implementationWithBlock(^(id self, id url, id completion) {}),
                                    method_getTypeEncoding(play4Method));
            }
        }
    }
}