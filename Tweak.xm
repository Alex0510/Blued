#import <UIKit/UIKit.h>

// ========== 修改 UI 显示 ==========
%hook UILabel
- (void)setText:(NSString *)text {
    if ([text hasPrefix:@"闪照("] && [text hasSuffix:@")"]) {
        UIResponder *responder = self;
        while (responder) {
            if ([responder isKindOfClass:NSClassFromString(@"PrivateChatViewController")]) {
                text = @"闪照(5)";
                break;
            }
            responder = [responder nextResponder];
        }
    }
    %orig(text);
}
%end

// ========== 修改本地数据源 ==========
%hook BDBurnAfterReadManager
- (long long)flash_left_times { return 5; }
- (long long)free_times { return 5; }
- (bool)is_enable { return YES; }
- (void)updateFlashTimes:(long long)times { %orig(5); }
%end

// ========== 修改发送请求参数（示例） ==========
%hook BDFlashMessage  // 需要根据实际情况修改类名
- (NSDictionary *)buildRequestParams {
    NSMutableDictionary *params = [[%orig mutableCopy] autorelease];
    params[@"free_times"] = @(5);
    params[@"flash_left_times"] = @(5);
    // 如果服务端要求客户端上报真实剩余次数，可能需要移除这些字段
    // [params removeObjectForKey:@"free_times"];
    return params;
}
%end

// ========== 修改网络响应（示例：hook 一个常见的网络回调） ==========
%hook BDRequestManager
- (void)sendRequest:(id)request completion:(void (^)(id response, NSError *error))completion {
    void (^newCompletion)(id, NSError *) = ^(id response, NSError *error) {
        if ([response isKindOfClass:[NSDictionary class]]) {
            NSMutableDictionary *mutResponse = [response mutableCopy];
            // 判断是否为闪照相关接口（根据 URL 或响应中的字段）
            if ([mutResponse[@"data"] isKindOfClass:[NSArray class]]) {
                BOOL isFlashRelated = NO;
                for (id item in mutResponse[@"data"]) {
                    if ([item isKindOfClass:[NSDictionary class]] && 
                        (item[@"free_times"] != nil || item[@"flash_left_times"] != nil)) {
                        isFlashRelated = YES;
                        break;
                    }
                }
                if (isFlashRelated) {
                    NSMutableArray *newData = [mutResponse[@"data"] mutableCopy];
                    for (NSMutableDictionary *item in newData) {
                        if (item[@"free_times"]) item[@"free_times"] = @(5);
                        if (item[@"flash_left_times"]) item[@"flash_left_times"] = @(5);
                        if (item[@"flash_prompt"]) item[@"flash_prompt"] = @"(5)";
                    }
                    mutResponse[@"data"] = newData;
                    response = mutResponse;
                }
            }
        }
        completion(response, error);
    };
    %orig(request, newCompletion);
}
%end

// ========== 可选：绕过发送时的本地校验 ==========
%hook NewKeyBoardPhotoView
- (bool)canSendDestroyVidoeOrPic:(bool)arg1 {
    return YES;
}
%end