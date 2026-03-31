#import <UIKit/UIKit.h>

#pragma mark - BDSVGAAnimationView 拦截

%hook BDSVGAAnimationView

// 拦截本地资源播放
- (void)playWithResource:(id)resource bundle:(id)bundle completion:(id)completion {
    NSLog(@"[SVGA BLOCK] playWithResource blocked");
    return;
}

// 拦截网络资源播放
- (void)playWithURLString:(id)url completion:(id)completion {
    NSLog(@"[SVGA BLOCK] playWithURLString blocked: %@", url);
    return;
}

// 带 sizeBlock 的版本
- (void)playWithResource:(id)resource bundle:(id)bundle sizeBlock:(id)sizeBlock completion:(id)completion {
    NSLog(@"[SVGA BLOCK] playWithResource(sizeBlock) blocked");
    return;
}

- (void)playWithURLString:(id)url sizeBlock:(id)sizeBlock completion:(id)completion {
    NSLog(@"[SVGA BLOCK] playWithURLString(sizeBlock) blocked: %@", url);
    return;
}

// 防止手动启动
- (void)startAnimation {
    NSLog(@"[SVGA BLOCK] startAnimation blocked");
    return;
}

// 防止恢复播放
- (void)layoutSubviews {
    %orig;
    [self stopAnimation];
}

// 确保停止
- (void)didMoveToWindow {
    %orig;
    [self stopAnimation];
}

%end


#pragma mark - SVGAPlayer 底层兜底拦截

%hook SVGAPlayer

// 阻止开始播放
- (void)startAnimation {
    NSLog(@"[SVGA BLOCK] SVGAPlayer start blocked");
    return;
}

// 阻止范围播放
- (void)startAnimationWithRange:(struct { long long location; long long length; })range reverse:(BOOL)reverse {
    NSLog(@"[SVGA BLOCK] startAnimationWithRange blocked");
    return;
}

// 强制停止
- (void)layoutSubviews {
    %orig;
    [self stopAnimation];
}

// 防止 step 播放
- (void)stepToFrame:(long long)frame andPlay:(BOOL)play {
    NSLog(@"[SVGA BLOCK] stepToFrame blocked");
    return;
}

- (void)stepToPercentage:(double)percent andPlay:(BOOL)play {
    NSLog(@"[SVGA BLOCK] stepToPercentage blocked");
    return;
}

%end


#pragma mark - 可选：直接隐藏动画 View（更狠）

%hook BDSVGAAnimationView

- (void)setHidden:(BOOL)hidden {
    %orig(YES); // 强制隐藏
}

- (void)setAlpha:(CGFloat)alpha {
    %orig(0.0); // 完全透明
}

%end