#import <UIKit/UIKit.h>

// 需要隐藏的 Cell 类名
static NSArray<NSString *> *targetCellClassNames = @[
    @"BDHealthServiceCollectionCell",
    @"BDMineServiceCollectionCell",
    @"BDAudioServiceCollectionViewCell",
    @"BDLiveServiceCollectionCell",
    @"BDOtherServiceCollectionCell"
];

// Hook UICollectionView 的 willDisplayCell 方法，在 Cell 即将显示时将其隐藏
%hook NSObject

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    %orig; // 先调用原始 delegate 方法
    
    for (NSString *className in targetCellClassNames) {
        if ([cell isKindOfClass:NSClassFromString(className)]) {
            cell.hidden = YES;          // 直接隐藏，不替换 Cell 类
            cell.userInteractionEnabled = NO;
            break;
        }
    }
}

// 同样处理 UITableView（如果需要）
- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    %orig;
    
    for (NSString *className in targetCellClassNames) {
        if ([cell isKindOfClass:NSClassFromString(className)]) {
            cell.hidden = YES;
            cell.userInteractionEnabled = NO;
            break;
        }
    }
}

%end