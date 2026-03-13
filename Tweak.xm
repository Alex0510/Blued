#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>

#pragma mark - Utils

static inline void BDHideAllSubviews(UIView *view) {
    if (!view) return;

    view.hidden = YES;
    view.alpha = 0.0;
    view.clipsToBounds = YES;
    view.userInteractionEnabled = NO;

    // 压缩 frame，减少可见占位
    CGRect f = view.frame;
    f.size.width = 0.01;
    f.size.height = 0.01;
    view.frame = f;

    if ([view respondsToSelector:@selector(setBounds:)]) {
        view.bounds = CGRectMake(0, 0, 0.01, 0.01);
    }

    for (NSLayoutConstraint *c in view.constraints) {
        if (c.firstAttribute == NSLayoutAttributeHeight ||
            c.firstAttribute == NSLayoutAttributeWidth ||
            c.firstAttribute == NSLayoutAttributeTop ||
            c.firstAttribute == NSLayoutAttributeBottom ||
            c.firstAttribute == NSLayoutAttributeLeading ||
            c.firstAttribute == NSLayoutAttributeTrailing) {
            c.constant = 0;
        }
    }

    for (UIView *sub in view.subviews) {
        sub.hidden = YES;
        sub.alpha = 0.0;
        sub.userInteractionEnabled = NO;

        CGRect sf = sub.frame;
        sf.size.width = 0.01;
        sf.size.height = 0.01;
        sub.frame = sf;
        sub.bounds = CGRectMake(0, 0, 0.01, 0.01);

        for (NSLayoutConstraint *c in sub.constraints) {
            if (c.firstAttribute == NSLayoutAttributeHeight ||
                c.firstAttribute == NSLayoutAttributeWidth ||
                c.firstAttribute == NSLayoutAttributeTop ||
                c.firstAttribute == NSLayoutAttributeBottom ||
                c.firstAttribute == NSLayoutAttributeLeading ||
                c.firstAttribute == NSLayoutAttributeTrailing) {
                c.constant = 0;
            }
        }
    }

    [view setNeedsLayout];
    [view layoutIfNeeded];
}

static inline void BDCollapseCollectionCell(UICollectionViewCell *cell) {
    if (!cell) return;

    cell.hidden = YES;
    cell.alpha = 0.0;
    cell.clipsToBounds = YES;
    cell.userInteractionEnabled = NO;

    // 自身压缩
    CGRect f = cell.frame;
    f.size.width = 0.01;
    f.size.height = 0.01;
    cell.frame = f;
    cell.bounds = CGRectMake(0, 0, 0.01, 0.01);

    if (cell.contentView) {
        BDHideAllSubviews(cell.contentView);
        cell.contentView.hidden = YES;
        cell.contentView.alpha = 0.0;
        cell.contentView.frame = CGRectMake(0, 0, 0.01, 0.01);
        cell.contentView.bounds = CGRectMake(0, 0, 0.01, 0.01);
    }

    // 压缩当前 cell 自己的约束
    for (NSLayoutConstraint *c in cell.constraints) {
        if (c.firstAttribute == NSLayoutAttributeHeight ||
            c.firstAttribute == NSLayoutAttributeWidth) {
            c.constant = 0;
        }
    }

    [cell setNeedsLayout];
    [cell layoutIfNeeded];
}

#pragma mark - Base Hook Macro

#define HOOK_REMOVE_CELL(CLASSNAME) \
%hook CLASSNAME \
- (void)awakeFromNib { \
    %orig; \
    BDCollapseCollectionCell((UICollectionViewCell *)self); \
} \
- (void)layoutSubviews { \
    %orig; \
    BDCollapseCollectionCell((UICollectionViewCell *)self); \
} \
- (void)prepareForReuse { \
    %orig; \
    BDCollapseCollectionCell((UICollectionViewCell *)self); \
} \
- (CGSize)sizeThatFits:(CGSize)size { \
    return CGSizeMake(0.01, 0.01); \
} \
- (CGSize)systemLayoutSizeFittingSize:(CGSize)targetSize { \
    return CGSizeMake(0.01, 0.01); \
} \
- (UICollectionViewLayoutAttributes *)preferredLayoutAttributesFittingAttributes:(UICollectionViewLayoutAttributes *)layoutAttributes { \
    UICollectionViewLayoutAttributes *attrs = %orig; \
    if (attrs) { \
        CGRect f = attrs.frame; \
        f.size.width = 0.01; \
        f.size.height = 0.01; \
        attrs.frame = f; \
    } \
    return attrs; \
} \
%end

#pragma mark - Target Cells

HOOK_REMOVE_CELL(BDAudioServiceCollectionViewCell)
HOOK_REMOVE_CELL(BDLiveServiceCollectionCell)
HOOK_REMOVE_CELL(BDOtherServiceCollectionCell)
HOOK_REMOVE_CELL(BDHealthServiceCollectionCell)

#pragma mark - Extra: 针对 BDOtherServiceCollectionCell 已知子视图进一步清理

%hook BDOtherServiceCollectionCell

- (void)awakeFromNib {
    %orig;

    @try {
        NSArray *keys = @[
            @"titleLabel",
            @"titleImgView",
            @"rainBowView",
            @"rainBowTitleLabel",
            @"rainBowNumberLabel",
            @"rainBowDescLabel",
            @"helpView",
            @"helpTitleLabel",
            @"helpRedPoint",
            @"emojiView",
            @"emojiTitleLabel",
            @"bannerView"
        ];

        for (NSString *key in keys) {
            id obj = [self valueForKey:key];
            if ([obj isKindOfClass:[UIView class]]) {
                BDHideAllSubviews((UIView *)obj);
            }
        }
    } @catch (__unused NSException *e) {}

    BDCollapseCollectionCell((UICollectionViewCell *)self);
}

- (void)layoutSubviews {
    %orig;

    @try {
        NSArray *keys = @[
            @"titleLabel",
            @"titleImgView",
            @"rainBowView",
            @"rainBowTitleLabel",
            @"rainBowNumberLabel",
            @"rainBowDescLabel",
            @"helpView",
            @"helpTitleLabel",
            @"helpRedPoint",
            @"emojiView",
            @"emojiTitleLabel",
            @"bannerView"
        ];

        for (NSString *key in keys) {
            id obj = [self valueForKey:key];
            if ([obj isKindOfClass:[UIView class]]) {
                BDHideAllSubviews((UIView *)obj);
            }
        }
    } @catch (__unused NSException *e) {}

    BDCollapseCollectionCell((UICollectionViewCell *)self);
}

%end