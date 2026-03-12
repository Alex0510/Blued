#import <Foundation/Foundation.h>
#import <zlib.h>
#import <objc/runtime.h>

// 保存原始方法实现
static id (*orig_dataTaskWithRequest_completion)(id, SEL, NSURLRequest *, id);

// 数据处理函数（与之前相同）
NSData *processResponseData(NSData *data, NSURLResponse *response) {
    // 处理 gzip 解压
    NSData *uncompressedData = data;
    if (data.length >= 2) {
        const uint8_t *bytes = (const uint8_t *)data.bytes;
        if (bytes[0] == 0x1F && bytes[1] == 0x8B) {
            NSLog(@"[AdBlocker] Data is gzip compressed, decompressing...");
            // 解压函数（见下方）
            uncompressedData = gzipInflate(data);
            if (!uncompressedData) {
                NSLog(@"[AdBlocker] Decompression failed, using original.");
                uncompressedData = data;
            }
        }
    }
    
    // 解析 JSON 并移除广告字段
    NSError *jsonError = nil;
    id jsonObj = [NSJSONSerialization JSONObjectWithData:uncompressedData options:0 error:&jsonError];
    if (!jsonError && [jsonObj isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary *modifiedJson = [jsonObj mutableCopy];
        NSMutableDictionary *extra = [modifiedJson[@"extra"] mutableCopy];
        if (extra) {
            BOOL modified = NO;
            if (extra[@"adms_operating"]) { [extra removeObjectForKey:@"adms_operating"]; modified = YES; }
            if (extra[@"nearby_dating"])   { [extra removeObjectForKey:@"nearby_dating"];   modified = YES; }
            if (extra[@"adms_user"])       { [extra removeObjectForKey:@"adms_user"];       modified = YES; }
            if (extra[@"adms_activity"])   { [extra removeObjectForKey:@"adms_activity"];   modified = YES; }
            
            if (modified) {
                modifiedJson[@"extra"] = extra;
                NSData *newData = [NSJSONSerialization dataWithJSONObject:modifiedJson options:0 error:&jsonError];
                if (!jsonError) {
                    uncompressedData = newData;
                    NSLog(@"[AdBlocker] Successfully removed ad fields.");
                }
            }
        }
    } else {
        NSLog(@"[AdBlocker] JSON parse error: %@", jsonError);
    }
    return uncompressedData;
}

// gzip 解压函数（与之前相同，改为 C 函数）
NSData *gzipInflate(NSData *data) {
    if (data.length == 0) return nil;
    z_stream stream;
    stream.zalloc = Z_NULL;
    stream.zfree = Z_NULL;
    stream.opaque = Z_NULL;
    stream.avail_in = (uInt)data.length;
    stream.next_in = (Bytef *)data.bytes;
    
    if (inflateInit2(&stream, 16 + MAX_WBITS) != Z_OK) return nil;
    
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

// Hook 函数
id hooked_dataTaskWithRequest_completion(id self, SEL _cmd, NSURLRequest *request, id completionHandler) {
    NSString *urlString = request.URL.absoluteString;
    // 检查 URL 是否匹配
    if ([urlString containsString:@"/users?"] && [urlString containsString:@"column=3"]) {
        NSLog(@"[AdBlocker] Intercepting request: %@", urlString);
        
        // 包装原始的 completionHandler
        id newCompletionHandler = ^(NSData *data, NSURLResponse *response, NSError *error) {
            if (error) {
                NSLog(@"[AdBlocker] Request error: %@", error);
                ((void (^)(NSData *, NSURLResponse *, NSError *))completionHandler)(data, response, error);
                return;
            }
            
            // 处理响应数据
            NSData *modifiedData = processResponseData(data, response);
            
            // 由于修改了数据长度，需要移除 Content-Length 头（可选，但建议）
            if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
                NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                NSMutableDictionary *headers = [httpResponse.allHeaderFields mutableCopy];
                [headers removeObjectForKey:@"Content-Length"];
                NSHTTPURLResponse *newResponse = [[NSHTTPURLResponse alloc] initWithURL:httpResponse.URL
                                                                              statusCode:httpResponse.statusCode
                                                                             HTTPVersion:nil
                                                                            headerFields:headers];
                response = newResponse;
            }
            
            ((void (^)(NSData *, NSURLResponse *, NSError *))completionHandler)(modifiedData, response, error);
        };
        
        // 调用原始方法，传入包装后的 handler
        return orig_dataTaskWithRequest_completion(self, _cmd, request, newCompletionHandler);
    } else {
        // 不匹配的请求直接走原流程
        return orig_dataTaskWithRequest_completion(self, _cmd, request, completionHandler);
    }
}

// 构造函数
%ctor {
    @autoreleasepool {
        Class cls = objc_getClass("NSURLSession");
        if (!cls) {
            NSLog(@"[AdBlocker] Failed to get NSURLSession class");
            return;
        }
        Method m = class_getInstanceMethod(cls, @selector(dataTaskWithRequest:completionHandler:));
        if (!m) {
            NSLog(@"[AdBlocker] Failed to get method");
            return;
        }
        orig_dataTaskWithRequest_completion = (void *)method_getImplementation(m);
        method_setImplementation(m, (IMP)hooked_dataTaskWithRequest_completion);
        NSLog(@"[AdBlocker] Hook installed successfully");
    }
}