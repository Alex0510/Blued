#import <Foundation/Foundation.h>

// 自定义 URLProtocol，拦截匹配的请求并记录响应
@interface LoggingURLProtocol : NSURLProtocol <NSURLSessionDataDelegate>
@property (nonatomic, strong) NSURLSessionDataTask *dataTask;
@property (nonatomic, strong) NSMutableData *responseData;
@property (nonatomic, strong) NSURLResponse *receivedResponse;
@end

@implementation LoggingURLProtocol

// 判断是否拦截该请求
+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    // 避免重复处理已经标记过的请求
    if ([NSURLProtocol propertyForKey:@"LoggingURLProtocolHandled" inRequest:request]) {
        return NO;
    }
    
    // 提取 URL 字符串
    NSString *urlString = request.URL.absoluteString;
    
    // 快速过滤：必须包含 "/users?"
    if (![urlString containsString:@"/users?"]) {
        return NO;
    }
    
    // 解析查询参数，检查是否包含目标参数
    NSURLComponents *components = [NSURLComponents componentsWithURL:request.URL resolvingAgainstBaseURL:NO];
    for (NSURLQueryItem *item in components.queryItems) {
        if ([item.name isEqualToString:@"column"] ||
            [item.name isEqualToString:@"aaid"] ||
            [item.name isEqualToString:@"extra_info"]) {
            return YES;
        }
    }
    return NO;
}

// 返回规范化请求（通常直接返回原请求）
+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    return request;
}

// 开始加载请求
- (void)startLoading {
    // 复制请求并添加标记，防止循环
    NSMutableURLRequest *newRequest = [self.request mutableCopy];
    [NSURLProtocol setProperty:@YES forKey:@"LoggingURLProtocolHandled" inRequest:newRequest];
    
    // 创建 NSURLSession 来执行实际请求
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];
    self.dataTask = [session dataTaskWithRequest:newRequest];
    self.responseData = [NSMutableData data];
    [self.dataTask resume];
}

// 停止加载（取消任务）
- (void)stopLoading {
    [self.dataTask cancel];
    self.dataTask = nil;
    self.responseData = nil;
}

#pragma mark - NSURLSessionDataDelegate

// 收到响应头
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
    self.receivedResponse = response;
    // 通知客户端收到响应
    [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
    completionHandler(NSURLSessionResponseAllow);
}

// 收到数据块
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    [self.responseData appendData:data];
    [self.client URLProtocol:self didLoadData:data];
}

// 请求完成（或失败）
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    if (error) {
        [self.client URLProtocol:self didFailWithError:error];
    } else {
        // 输出日志
        NSLog(@"[LoggingURLProtocol] Request URL: %@", task.originalRequest.URL.absoluteString);
        
        // 尝试将响应数据转为字符串输出（假设为 UTF-8 编码）
        NSString *responseString = [[NSString alloc] initWithData:self.responseData encoding:NSUTF8StringEncoding];
        if (responseString) {
            NSLog(@"[LoggingURLProtocol] Response Body: %@", responseString);
        } else {
            NSLog(@"[LoggingURLProtocol] Response Data (length: %lu bytes)", (unsigned long)self.responseData.length);
        }
        
        [self.client URLProtocolDidFinishLoading:self];
    }
    self.responseData = nil;
}

@end

// 插件加载时注册自定义协议
%ctor {
    [NSURLProtocol registerClass:[LoggingURLProtocol class]];
    NSLog(@"[LoggingURLProtocol] Registered successfully.");
}