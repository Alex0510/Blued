#import <Foundation/Foundation.h>
#import <zlib.h>  // 必须导入以使用 gzip 解压

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
    // 正则：匹配任何包含 /users? 且带有 column=3 的请求
    NSString *pattern = @"^https?://[^/]+/users\\?.*column=3.*";
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                                           options:0
                                                                             error:&error];
    if (error) {
        NSLog(@"[AdBlocker] Regex error: %@", error);
        return NO;
    }
    
    NSRange range = [regex rangeOfFirstMatchInString:urlString
                                             options:0
                                               range:NSMakeRange(0, urlString.length)];
    BOOL matches = range.location != NSNotFound;
    if (matches) {
        NSLog(@"[AdBlocker] Intercepting: %@", urlString);
    }
    return matches;
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
            NSLog(@"[AdBlocker] Request failed: %@", error);
            [self.client URLProtocol:self didFailWithError:error];
            return;
        }
        
        // 处理可能的 gzip 压缩
        NSData *uncompressedData = data;
        if (data.length >= 2) {
            const uint8_t *bytes = (const uint8_t *)data.bytes;  // 显式转换
            if (bytes[0] == 0x1F && bytes[1] == 0x8B) {
                NSLog(@"[AdBlocker] Data is gzip compressed, attempting decompression...");
                uncompressedData = [AdBlockerURLProtocol gzipInflate:data];  // 使用类方法
                if (!uncompressedData) {
                    NSLog(@"[AdBlocker] Gzip decompression failed, using original data.");
                    uncompressedData = data;
                }
            }
        }
        
        // 尝试解析 JSON
        NSError *jsonError = nil;
        id jsonObj = [NSJSONSerialization JSONObjectWithData:uncompressedData options:0 error:&jsonError];
        if (!jsonError && [jsonObj isKindOfClass:[NSDictionary class]]) {
            NSMutableDictionary *modifiedJson = [jsonObj mutableCopy];
            NSMutableDictionary *extra = [modifiedJson[@"extra"] mutableCopy];
            if (extra) {
                BOOL modified = NO;
                if (extra[@"adms_operating"]) {
                    [extra removeObjectForKey:@"adms_operating"];
                    modified = YES;
                }
                if (extra[@"nearby_dating"]) {
                    [extra removeObjectForKey:@"nearby_dating"];
                    modified = YES;
                }
                if (extra[@"adms_user"]) {
                    [extra removeObjectForKey:@"adms_user"];
                    modified = YES;
                }
                if (extra[@"adms_activity"]) {
                    [extra removeObjectForKey:@"adms_activity"];
                    modified = YES;
                }
                
                if (modified) {
                    modifiedJson[@"extra"] = extra;
                    NSData *newData = [NSJSONSerialization dataWithJSONObject:modifiedJson
                                                                       options:0
                                                                         error:&jsonError];
                    if (!jsonError) {
                        uncompressedData = newData;
                        NSLog(@"[AdBlocker] Successfully removed ad fields.");
                    } else {
                        NSLog(@"[AdBlocker] Re-serialization failed: %@", jsonError);
                    }
                }
            }
        } else {
            NSLog(@"[AdBlocker] JSON parse error: %@", jsonError);
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
        [self.client URLProtocol:self didLoadData:uncompressedData];
        [self.client URLProtocolDidFinishLoading:self];
    }];
    
    [task resume];
}

- (void)stopLoading {
    // 可选：取消任务
}

// gzip 解压类方法
+ (NSData *)gzipInflate:(NSData *)data {
    if (data.length == 0) return nil;
    
    z_stream stream;
    stream.zalloc = Z_NULL;
    stream.zfree = Z_NULL;
    stream.opaque = Z_NULL;
    stream.avail_in = (uInt)data.length;
    stream.next_in = (Bytef *)data.bytes;
    
    // 初始化 inflate 以处理 gzip (16 + MAX_WBITS)
    if (inflateInit2(&stream, 16 + MAX_WBITS) != Z_OK) {
        return nil;
    }
    
    NSMutableData *result = [NSMutableData dataWithCapacity:data.length * 2];
    do {
        stream.avail_out = (uInt)data.length;
        stream.next_out = (Bytef *)malloc(data.length);
        int ret = inflate(&stream, Z_NO_FLUSH);
        if (ret != Z_OK && ret != Z_STREAM_END) {
            free(stream.next_out);
            inflateEnd(&stream);
            return nil;
        }
        [result appendBytes:stream.next_out length:stream.total_out - result.length];
        free(stream.next_out);
    } while (stream.avail_out == 0);
    
    inflateEnd(&stream);
    return result;
}

@end

// 插件加载时注册协议
%ctor {
    [NSURLProtocol registerClass:[AdBlockerURLProtocol class]];
    NSLog(@"[AdBlocker] Protocol registered.");
}