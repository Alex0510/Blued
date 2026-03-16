#import <Foundation/Foundation.h>

// 自定义 URLProtocol，拦截匹配的请求并记录响应到文件
@interface LoggingURLProtocol : NSURLProtocol <NSURLSessionDataDelegate>
@property (nonatomic, strong) NSURLSessionDataTask *dataTask;
@property (nonatomic, strong) NSMutableData *responseData;
@property (nonatomic, strong) NSURLResponse *receivedResponse;
@end

@implementation LoggingURLProtocol

// 判断是否拦截该请求
+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    if ([NSURLProtocol propertyForKey:@"LoggingURLProtocolHandled" inRequest:request]) {
        return NO;
    }
    
    NSString *urlString = request.URL.absoluteString;
    if (![urlString containsString:@"/users?"]) {
        return NO;
    }
    
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

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    return request;
}

- (void)startLoading {
    NSMutableURLRequest *newRequest = [self.request mutableCopy];
    [NSURLProtocol setProperty:@YES forKey:@"LoggingURLProtocolHandled" inRequest:newRequest];
    
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];
    self.dataTask = [session dataTaskWithRequest:newRequest];
    self.responseData = [NSMutableData data];
    [self.dataTask resume];
}

- (void)stopLoading {
    [self.dataTask cancel];
    self.dataTask = nil;
    self.responseData = nil;
}

#pragma mark - NSURLSessionDataDelegate

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
    self.receivedResponse = response;
    [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    [self.responseData appendData:data];
    [self.client URLProtocol:self didLoadData:data];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    if (error) {
        [self.client URLProtocol:self didFailWithError:error];
    } else {
        // 日志输出到控制台（可选）
        NSLog(@"[LoggingURLProtocol] Request URL: %@", task.originalRequest.URL.absoluteString);
        
        // 准备保存到文件
        NSData *data = [self.responseData copy];
        NSString *urlString = task.originalRequest.URL.absoluteString;
        
        // 异步写入文件，避免阻塞网络回调
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            [self saveResponseData:data forURL:urlString];
        });
        
        [self.client URLProtocolDidFinishLoading:self];
    }
    self.responseData = nil;
}

// 保存响应数据到文件
- (void)saveResponseData:(NSData *)data forURL:(NSString *)urlString {
    // 获取应用的 Documents 目录
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = paths.firstObject;
    
    // 在 Documents 下创建 Logs 文件夹
    NSString *logsDirectory = [documentsDirectory stringByAppendingPathComponent:@"Logs"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *dirError = nil;
    if (![fileManager fileExistsAtPath:logsDirectory]) {
        [fileManager createDirectoryAtPath:logsDirectory withIntermediateDirectories:YES attributes:nil error:&dirError];
        if (dirError) {
            NSLog(@"[LoggingURLProtocol] Failed to create Logs directory: %@", dirError);
            return;
        }
    }
    
    // 生成文件名：时间戳.txt
    NSTimeInterval timestamp = [[NSDate date] timeIntervalSince1970];
    NSString *fileName = [NSString stringWithFormat:@"%.0f.txt", timestamp * 1000]; // 毫秒级时间戳
    NSString *filePath = [logsDirectory stringByAppendingPathComponent:fileName];
    
    // 构造写入内容：URL + 响应正文
    NSString *urlLine = [NSString stringWithFormat:@"URL: %@\n\n", urlString];
    NSData *urlData = [urlLine dataUsingEncoding:NSUTF8StringEncoding];
    
    NSMutableData *outputData = [NSMutableData data];
    [outputData appendData:urlData];
    [outputData appendData:data];
    
    // 写入文件
    BOOL success = [outputData writeToFile:filePath atomically:YES];
    if (success) {
        NSLog(@"[LoggingURLProtocol] Response saved to file: %@", filePath);
    } else {
        NSLog(@"[LoggingURLProtocol] Failed to write response to file");
    }
}

@end

// 插件加载时注册自定义协议
%ctor {
    [NSURLProtocol registerClass:[LoggingURLProtocol class]];
    NSLog(@"[LoggingURLProtocol] Registered successfully.");
}