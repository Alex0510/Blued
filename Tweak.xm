/* Tweak.xm - 移除 BDHealthServiceCollectionCell 中的占位插图 */

#import <UIKit/UIKit.h>

// 声明目标类（可选，但有助于代码提示）
@class BDHealthServiceCollectionCell;

%hook BDHealthServiceCollectionCell

// Cell 从 XIB 唤醒时执行移除操作
- (void)awakeFromNib {
    %orig; // 先调用原始方法
    [self removePlaceholderImageViews];
}

// 移除所有指定的占位视图
- (void)removePlaceholderImageViews {
    // 需要移除的视图属性名列表（根据头文件定义）
    NSArray<NSString *> *viewProps = @[
        @"firstCollectionImgView",
        @"secondCollectionImgView",
        @"publicStackImgView1",
        @"publicStackImgView2",
        @"hullHealthImgView",
        @"healthStackImgView1",
        @"healthStackImgView2",
        @"publicBenefitImageView2",
        @"hullHealthImgView2",
        @"redPointView1",
        @"redPointView2",
        @"redPointView3"
    ];
    
    for (NSString *prop in viewProps) {
        // 通过 KVC 获取属性对应的视图
        UIView *view = [self valueForKey:prop];
        if (view && [view isKindOfClass:[UIView class]]) {
            [view removeFromSuperview];
            NSLog(@"[Tweak] Removed %@ from BDHealthServiceCollectionCell", prop);
        }
    }
}

// 备选：递归移除所有 UIImageView（如果上述方法不够彻底）
- (void)removeAllImageViewsInView:(UIView *)view {
    for (UIView *subview in view.subviews) {
        if ([subview isKindOfClass:[UIImageView class]]) {
            [subview removeFromSuperview];
        } else {
            [self removeAllImageViewsInView:subview];
        }
    }
}

%end