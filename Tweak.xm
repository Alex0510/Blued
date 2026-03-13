#import <UIKit/UIKit.h>

// 需要隐藏的 Cell 类名列表
static NSArray<NSString *> *targetCellClassNames = @[
    @"BDHealthServiceCollectionCell",
    @"BDMineServiceCollectionCell",
    @"BDAudioServiceCollectionViewCell",
    @"BDLiveServiceCollectionCell",
    @"BDOtherServiceCollectionCell"
];

// 空 Cell 重用标识符
static NSString *const kEmptyCellIdentifier = @"__BDEmptyCollectionCell";

%hook UICollectionView

// 在设置数据源时，顺便注册空 Cell（确保每个 UICollectionView 都有空 Cell 可用）
- (void)setDataSource:(id<UICollectionViewDataSource>)dataSource {
    %orig;
    [self registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:kEmptyCellIdentifier];
}

// 在 reloadData 时也确保空 Cell 已注册（防止某些情况下未触发 setDataSource）
- (void)reloadData {
    [self registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:kEmptyCellIdentifier];
    %orig;
}

// 拦截 cellForItemAtIndexPath，将目标 Cell 替换为空 Cell
- (id)cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    // 先获取原始 cell（可能由数据源返回）
    id cell = %orig;
    
    for (NSString *className in targetCellClassNames) {
        if ([cell isKindOfClass:NSClassFromString(className)]) {
            // 返回一个空白的、隐藏的 Cell
            UICollectionViewCell *emptyCell = [self dequeueReusableCellWithReuseIdentifier:kEmptyCellIdentifier forIndexPath:indexPath];
            emptyCell.hidden = YES;
            emptyCell.userInteractionEnabled = NO;
            return emptyCell;
        }
    }
    
    return cell;
}

%end

// 如果目标 Cell 可能出现在 UITableView 中，也可类似处理
%hook UITableView

- (void)setDataSource:(id<UITableViewDataSource>)dataSource {
    %orig;
    static NSString *emptyID = @"__BDEmptyTableCell";
    [self registerClass:[UITableViewCell class] forCellReuseIdentifier:emptyID];
}

- (void)reloadData {
    static NSString *emptyID = @"__BDEmptyTableCell";
    [self registerClass:[UITableViewCell class] forCellReuseIdentifier:emptyID];
    %orig;
}

- (id)cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    id cell = %orig;
    
    for (NSString *className in targetCellClassNames) {
        if ([cell isKindOfClass:NSClassFromString(className)]) {
            static NSString *emptyID = @"__BDEmptyTableCell";
            UITableViewCell *emptyCell = [self dequeueReusableCellWithIdentifier:emptyID forIndexPath:indexPath];
            emptyCell.hidden = YES;
            emptyCell.userInteractionEnabled = NO;
            return emptyCell;
        }
    }
    
    return cell;
}

%end