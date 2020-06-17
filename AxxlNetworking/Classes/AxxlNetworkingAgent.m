//
//  AxxlNetworkingAgent.m
//  AxxlNetworking
//
//  Created by 张延深 on 2020/6/9.
//  Copyright © 2020 张延深. All rights reserved.
//

#import "AxxlNetworkingAgent.h"
#import "AxxlNetworkingConfig.h"
#import "AxxlNetworkingUtil.h"
#if __has_include(<AFNetworking/AFHTTPSessionManager.h>)
#import <AFNetworking/AFHTTPSessionManager.h>
#else
#import "AFHTTPSessionManager.h"
#endif

#define Lock() [self.lock lock]
#define Unlock() [self.lock unlock]

#define AxxlNetworkIncompleteDownloadFolderName @"Incomplete"

void AxxlLog(NSString *format, ...) {
#ifdef DEBUG
    if (![AxxlNetworkingConfig sharedConfig].debugLogEnabled) {
        return;
    }
    va_list argptr;
    va_start(argptr, format);
    NSLogv(format, argptr);
    va_end(argptr);
#endif
}

@interface AxxlNetworkingAgent ()

@property (nonatomic, strong) AFHTTPSessionManager *sessionManager;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, AxxlNetworkingRequest *> *requestsRecord;
@property (nonatomic, strong) NSLock *lock;
@property (nonatomic, strong) AxxlNetworkingConfig *config;
//@property (nonatomic, strong) AFJSONResponseSerializer *jsonResponseSerializer;
//@property (nonatomic, strong) AFXMLParserResponseSerializer *xmlParserResponseSerialzier;

@property (nonatomic, strong) NSIndexSet *allStatusCodes;
@property (nonatomic, strong) dispatch_queue_t completionQueue;

@end

@implementation AxxlNetworkingAgent

#pragma mark - Life cycle

+ (instancetype)sharedAgent {
    static AxxlNetworkingAgent *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    if (self = [super init]) {
        _requestsRecord = [NSMutableDictionary dictionary];
        _lock = [[NSLock alloc] init];
        _config = [AxxlNetworkingConfig sharedConfig];
        _completionQueue = dispatch_queue_create("com.aixuexi.networkingagent.processing", DISPATCH_QUEUE_CONCURRENT);
        _allStatusCodes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(100, 500)];
        
        _sessionManager = [[AFHTTPSessionManager alloc] initWithSessionConfiguration:_config.sessionConfiguration];
        _sessionManager.securityPolicy = _config.securityPolicy;
        _sessionManager.responseSerializer = [AFHTTPResponseSerializer serializer];
        _sessionManager.completionQueue = _completionQueue;
    }
    return self;
}

#pragma mark - Private methods

- (NSString *)buildRequestURL:(NSString *)originalURL {
    NSParameterAssert(originalURL != nil);
    NSURL *temp = [NSURL URLWithString:originalURL];
    // 如果原来的URL是合法的URL，直接返回
    if (temp && temp.host && temp.scheme) {
        return originalURL;
    }
    // 拼接URL
    return [self.config.baseURL stringByAppendingPathComponent:originalURL];
}

- (NSDictionary *)buildRequestParams:(id __nullable)userParams {
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    if (self.config.systemParams) {
        [params addEntriesFromDictionary:self.config.systemParams];
    }
    if (userParams) {
        [params addEntriesFromDictionary:userParams];
    }
    return [params copy];
}

- (AFHTTPRequestSerializer *)requestSerializerForRequest:(AxxlNetworkingRequest *)request {
    AFHTTPRequestSerializer *requestSerializer = nil;
    if (request.requestSerializerType == AxxlRequestSerializerTypeHTTP) {
        requestSerializer = [AFHTTPRequestSerializer serializer];
    } else if (request.requestSerializerType == AxxlRequestSerializerTypeJSON) {
        requestSerializer = [AFJSONRequestSerializer serializer];
    }
    
    // 设置超时时间
    requestSerializer.timeoutInterval = [request requestTimeoutInterval];
    
    // If api needs server username and password
    NSArray<NSString *> *authorizationHeaderFieldArray = request.requestAuthorizationHeaderFieldArray;
    if (authorizationHeaderFieldArray != nil) {
        [requestSerializer setAuthorizationHeaderFieldWithUsername:authorizationHeaderFieldArray.firstObject
                                                          password:authorizationHeaderFieldArray.lastObject];
    }
    
    // 通用请求头信息
    if (self.config.requestHeaderFieldValueDictionary != nil) {
        for (NSString *httpHeaderField in self.config.requestHeaderFieldValueDictionary.allKeys) {
            NSString *value = self.config.requestHeaderFieldValueDictionary[httpHeaderField];
            [requestSerializer setValue:value forHTTPHeaderField:httpHeaderField];
        }
    }
    
    // 自定义请求头信息
    NSDictionary<NSString *, NSString *> *headerFieldValueDictionary = request.requestHeaderFieldValueDictionary;
    if (headerFieldValueDictionary != nil) {
        for (NSString *httpHeaderField in headerFieldValueDictionary.allKeys) {
            NSString *value = headerFieldValueDictionary[httpHeaderField];
            [requestSerializer setValue:value forHTTPHeaderField:httpHeaderField];
        }
    }
    
    self.sessionManager.requestSerializer = requestSerializer;
    
    return requestSerializer;
}

- (AFHTTPResponseSerializer *)responseSerializerForRequest:(AxxlNetworkingRequest *)request {
    AFHTTPResponseSerializer *responseSerializer = nil;
    switch (request.responseSerializerType) {
        case AxxlResponseSerializerTypeHTTP:
            responseSerializer = [AFHTTPResponseSerializer serializer];
            break;
        case AxxlResponseSerializerTypeJSON:
            responseSerializer = [AFJSONResponseSerializer serializer];
            break;
        case AxxlResponseSerializerTypeXMLParser:
            responseSerializer = [AFXMLParserResponseSerializer serializer];
            break;
    }
    // 设置MIME
    if (request.acceptableContentTypes) {
        responseSerializer.acceptableContentTypes = request.acceptableContentTypes;
    }
    // 设置状态码
    responseSerializer.acceptableStatusCodes = self.allStatusCodes;
    
    self.sessionManager.responseSerializer = responseSerializer;
    
    return responseSerializer;
}

- (NSURLSessionDataTask *)dataTaskWithHTTPMethod:(NSString *)method
                               requestSerializer:(AFHTTPRequestSerializer *)requestSerializer
                                       URLString:(NSString *)URLString
                                      parameters:(id)parameters
                                           error:(NSError * _Nullable __autoreleasing *)error
{
    return [self dataTaskWithHTTPMethod:method
                      requestSerializer:requestSerializer
                              URLString:URLString
                             parameters:parameters
                         uploadProgress:nil
              constructingBodyWithBlock:nil
                                  error:error];
}

- (NSURLSessionDataTask *)dataTaskWithHTTPMethod:(NSString *)method
                               requestSerializer:(AFHTTPRequestSerializer *)requestSerializer
                                       URLString:(NSString *)URLString
                                      parameters:(id)parameters
                                  uploadProgress:(AxxlURLSessionTaskProgressBlock)uploadProgressBlock
                       constructingBodyWithBlock:(nullable void (^)(id <AFMultipartFormData> formData))block
                                           error:(NSError * _Nullable __autoreleasing *)error
{
    NSMutableURLRequest *request = nil;

    if (block) {
        request = [requestSerializer multipartFormRequestWithMethod:method URLString:URLString parameters:parameters constructingBodyWithBlock:block error:error];
    } else {
        request = [requestSerializer requestWithMethod:method URLString:URLString parameters:parameters error:error];
    }

    __block NSURLSessionDataTask *dataTask = nil;
    dataTask = [self.sessionManager dataTaskWithRequest:request uploadProgress:^(NSProgress * _Nonnull uploadProgress) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (uploadProgressBlock) {
                uploadProgressBlock(uploadProgress);
            }
        });
    } downloadProgress:nil completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
        [self handleRequestResult:dataTask responseObject:responseObject error:error];
    }];

    return dataTask;
}

- (NSURLSessionDownloadTask *)downloadTaskWithDownloadPath:(NSString *)downloadPath
                                         requestSerializer:(AFHTTPRequestSerializer *)requestSerializer
                                                 URLString:(NSString *)URLString
                                                parameters:(id)parameters
                                                  progress:(nullable void (^)(NSProgress *downloadProgress))downloadProgressBlock
                                                     error:(NSError * _Nullable __autoreleasing *)error {
    // add parameters to URL;
    NSMutableURLRequest *urlRequest = [requestSerializer requestWithMethod:@"GET" URLString:URLString parameters:parameters error:error];

    NSString *downloadTargetPath;
    BOOL isDirectory;
    if(![[NSFileManager defaultManager] fileExistsAtPath:downloadPath isDirectory:&isDirectory]) {
        isDirectory = NO;
    }
    // 如果传进来的是个目录，则在目录后面追加文件名
    if (isDirectory) {
        NSString *fileName = [urlRequest.URL lastPathComponent];
        downloadTargetPath = [NSString pathWithComponents:@[downloadPath, fileName]];
    } else {
        downloadTargetPath = downloadPath;
    }

    // AFN use `moveItemAtURL` to move downloaded file to target path,
    // this method aborts the move attempt if a file already exist at the path.
    // So we remove the exist file before we start the download task.
    // https://github.com/AFNetworking/AFNetworking/issues/3775
    if ([[NSFileManager defaultManager] fileExistsAtPath:downloadTargetPath]) {
        [[NSFileManager defaultManager] removeItemAtPath:downloadTargetPath error:nil];
    }

    BOOL resumeSucceeded = NO;
    __block NSURLSessionDownloadTask *downloadTask = nil;
    NSURL *localUrl = [self incompleteDownloadTempPathForDownloadPath:downloadPath];
    if (localUrl != nil) {
        BOOL resumeDataFileExists = [[NSFileManager defaultManager] fileExistsAtPath:localUrl.path];
        NSData *data = [NSData dataWithContentsOfURL:localUrl];
        BOOL resumeDataIsValid = [AxxlNetworkingUtil validateResumeData:data];

        BOOL canBeResumed = resumeDataFileExists && resumeDataIsValid;
        // 支持断点续传
        if (canBeResumed) {
            @try {
                downloadTask = [self.sessionManager downloadTaskWithResumeData:data progress:^(NSProgress * _Nonnull downloadProgress) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (downloadProgressBlock) {
                            downloadProgressBlock(downloadProgress);
                        }
                    });
                } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
                    return [NSURL fileURLWithPath:downloadTargetPath isDirectory:NO];
                } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
                    [self handleRequestResult:downloadTask responseObject:filePath error:error];
                }];
                resumeSucceeded = YES;
            } @catch (NSException *exception) {
                AxxlLog(@"Resume download failed, reason = %@", exception.reason);
                resumeSucceeded = NO;
            }
        }
    }
    if (!resumeSucceeded) {
        downloadTask = [self.sessionManager downloadTaskWithRequest:urlRequest progress:^(NSProgress * _Nonnull downloadProgress) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (downloadProgressBlock) {
                    downloadProgressBlock(downloadProgress);
                }
            });
        } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
            return [NSURL fileURLWithPath:downloadTargetPath isDirectory:NO];
        } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
            [self handleRequestResult:downloadTask responseObject:filePath error:error];
        }];
    }
    return downloadTask;
}

- (void)handleRequestResult:(NSURLSessionTask *)task responseObject:(id)responseObject error:(NSError *)error {
    Lock();
    AxxlNetworkingRequest *request = self.requestsRecord[@(task.taskIdentifier)];
    Unlock();
    
    if (!request) {
        return;
    }
    
    // 返回数据序列化
    NSError * __autoreleasing serializationError = nil;
    NSError * __autoreleasing validationError = nil;
    
    NSError *requestError = nil;
    BOOL succeed = NO;
    
    request.responseObject = responseObject;
    if ([request.responseObject isKindOfClass:[NSData class]]) {
        request.responseData = responseObject;
        request.responseString = [[NSString alloc] initWithData:responseObject encoding:[AxxlNetworkingUtil stringEncodingWithRequest:request]];
        switch (request.responseSerializerType) {
            case AxxlResponseSerializerTypeHTTP:
                // 默认行为，不用处理
                break;
            case AxxlResponseSerializerTypeJSON:
                request.responseObject = [self.sessionManager.responseSerializer responseObjectForResponse:task.response
                                                                                                      data:request.responseData
                                                                                                     error:&serializationError];
                request.responseJSONObject = request.responseObject;
                break;
            case AxxlResponseSerializerTypeXMLParser:
                request.responseObject = [self.sessionManager.responseSerializer responseObjectForResponse:task.response
                                                                                                      data:request.responseData
                                                                                                     error:&serializationError];
                break;
        }
    }
    
    if (error) { // 请求出错
        succeed = NO;
        requestError = error;
    } else if (serializationError) { // 序列化出错
        succeed = NO;
        requestError = serializationError;
    } else {
        succeed = [self validateResult:request error:&validationError];
        requestError = validationError;
    }
    
    if (succeed) {
        [self requestDidSucceedWithRequest:request];
    } else {
        [self requestDidFailedWithRequest:request error:requestError];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self removeRequestFromRecord:request];
        [request clearCompletionBlock];
    });
}

- (void)requestDidSucceedWithRequest:(AxxlNetworkingRequest *)request {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (request.successCompletionBlock) {
            request.successCompletionBlock(request);
        }
    });
}

- (void)requestDidFailedWithRequest:(AxxlNetworkingRequest *)request error:(NSError *)error {
    request.error = error;
    AxxlLog(@"Request %@ failed, status code = %ld, error = %@",
            NSStringFromClass([request class]),
            (long)request.responseStatusCode,
            error.localizedDescription);
    
    // 保存未完成的下载数据
    NSData *incompleteDownloadData = error.userInfo[NSURLSessionDownloadTaskResumeData];
    NSURL *localUrl = nil;
    if (request.resumableDownloadPath) {
        localUrl = [self incompleteDownloadTempPathForDownloadPath:request.resumableDownloadPath];
    }
    if (incompleteDownloadData && localUrl != nil) {
        [incompleteDownloadData writeToURL:localUrl atomically:YES];
    }

    // Load response from file and clean up if download task failed.
    if ([request.responseObject isKindOfClass:[NSURL class]]) {
        NSURL *url = request.responseObject;
        if (url.isFileURL && [[NSFileManager defaultManager] fileExistsAtPath:url.path]) {
            request.responseData = [NSData dataWithContentsOfURL:url];
            request.responseString = [[NSString alloc] initWithData:request.responseData encoding:[AxxlNetworkingUtil stringEncodingWithRequest:request]];

            [[NSFileManager defaultManager] removeItemAtURL:url error:nil];
        }
        request.responseObject = nil;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (request.failureCompletionBlock) {
            request.failureCompletionBlock(request);
        }
    });
}

- (void)addRequestToRecord:(AxxlNetworkingRequest *)request {
    Lock();
    self.requestsRecord[@(request.requestTask.taskIdentifier)] = request;
    AxxlLog(@"Add request: %@", NSStringFromClass([request class]));
    Unlock();
}

- (void)removeRequestFromRecord:(AxxlNetworkingRequest *)request {
    Lock();
    [self.requestsRecord removeObjectForKey:@(request.requestTask.taskIdentifier)];
    AxxlLog(@"Request queue size = %zd", [self.requestsRecord count]);
    Unlock();
}

- (BOOL)validateResult:(AxxlNetworkingRequest *)request error:(NSError * _Nullable __autoreleasing *)error {
    NSInteger statusCode = request.responseStatusCode;
    if (statusCode >= 200 && statusCode <= 299) {
        return YES;
    }
    if (error) {
        *error = [NSError errorWithDomain:AxxlRequestValidationErrorDomain
                                     code:AxxlRequestValidationErrorInvalidStatusCode
                                 userInfo:@{NSLocalizedDescriptionKey: @"Invalid status code"}];
    }
    return NO;
}

- (NSURLSessionTask *)sessionTaskForRequest:(AxxlNetworkingRequest *)request error:(NSError * _Nullable __autoreleasing *)error {
    AxxlRequestMethod requestMethod = request.requestMethod;
    NSString *url = [self buildRequestURL:request.requestURL];
    NSDictionary *params = [self buildRequestParams:request.params];
    AFHTTPRequestSerializer *requestSerializer = [self requestSerializerForRequest:request];
    [self responseSerializerForRequest:request];
    AxxlConstructingBlock constructingBlock = request.constructingBodyBlock;
    AxxlURLSessionTaskProgressBlock uploadProgressBlock = request.uploadProgressBlock;
    switch (requestMethod) {
        case AxxlRequestMethodGET:
        {
            if (request.resumableDownloadPath) { // 下载
                return [self downloadTaskWithDownloadPath:request.resumableDownloadPath
                                        requestSerializer:requestSerializer
                                                URLString:url
                                               parameters:params
                                                 progress:request.resumableDownloadProgressBlock
                                                    error:error];
            } else { // 普通GET请求
                return [self dataTaskWithHTTPMethod:@"GET"
                                  requestSerializer:requestSerializer
                                          URLString:url
                                         parameters:params
                                              error:error];
            }
        }
        case AxxlRequestMethodPOST:
            return [self dataTaskWithHTTPMethod:@"POST"
                              requestSerializer:requestSerializer
                                      URLString:url
                                     parameters:params
                                 uploadProgress:uploadProgressBlock
                      constructingBodyWithBlock:constructingBlock
                                          error:error];
        case AxxlRequestMethodHEAD:
            return [self dataTaskWithHTTPMethod:@"HEAD"
                              requestSerializer:requestSerializer
                                      URLString:url
                                     parameters:params
                                          error:error];
        case AxxlRequestMethodPUT:
            return [self dataTaskWithHTTPMethod:@"PUT"
                              requestSerializer:requestSerializer
                                      URLString:url
                                     parameters:params
                                 uploadProgress:uploadProgressBlock
                      constructingBodyWithBlock:constructingBlock
                                          error:error];
        case AxxlRequestMethodDELETE:
            return [self dataTaskWithHTTPMethod:@"DELETE"
                              requestSerializer:requestSerializer
                                      URLString:url
                                     parameters:params
                                          error:error];
        case AxxlRequestMethodPATCH:
            return [self dataTaskWithHTTPMethod:@"PATCH"
                              requestSerializer:requestSerializer
                                      URLString:url
                                     parameters:params
                                          error:error];
    }
}

#pragma mark - Resumable Download

- (NSString *)incompleteDownloadTempCacheFolder {
    NSFileManager *fileManager = [NSFileManager new];
    static NSString *cacheFolder;

    if (!cacheFolder) {
        NSString *cacheDir = NSTemporaryDirectory();
        cacheFolder = [cacheDir stringByAppendingPathComponent:AxxlNetworkIncompleteDownloadFolderName];
    }

    NSError *error = nil;
    if(![fileManager createDirectoryAtPath:cacheFolder withIntermediateDirectories:YES attributes:nil error:&error]) {
        AxxlLog(@"Failed to create cache directory at %@", cacheFolder);
        cacheFolder = nil;
    }
    return cacheFolder;
}

- (NSURL *)incompleteDownloadTempPathForDownloadPath:(NSString *)downloadPath {
    NSString *tempPath = nil;
    NSString *md5URLString = [AxxlNetworkingUtil md5StringFromString:downloadPath];
    tempPath = [[self incompleteDownloadTempCacheFolder] stringByAppendingPathComponent:md5URLString];
    return tempPath == nil ? nil : [NSURL fileURLWithPath:tempPath];
}

#pragma mark - 网络请求便利方法

- (void)startRequest:(AxxlNetworkingRequest *)request
{
    NSParameterAssert(request != nil);
    // 如果请求正在执行，直接返回
    if (request.isExecuting) {
        return;
    }
    // 获取requestTask
    NSError * __autoreleasing requestSerializationError = nil;
    request.requestTask = [self sessionTaskForRequest:request error:&requestSerializationError];
    // 请求序列化失败
    if (requestSerializationError) {
        [self requestDidFailedWithRequest:request error:requestSerializationError];
        return;
    }
    
    NSAssert(request.requestTask != nil, @"requestTask should not be nil");
    
    // 设置task优先级（iOS 8.0+）
    if ([request.requestTask respondsToSelector:@selector(priority)]) {
        switch (request.priority) {
            case AxxlRequestPriorityHigh:
                request.requestTask.priority = NSURLSessionTaskPriorityHigh;
                break;
            case AxxlRequestPriorityLow:
                request.requestTask.priority = NSURLSessionTaskPriorityLow;
                break;
            default:
                request.requestTask.priority = NSURLSessionTaskPriorityDefault;
                break;
        }
    }
    // 记录request
    [self addRequestToRecord:request];
    // 启动request
    [request.requestTask resume];
}

- (void)cancelRequest:(AxxlNetworkingRequest *)request {
    NSParameterAssert(request != nil);
    
    if (request.resumableDownloadPath && [self incompleteDownloadTempPathForDownloadPath:request.resumableDownloadPath] != nil) {
        NSURLSessionDownloadTask *requestTask = (NSURLSessionDownloadTask *)request.requestTask;
        [requestTask cancelByProducingResumeData:^(NSData *resumeData) {
            NSURL *localUrl = [self incompleteDownloadTempPathForDownloadPath:request.resumableDownloadPath];
            [resumeData writeToURL:localUrl atomically:YES];
        }];
    } else {
        [request.requestTask cancel];
    }
    
    [self removeRequestFromRecord:request];
    [request clearCompletionBlock];
}

- (void)cancelAllRequests {
    Lock();
    NSArray *allKeys = [self.requestsRecord allKeys];
    Unlock();
    if (allKeys && allKeys.count > 0) {
        NSArray *copiedKeys = [allKeys copy];
        for (NSNumber *key in copiedKeys) {
            Lock();
            AxxlNetworkingRequest *request = self.requestsRecord[key];
            Unlock();
            // We are using non-recursive lock.
            // Do not lock `stop`, otherwise deadlock may occur.
            [self cancelRequest:request];
        }
    }
}

@end
