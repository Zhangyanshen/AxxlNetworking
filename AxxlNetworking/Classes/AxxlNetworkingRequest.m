//
//  AxxlNetworkingRequest.m
//  AxxlNetworking
//
//  Created by 张延深 on 2020/6/10.
//  Copyright © 2020 张延深. All rights reserved.
//

#import "AxxlNetworkingRequest.h"
#import "AxxlNetworkingAgent.h"

NSString *const AxxlRequestValidationErrorDomain = @"com.aixuexi.request.validation";

@interface AxxlNetworkingRequest ()

@end

@implementation AxxlNetworkingRequest

+ (instancetype)requestWithURL:(NSString * __nullable)URL params:(id __nullable)params method:(AxxlRequestMethod)method {
    return [[self alloc] initWithURL:URL params:params method:method];
}

- (instancetype)initWithURL:(NSString * __nullable)URL params:(id __nullable)params method:(AxxlRequestMethod)method {
    AxxlNetworkingRequest *request = [[AxxlNetworkingRequest alloc] initWithURL:URL params:params];
    request.requestMethod = method;
    return request;
}

+ (instancetype)requestWithURL:(NSString *)URL params:(id)params {
    return [[self alloc] initWithURL:URL params:params];
}

- (instancetype)initWithURL:(NSString *)URL params:(id)params {
    if (self = [self init]) {
        _requestURL = URL;
        _params = params;
    }
    return self;
}

- (instancetype)init {
    if (self = [super init]) {
        _requestURL = @"";
        _requestMethod = AxxlRequestMethodGET;
        _requestSerializerType = AxxlRequestSerializerTypeHTTP;
        _responseSerializerType = AxxlResponseSerializerTypeJSON;
        _requestTimeoutInterval = 60;
    }
    return self;
}

#pragma mark - Setters/Getters

- (NSHTTPURLResponse *)response {
    return (NSHTTPURLResponse *)self.requestTask.response;
}

- (NSInteger)responseStatusCode {
    return self.response.statusCode;
}

- (BOOL)isCancelled {
    if (!self.requestTask) {
        return NO;
    }
    return self.requestTask.state == NSURLSessionTaskStateCanceling;
}

- (BOOL)isExecuting {
    if (!self.requestTask) {
        return NO;
    }
    return self.requestTask.state == NSURLSessionTaskStateRunning;
}

#pragma mark - Public methods

- (void)start {
    [[AxxlNetworkingAgent sharedAgent] startRequest:self];
}

- (void)startWithSuccess:(AxxlRequestCompletionBlock)success
                 failure:(AxxlRequestCompletionBlock)failure
{
    [self setCompletionBlockWithSuccess:success failure:failure];
    [self start];
}

- (void)startWithConstructingBlock:(nullable AxxlConstructingBlock)constructingBlock
               uploadProgressBlock:(nullable AxxlURLSessionTaskProgressBlock)uploadProgressBlock
                           success:(nullable AxxlRequestCompletionBlock)success
                           failure:(nullable AxxlRequestCompletionBlock)failure
{
    self.constructingBodyBlock = constructingBlock;
    self.uploadProgressBlock = uploadProgressBlock;
    [self startWithSuccess:success failure:failure];
}

- (void)startWithDownloadPath:(NSString *)downloadPath
        downloadProgressBlock:(nullable AxxlURLSessionTaskProgressBlock)downloadProgressBlock
                      success:(nullable AxxlRequestCompletionBlock)success
                      failure:(nullable AxxlRequestCompletionBlock)failure
{
    self.resumableDownloadPath = downloadPath;
    self.resumableDownloadProgressBlock = downloadProgressBlock;
    [self startWithSuccess:success failure:failure];
}

- (void)stop {
    [[AxxlNetworkingAgent sharedAgent] cancelRequest:self];
}

- (void)setCompletionBlockWithSuccess:(AxxlRequestCompletionBlock)success failure:(AxxlRequestCompletionBlock)failure {
    self.successCompletionBlock = success;
    self.failureCompletionBlock = failure;
}

- (void)clearCompletionBlock {
    // nil out to break the retain cycle.
    self.successCompletionBlock = nil;
    self.failureCompletionBlock = nil;
    self.uploadProgressBlock = nil;
}

#pragma mark - dealloc

- (void)dealloc {
    NSLog(@"%@释放了！", self);
}

@end
