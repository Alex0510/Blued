#import <Foundation/Foundation.h>

// 自定义 URL 协议
@interface AdBlockerURLProtocol : NSURLProtocol
@end

@implementation AdBlockerURLProtocol

// 判断是否拦截请求
+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    // 避免重复处理
    if ([self propertyForKey:@"AdBlockerHandled" inRequest:request]) {
        return NO;
    }
    
    NSString *urlString = request.URL.absoluteString;
    // 正则匹配：https://.*/users?column=3&extra_info=.*
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
    [AdBlockerURLProtocol setProperty:@YES forKey:@"AdBlockerHandled" inRequest:newRequest];
    
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
                // 移除指定字段
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
        
        [self.client URLProtocol:self didReceiveResponse:newResponse cacheStoragePolicy:NSURLCacheStorageNotAllowed];
        [self.client URLProtocol:self didLoadData:data];
        [self.client URLProtocolDidFinishLoading:self];
    }];
    
    [task resume];
}

- (void)stopLoading {
    // 可选：取消任务
}

@end

// 插件加载时注册协议
%ctor {
    [NSURLProtocol registerClass:[AdBlockerURLProtocol class]];
}