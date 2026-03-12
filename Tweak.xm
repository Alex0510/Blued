// Tweak.x
#import <Foundation/Foundation.h>

@interface AdBlockerURLProtocol : NSURLProtocol
@end

@implementation AdBlockerURLProtocol

// 判断是否拦截该请求
+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    // 防止重复处理
    if ([self propertyForKey:@"AdBlockerHandled" inRequest:request] != nil) {
        return NO;
    }
    
    NSString *urlString = request.URL.absoluteString;
    // 正则：https://.*/users?column=3&extra_info=.*
    NSString *pattern = @"^https://.*/users\\?column=3&extra_info=.*";
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                                           options:0
                                                                             error:&error];
    if (error) return NO;
    
    NSRange range = [regex rangeOfFirstMatchInString:urlString
                                             options:0
                                               range:NSMakeRange(0, urlString.length)];
    return range.location != NSNotFound;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    return request;
}

- (void)startLoading {
    NSMutableURLRequest *newRequest = [self.request mutableCopy];
    // 标记已处理，避免循环
    [AdBlockerURLProtocol setProperty:@YES forKey:@"AdBlockerHandled" inRequest:newRequest];
    
    // 使用 NSURLSession 发起实际请求
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:newRequest
                                            completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            [self.client URLProtocol:self didFailWithError:error];
            return;
        }
        
        // 尝试解析 JSON
        NSError *jsonError = nil;
        id jsonObj = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
        if (!jsonError && [jsonObj isKindOfClass:[NSDictionary class]]) {
            NSMutableDictionary *modifiedJson = [jsonObj mutableCopy];
            NSMutableDictionary *extra = [modifiedJson[@"extra"] mutableCopy];
            if (extra) {
                // 移除目标字段
                [extra removeObjectForKey:@"adms_operating"];
                [extra removeObjectForKey:@"nearby_dating"];
                [extra removeObjectForKey:@"adms_user"];
                [extra removeObjectForKey:@"adms_activity"];
                modifiedJson[@"extra"] = extra;
                
                // 重新序列化
                NSData *newData = [NSJSONSerialization dataWithJSONObject:modifiedJson
                                                                   options:0
                                                                     error:&jsonError];
                if (!jsonError) {
                    data = newData;
                }
            }
        }
        
        // 移除 Content-Length 头，因为数据长度已变
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        NSMutableDictionary *headers = [httpResponse.allHeaderFields mutableCopy];
        [headers removeObjectForKey:@"Content-Length"];
        NSHTTPURLResponse *newResponse = [[NSHTTPURLResponse alloc] initWithURL:httpResponse.URL
                                                                      statusCode:httpResponse.statusCode
                                                                     HTTPVersion:nil
                                                                    headerFields:headers];
        
        // 将修改后的响应传递给客户端
        [self.client URLProtocol:self didReceiveResponse:newResponse cacheStoragePolicy:NSURLCacheStorageNotAllowed];
        [self.client URLProtocol:self didLoadData:data];
        [self.client URLProtocolDidFinishLoading:self];
    }];
    
    [task resume];
}

- (void)stopLoading {
    // 如果需要，可以取消任务
}

@end

// 构造函数：在插件加载时注册自定义协议
%ctor {
    [NSURLProtocol registerClass:[AdBlockerURLProtocol class]];
}