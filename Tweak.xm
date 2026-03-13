#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <substrate.h>

static const void *kBDCollapsedKey = &kBDCollapsedKey;

#pragma mark - Utils

static inline BOOL BDAlreadyCollapsed(id obj) {
    id v = objc_getAssociatedObject(obj, kBDCollapsedKey);
    return [v boolValue];
}

static inline void BDMarkCollapsed(id obj) {
    objc_setAssociatedObject(obj, kBDCollapsedKey, @(YES), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

static void BDSafelyHideView(UIView *view) {
    if (!view) return;

    view.hidden = YES;
    view.alpha = 0.0;
    view.clipsToBounds = YES;
    view.userInteractionEnabled = NO;
}

static void BDCollapseKnownSubviews(id cell) {
    @try {
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
            id obj = [cell valueForKey:key];
            if ([obj isKindOfClass:[UIView class]]) {
                BDSafelyHideView((UIView *)obj);
            }
        }
    } @catch (__unused NSException *e) {}
}

static void BDCollapseCellLight(id selfObj) {
    if (!selfObj || ![selfObj isKindOfClass:[UICollectionViewCell class]]) return;

    UICollectionViewCell *cell = (UICollectionViewCell *)selfObj;

    if (BDAlreadyCollapsed(cell)) return;
    BDMarkCollapsed(cell);

    BDSafelyHideView(cell);
    if (cell.contentView) {
        BDSafelyHideView(cell.contentView);
    }

    BDCollapseKnownSubviews(cell);
}

#pragma mark - Hooked methods

static void (*orig_awakeFromNib)(id, SEL) = NULL;
static void replaced_awakeFromNib(id self, SEL _cmd) {
    if (orig_awakeFromNib) orig_awakeFromNib(self, _cmd);
    BDCollapseCellLight(self);
}

static void (*orig_prepareForReuse)(id, SEL) = NULL;
static void replaced_prepareForReuse(id self, SEL _cmd) {
    if (orig_prepareForReuse) orig_prepareForReuse(self, _cmd);

    objc_setAssociatedObject(self, kBDCollapsedKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    BDCollapseCellLight(self);
}

static void (*orig_didMoveToSuperview)(id, SEL) = NULL;
static void replaced_didMoveToSuperview(id self, SEL _cmd) {
    if (orig_didMoveToSuperview) orig_didMoveToSuperview(self, _cmd);
    BDCollapseCellLight(self);
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

static void BDHookIfExists(Class cls, SEL sel, IMP newImp, IMP *oldImp) {
    if (!cls || !sel || !newImp) return;
    Method m = class_getInstanceMethod(cls, sel);
    if (m) {
        MSHookMessageEx(cls, sel, newImp, oldImp);
    }
}

static void BDHookCellClass(NSString *name) {
    Class cls = objc_getClass(name.UTF8String);
    if (!cls) {
        NSLog(@"[BluedAd] class not found: %@", name);
        return;
    }

    NSLog(@"[BluedAd] hook class: %@", name);

    BDHookIfExists(cls, @selector(awakeFromNib), (IMP)replaced_awakeFromNib, (IMP *)&orig_awakeFromNib);
    BDHookIfExists(cls, @selector(prepareForReuse), (IMP)replaced_prepareForReuse, (IMP *)&orig_prepareForReuse);
    BDHookIfExists(cls, @selector(didMoveToSuperview), (IMP)replaced_didMoveToSuperview, (IMP *)&orig_didMoveToSuperview);
    BDHookIfExists(cls, @selector(sizeThatFits:), (IMP)replaced_sizeThatFits, (IMP *)&orig_sizeThatFits);
    BDHookIfExists(cls, @selector(systemLayoutSizeFittingSize:), (IMP)replaced_systemLayoutSizeFittingSize, (IMP *)&orig_systemLayoutSizeFittingSize);
    BDHookIfExists(cls, @selector(preferredLayoutAttributesFittingAttributes:), (IMP)replaced_preferredLayoutAttributesFittingAttributes, (IMP *)&orig_preferredLayoutAttributesFittingAttributes);
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
            BDHookCellClass(name);
        }
    }
}