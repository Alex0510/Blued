#import <UIKit/UIKit.h>

typedef struct {
    long long location;
    long long length;
} SVGAFrameRange;

@interface BDSVGAAnimationView : UIView
@end

@interface SVGAPlayer : NSObject
@end


#pragma mark - 只拦截播放（核心）

%hook BDSVGAAnimationView

- (void)playWithResource:(id)resource bundle:(id)bundle completion:(id)completion {
    NSLog(@"[SVGA BLOCK] resource");
    return;
}

- (void)playWithURLString:(id)url completion:(id)completion {
    NSLog(@"[SVGA BLOCK] url: %@", url);
    return;
}

- (void)playWithResource:(id)resource bundle:(id)bundle sizeBlock:(id)sizeBlock completion:(id)completion {
    return;
}

- (void)playWithURLString:(id)url sizeBlock:(id)sizeBlock completion:(id)completion {
    return;
}

- (void)startAnimation {
    return;
}

%end


#pragma mark - 底层兜底（可选）

%hook SVGAPlayer

- (void)startAnimation {
    return;
}

- (void)startAnimationWithRange:(SVGAFrameRange)range reverse:(BOOL)reverse {
    return;
}

%end