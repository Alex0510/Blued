#import <UIKit/UIKit.h>
#import <objc/runtime.h>

// 辅助函数：设置 CollectionView 的滚动行为
static void fixCollectionViewScrollBehavior(UICollectionView *collectionView) {
    if (!collectionView) return;
    static void *kOnceToken = &kOnceToken;
    if (objc_getAssociatedObject(collectionView, kOnceToken)) return;
    
    // 禁止垂直方向弹性（即使内容不足也不会产生滑动空白）
    collectionView.alwaysBounceVertical = NO;
    collectionView.bounces = NO;
    
    // 如果内容总高度 ≤ 可视高度，则完全禁用滚动
    if (collectionView.contentSize.height <= collectionView.bounds.size.height) {
        collectionView.scrollEnabled = NO;
    }
    
    objc_setAssociatedObject(collectionView, kOnceToken, @(YES), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

// 隐藏各类服务 Cell 并修正滚动视图
%hook BDMineServiceCollectionCell
- (void)layoutSubviews {
    %orig;
    UIView *view = (UIView *)self;
    view.frame = CGRectMake(view.frame.origin.x, view.frame.origin.y, view.frame.size.width, 0);
    view.hidden = YES;
    
    // 获取所在的 CollectionView 并修复滚动行为
    UICollectionView *collectionView = (UICollectionView *)view.superview;
    if ([collectionView isKindOfClass:[UICollectionView class]]) {
        fixCollectionViewScrollBehavior(collectionView);
    }
}
%end

%hook BDOtherServiceCollectionCell
- (void)layoutSubviews {
    %orig;
    UIView *view = (UIView *)self;
    view.frame = CGRectMake(view.frame.origin.x, view.frame.origin.y, view.frame.size.width, 0);
    view.hidden = YES;
    
    UICollectionView *collectionView = (UICollectionView *)view.superview;
    if ([collectionView isKindOfClass:[UICollectionView class]]) {
        fixCollectionViewScrollBehavior(collectionView);
    }
}
%end

%hook BDLiveServiceCollectionCell
- (void)layoutSubviews {
    %orig;
    UIView *view = (UIView *)self;
    view.frame = CGRectMake(view.frame.origin.x, view.frame.origin.y, view.frame.size.width, 0);
    view.hidden = YES;
    
    UICollectionView *collectionView = (UICollectionView *)view.superview;
    if ([collectionView isKindOfClass:[UICollectionView class]]) {
        fixCollectionViewScrollBehavior(collectionView);
    }
}
%end

%hook BDAudioServiceCollectionViewCell
- (void)layoutSubviews {
    %orig;
    UIView *view = (UIView *)self;
    view.frame = CGRectMake(view.frame.origin.x, view.frame.origin.y, view.frame.size.width, 0);
    view.hidden = YES;
    
    UICollectionView *collectionView = (UICollectionView *)view.superview;
    if ([collectionView isKindOfClass:[UICollectionView class]]) {
        fixCollectionViewScrollBehavior(collectionView);
    }
}
%end

%hook BDHealthServiceCollectionCell
- (void)layoutSubviews {
    %orig;
    UIView *view = (UIView *)self;
    view.frame = CGRectMake(view.frame.origin.x, view.frame.origin.y, view.frame.size.width, 0);
    view.hidden = YES;
    
    UICollectionView *collectionView = (UICollectionView *)view.superview;
    if ([collectionView isKindOfClass:[UICollectionView class]]) {
        fixCollectionViewScrollBehavior(collectionView);
    }
}
%end