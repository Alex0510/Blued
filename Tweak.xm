/* Tweak.xm - 移除 BDHealthServiceCollectionCell 中的占位插图 */
#import <UIKit/UIKit.h>

// 完整的类接口声明（已移除 .cxx_destruct）
@interface BDHealthServiceCollectionCell : UIView
// 属性
@property id centerView;
@property id titleLabel;
@property id mainStackView;
@property id firstCollectionTitle;
@property id firstCollectionImgView;
@property id secondCollectionTitle;
@property id secondCollectionImgView;
@property id publicBenefitView;
@property id publicBenefitTitleLabel;
@property id publicBenefitDescLabel;
@property id publicStackView;
@property id publicStackImgView1;
@property id publicStackImgView2;
@property id hullHealthView;
@property id hullHealthTitleLabel;
@property id hullHealthDescLabel;
@property id hullHealthImgView;
@property id healthStoreView;
@property id healthLineView;
@property id healthStoreTitleLabel;
@property id healthStoreDescLabel;
@property id healthStackView;
@property id healthStackImgView1;
@property id healthStackImgView2;
@property id publicBenefitAndHullHealthView2;
@property id publicBenefitView2;
@property id publicBenefitImageView2;
@property id publicBenefitTitleLabel2;
@property id publicBenefitDescLabel2;
@property id hullHealthView2;
@property id hullHealthImgView2;
@property id hullHealthTitleLabel2;
@property id hullHealthDescLabel2;
@property id productToPromotionView;
@property id separateLineView;
@property id productListScrollView;
@property id publicBenefitModel;
@property id hullHealthModel;
@property id productToPromotionViewsArrayM;
@property id cTimer;
@property id healthStoreModel;
@property id marqueeView;
@property id marqueeItemView;
@property id redPointView1;
@property id redPointView2;
@property id redPointView3;
@property id bannerSortDictM;
@property BOOL isTouristsMode;
@property id signal;

// 原始方法（可选，仅为了完整性）
- (void)awakeFromNib;
- (void)setSignal:(id)arg;
- (void)layoutSubviews;
- (void)startTimer;
- (void)addObserver;
- (uint64_t)textLength:(id)arg;
- (id)subText:(id)arg toLength:(long long)len;
- (void)stopMarquee;
- (void)clickPublicBenefitView;
- (void)clickHullHealthView;
- (void)clickHealthStoreView;
- (void)clickProductToPromotionView:(id)view redPointInView:(id)redPoint;
- (void)clickFirstCollection:(id)arg;
- (void)clickSecondCollection:(id)arg;
- (Class)customMarqueeItemViewClass;
- (void)didSelectedModel:(id)model atIndex:(int)index;
- (id)marqueeView;
- (id)marqueeItemView;
- (id)redPointView1;
- (id)redPointView2;
- (id)redPointView3;
- (id)productListScrollView;
- (id)bannerSortDictM;
- (BOOL)isTouristsMode;
- (void)setIsTouristsMode:(BOOL)mode;
- (id)signal;
- (id)centerView;
- (void)setCenterView:(id)view;
- (id)titleLabel;
- (void)setTitleLabel:(id)label;
- (id)mainStackView;
- (void)setMainStackView:(id)view;
- (id)firstCollectionTitle;
- (void)setFirstCollectionTitle:(id)title;
- (id)firstCollectionImgView;
- (void)setFirstCollectionImgView:(id)view;
- (id)secondCollectionTitle;
- (void)setSecondCollectionTitle:(id)title;
- (id)secondCollectionImgView;
- (void)setSecondCollectionImgView:(id)view;
- (id)publicBenefitView;
- (void)setPublicBenefitView:(id)view;
- (id)publicBenefitTitleLabel;
- (void)setPublicBenefitTitleLabel:(id)label;
- (id)publicBenefitDescLabel;
- (void)setPublicBenefitDescLabel:(id)label;
- (id)publicStackView;
- (void)setPublicStackView:(id)view;
- (id)publicStackImgView1;
- (void)setPublicStackImgView1:(id)view;
- (id)publicStackImgView2;
- (void)setPublicStackImgView2:(id)view;
- (id)hullHealthView;
- (void)setHullHealthView:(id)view;
- (id)hullHealthTitleLabel;
- (void)setHullHealthTitleLabel:(id)label;
- (id)hullHealthDescLabel;
- (void)setHullHealthDescLabel:(id)label;
- (id)hullHealthImgView;
- (void)setHullHealthImgView:(id)view;
- (id)healthStoreView;
- (void)setHealthStoreView:(id)view;
- (id)healthLineView;
- (void)setHealthLineView:(id)view;
- (id)healthStoreTitleLabel;
- (void)setHealthStoreTitleLabel:(id)label;
- (id)healthStoreDescLabel;
- (void)setHealthStoreDescLabel:(id)label;
- (id)healthStackView;
- (void)setHealthStackView:(id)view;
- (id)healthStackImgView1;
- (void)setHealthStackImgView1:(id)view;
- (id)healthStackImgView2;
- (void)setHealthStackImgView2:(id)view;
- (id)publicBenefitAndHullHealthView2;
- (void)setPublicBenefitAndHullHealthView2:(id)view;
- (id)publicBenefitView2;
- (void)setPublicBenefitView2:(id)view;
- (id)publicBenefitImageView2;
- (void)setPublicBenefitImageView2:(id)view;
- (id)publicBenefitTitleLabel2;
- (void)setPublicBenefitTitleLabel2:(id)label;
- (id)publicBenefitDescLabel2;
- (void)setPublicBenefitDescLabel2:(id)label;
- (id)hullHealthView2;
- (void)setHullHealthView2:(id)view;
- (id)hullHealthImgView2;
- (void)setHullHealthImgView2:(id)view;
- (id)hullHealthTitleLabel2;
- (void)setHullHealthTitleLabel2:(id)label;
- (id)hullHealthDescLabel2;
- (void)setHullHealthDescLabel2:(id)label;
- (id)productToPromotionView;
- (void)setProductToPromotionView:(id)view;
- (id)separateLineView;
- (void)setSeparateLineView:(id)view;
- (void)setProductListScrollView:(id)view;
- (id)publicBenefitModel;
- (void)setPublicBenefitModel:(id)model;
- (id)hullHealthModel;
- (void)setHullHealthModel:(id)model;
- (id)productToPromotionViewsArrayM;
- (void)setProductToPromotionViewsArrayM:(id)array;
- (id)cTimer;
- (void)setCTimer:(id)timer;
- (id)healthStoreModel;
- (void)setHealthStoreModel:(id)model;
- (void)setMarqueeView:(id)view;
- (void)setMarqueeItemView:(id)view;
- (void)setRedPointView1:(id)view;
- (void)setRedPointView2:(id)view;
- (void)setRedPointView3:(id)view;
- (void)setBannerSortDictM:(id)dict;
@end

// 添加类别声明新方法，使编译器可见
@interface BDHealthServiceCollectionCell (Tweak)
- (void)removePlaceholderImageViews;
- (void)removeAllImageViewsInView:(UIView *)view;
@end

// 开始 Hook
%hook BDHealthServiceCollectionCell

// 在 awakeFromNib 中执行移除操作
- (void)awakeFromNib {
    %orig;
    [self removePlaceholderImageViews];
}

// 使用 %new 添加新方法：移除指定的占位视图
%new
- (void)removePlaceholderImageViews {
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
        UIView *view = [self valueForKey:prop];
        if (view && [view isKindOfClass:[UIView class]]) {
            [view removeFromSuperview];
            NSLog(@"[Tweak] Removed %@ from BDHealthServiceCollectionCell", prop);
        }
    }
}

// 使用 %new 添加新方法：递归移除所有 UIImageView
%new
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