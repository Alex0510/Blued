#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <substrate.h>

#pragma mark - Utils

static inline void BDSetZeroFrame(UIView *view) {
    if (!view) return;
    CGRect f = view.frame;
    f.size.width = 0.01;
    f.size.height = 0.01;
    view.frame = f;
    view.bounds = CGRectMake(0, 0, 0.01, 0.01);
}

static void BDHideSubviewsRecursively(UIView *view) {
    if (!view) return;

    @try {
        view.hidden = YES;
        view.alpha = 0.0;
        view.clipsToBounds = YES;
        view.userInteractionEnabled = NO;
        BDSetZeroFrame(view);

        // 安全地修改约束
        @try {
            for (NSLayoutConstraint *c in view.constraints) {
                NSLayoutAttribute a = c.firstAttribute;
                if (a == NSLayoutAttributeWidth ||
                    a == NSLayoutAttributeHeight ||
                    a == NSLayoutAttributeTop ||
                    a == NSLayoutAttributeBottom ||
                    a == NSLayoutAttributeLeading ||
                    a == NSLayoutAttributeTrailing) {
                    c.constant = 0;
                }
            }
        } @catch (NSException *e) {
            NSLog(@"[BluedAd] Exception modifying constraints: %@", e);
        }

        for (UIView *sub in view.subviews) {
            BDHideSubviewsRecursively(sub);
        }
    } @catch (NSException *e) {
        NSLog(@"[BluedAd] Exception in BDHideSubviewsRecursively: %@", e);
    }
}

static void BDCollapseCell(id selfObj) {
    if (!selfObj || ![selfObj isKindOfClass:[UICollectionViewCell class]]) return;

    @try {
        UICollectionViewCell *cell = (UICollectionViewCell *)selfObj;
        cell.hidden = YES;
        cell.alpha = 0.0;
        cell.clipsToBounds = YES;
        cell.userInteractionEnabled = NO;
        BDSetZeroFrame(cell);

        if (cell.contentView) {
            BDHideSubviewsRecursively(cell.contentView);
            cell.contentView.hidden = YES;
            cell.contentView.alpha = 0.0;
            BDSetZeroFrame(cell.contentView);
        }

        @try {
            for (NSLayoutConstraint *c in cell.constraints) {
                NSLayoutAttribute a = c.firstAttribute;
                if (a == NSLayoutAttributeWidth || a == NSLayoutAttributeHeight) {
                    c.constant = 0;
                }
            }
        } @catch (NSException *e) {
            NSLog(@"[BluedAd] Exception modifying cell constraints: %@", e);
        }

        NSArray *keys = @[
            @"centerView",
            @"mainStackView",
            @"titleLabel",
            @"productListScrollView",
            @"marqueeView",
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
            @try {
                // 检查 getter 是否存在，避免 valueForKey: 抛出异常
                SEL getter = NSSelectorFromString(key);
                if ([cell respondsToSelector:getter]) {
                    id obj = [cell valueForKey:key];
                    if ([obj isKindOfClass:[UIView class]]) {
                        BDHideSubviewsRecursively((UIView *)obj);
                    }
                } else {
                    NSLog(@"[BluedAd] Warning: cell %@ does not respond to selector %@", NSStringFromClass([cell class]), key);
                }
            } @catch (NSException *e) {
                NSLog(@"[BluedAd] Exception accessing key %@: %@", key, e);
            }
        }
    } @catch (NSException *e) {
        NSLog(@"[BluedAd] Exception in BDCollapseCell: %@", e);
    }
}

#pragma mark - Hook impls

static void (*orig_awakeFromNib)(id, SEL) = NULL;
static void replaced_awakeFromNib(id self, SEL _cmd) {
    if (orig_awakeFromNib) orig_awakeFromNib(self, _cmd);
    BDCollapseCell(self);
}

static void (*orig_prepareForReuse)(id, SEL) = NULL;
static void replaced_prepareForReuse(id self, SEL _cmd) {
    if (orig_prepareForReuse) orig_prepareForReuse(self, _cmd);
    BDCollapseCell(self);
}

static CGSize (*orig_sizeThatFits)(id, SEL, CGSize) = NULL;
static CGSize replaced_sizeThatFits(id self, SEL _cmd, CGSize size) {
    return CGSizeMake(0.01, 0.01);
}

static CGSize (*orig_systemLayoutSizeFittingSize)(id, SEL, CGSize) = NULL;
static CGSize replaced_systemLayoutSizeFittingSize(id self, SEL _cmd, CGSize targetSize) {
    return CGSizeMake(0.01, 0.01);
}

static UICollectionViewLayoutAttributes *(*orig_preferredLayoutAttributesFittingAttributes)(id, SEL, UICollectionViewLayoutAttributes *) = NULL;
static UICollectionViewLayoutAttributes *replaced_preferredLayoutAttributesFittingAttributes(id self, SEL _cmd, UICollectionViewLayoutAttributes *attrs) {
    UICollectionViewLayoutAttributes *ret = attrs;
    if (orig_preferredLayoutAttributesFittingAttributes) {
        ret = orig_preferredLayoutAttributesFittingAttributes(self, _cmd, attrs);
    }
    if (ret) {
        CGRect f = ret.frame;
        f.size.width = 0.01;
        f.size.height = 0.01;
        ret.frame = f;
    }
    return ret;
}

#pragma mark - Runtime Hook

static void BDHookSelectorIfExists(Class cls, SEL sel, IMP newImp, IMP *oldImp, const char *types) {
    if (!cls || !sel || !newImp) return;

    Method m = class_getInstanceMethod(cls, sel);
    if (m) {
        MSHookMessageEx(cls, sel, newImp, oldImp);
    } else if (types) {
        class_addMethod(cls, sel, newImp, types);
    }
}

static void BDHookTargetClass(NSString *className) {
    Class cls = objc_getClass(className.UTF8String);
    if (!cls) {
        NSLog(@"[BluedAd] class not found: %@", className);
        return;
    }

    NSLog(@"[BluedAd] hooking class: %@", className);

    BDHookSelectorIfExists(cls, @selector(awakeFromNib), (IMP)replaced_awakeFromNib, (IMP *)&orig_awakeFromNib, "v@:");
    BDHookSelectorIfExists(cls, @selector(prepareForReuse), (IMP)replaced_prepareForReuse, (IMP *)&orig_prepareForReuse, "v@:");
    BDHookSelectorIfExists(cls, @selector(sizeThatFits:), (IMP)replaced_sizeThatFits, (IMP *)&orig_sizeThatFits, "{CGSize=dd}@:{CGSize=dd}");
    BDHookSelectorIfExists(cls, @selector(systemLayoutSizeFittingSize:), (IMP)replaced_systemLayoutSizeFittingSize, (IMP *)&orig_systemLayoutSizeFittingSize, "{CGSize=dd}@:{CGSize=dd}");
    BDHookSelectorIfExists(cls, @selector(preferredLayoutAttributesFittingAttributes:), (IMP)replaced_preferredLayoutAttributesFittingAttributes, (IMP *)&orig_preferredLayoutAttributesFittingAttributes, "@@:@");
}

__attribute__((constructor))
static void BDInit() {
    @autoreleasepool {
        NSArray *targets = @[
            @"BDAudioServiceCollectionViewCell",
            @"BDLiveServiceCollectionCell",
            @"BDOtherServiceCollectionCell",
            @"BDHealthServiceCollectionCell"
        ];

        for (NSString *name in targets) {
            BDHookTargetClass(name);
        }
    }
}