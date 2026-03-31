#import <UIKit/UIKit.h>

%hook UILabel

// 拦截普通文本设置
- (void)setText:(NSString *)text {
    // 检查是否为“闪照(数字)”格式
    if ([text hasPrefix:@"闪照("] && [text hasSuffix:@")"]) {
        // 查找当前 label 是否位于 PrivateChatViewController 的视图层级中
        UIResponder *responder = self;
        while (responder) {
            if ([responder isKindOfClass:NSClassFromString(@"PrivateChatViewController")]) {
                // 修改文本为固定值 5
                text = @"闪照(5)";
                break;
            }
            responder = [responder nextResponder];
        }
    }
    %orig(text);
}

// 拦截富文本设置（如果闪照文本通过 NSAttributedString 显示）
- (void)setAttributedText:(NSAttributedString *)attributedText {
    NSString *text = attributedText.string;
    if ([text hasPrefix:@"闪照("] && [text hasSuffix:@")"]) {
        UIResponder *responder = self;
        while (responder) {
            if ([responder isKindOfClass:NSClassFromString(@"PrivateChatViewController")]) {
                // 替换数字部分为“5”
                NSMutableAttributedString *newAttr = [attributedText mutableCopy];
                NSRange numberRange = NSMakeRange(3, text.length - 4);
                [newAttr replaceCharactersInRange:numberRange withString:@"5"];
                attributedText = newAttr;
                break;
            }
            responder = [responder nextResponder];
        }
    }
    %orig(attributedText);
}

%end

%hook BDBurnAfterReadManager

// 剩余闪照次数
- (long long)flash_left_times {
    return 5;
}

// 免费次数
- (long long)free_times {
    return 5;
}

// 功能开关
- (bool)is_enable {
    return YES;
}

%end

// 可选：绕过发送时的次数检查
%hook NewKeyBoardPhotoView

// 判断是否可以发送销毁图片/视频（闪照）
- (bool)canSendDestroyVidoeOrPic:(bool)arg1 {
    return YES;
}

%end