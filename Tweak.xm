#import <UIKit/UIKit.h>

#pragma mark - 修复 struct（必须写！）

typedef struct {
    long long location;
    long long length;
} SVGAFrameRange;


#pragma mark - 补全接口（解决 forward declaration 问题）

@interface BDSVGAAnimationView : UIView
- (void)stopAnimation;
- (void)startAnimation;
@end

@interface SVGAPlayer : NSObject
- (void)stopAnimation;
@end


#pragma mark - BDSVGAAnimationView

%hook BDSVGAAnimationView

- (void)playWithResource:(id)resource bundle:(id)bundle completion:(id)completion {
    NSLog(@"[SVGA BLOCK] resource blocked");
    return;
}

- (void)playWithURLString:(id)url completion:(id)completion {
    NSLog(@"[SVGA BLOCK] url blocked: %@", url);
    return;
}

- (void)playWithResource:(id)resource bundle:(id)bundle sizeBlock:(id)sizeBlock completion:(id)completion {
    NSLog(@"[SVGA BLOCK] resource(size) blocked");
    return;
}

- (void)playWithURLString:(id)url sizeBlock:(id)sizeBlock completion:(id)completion {
    NSLog(@"[SVGA BLOCK] url(size) blocked: %@", url);
    return;
}

- (void)startAnimation {
    NSLog(@"[SVGA BLOCK] startAnimation blocked");
    return;
}

- (void)layoutSubviews {
    %orig;
    [self stopAnimation];
}

- (void)didMoveToWindow {
    %orig;
    [self stopAnimation];
}

%end


#pragma mark - SVGAPlayer 底层兜底

%hook SVGAPlayer

- (void)startAnimation {
    NSLog(@"[SVGA BLOCK] player start blocked");
    return;
}

- (void)startAnimationWithRange:(SVGAFrameRange)range reverse:(BOOL)reverse {
    NSLog(@"[SVGA BLOCK] range start blocked");
    return;
}

- (void)stepToFrame:(long long)frame andPlay:(BOOL)play {
    return;
}

- (void)stepToPercentage:(double)percent andPlay:(BOOL)play {
    return;
}

- (void)layoutSubviews {
    %orig;
    [self stopAnimation];
}

%end


#pragma mark - 强制隐藏（可选更狠）

%hook BDSVGAAnimationView

- (void)setHidden:(BOOL)hidden {
    %orig(YES);
}

- (void)setAlpha:(CGFloat)alpha {
    %orig(0.0);
}

%end