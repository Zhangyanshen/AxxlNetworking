//
//  AxxlNetworkingRequest.h
//  AxxlNetworking
//
//  Created by 张延深 on 2020/6/10.
//  Copyright © 2020 张延深. All rights reserved.
//  请求的request

/**
 每个请求独有的配置项
 1.请求URL
 2.请求参数
 3.HTTP请求方式（GET、POST...）
 4.request序列化方式
 5.response序列化方式
 ...
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString *const AxxlRequestValidationErrorDomain;

NS_ENUM(NSInteger) {
    AxxlRequestValidationErrorInvalidStatusCode = -8,
};

@protocol AFMultipartFormData;

/// 构造POST请求的请求体
typedef void (^AxxlConstructingBlock)(id<AFMultipartFormData> formData);
/// 监听进度
typedef void (^AxxlURLSessionTaskProgressBlock)(NSProgress *progress);

@class AxxlNetworkingRequest;

/// 请求完成
typedef void(^AxxlRequestCompletionBlock)(AxxlNetworkingRequest *request);

/// HTTP请求方式
typedef NS_ENUM(NSInteger, AxxlRequestMethod) {
    AxxlRequestMethodGET = 0,
    AxxlRequestMethodPOST,
    AxxlRequestMethodHEAD,
    AxxlRequestMethodPUT,
    AxxlRequestMethodDELETE,
    AxxlRequestMethodPATCH,
};

/// Request序列化方式
typedef NS_ENUM(NSInteger, AxxlRequestSerializerType) {
    AxxlRequestSerializerTypeHTTP = 0,
    AxxlRequestSerializerTypeJSON,
};

/// Response序列化方式
typedef NS_ENUM(NSInteger, AxxlResponseSerializerType) {
    /// NSData type
    AxxlResponseSerializerTypeHTTP,
    /// JSON object type
    AxxlResponseSerializerTypeJSON,
    /// NSXMLParser type
    AxxlResponseSerializerTypeXMLParser,
};

/// 请求的优先级（iOS 8.0+）
typedef NS_ENUM(NSInteger, AxxlRequestPriority) {
    AxxlRequestPriorityLow = 0,
    AxxlRequestPriorityDefault,
    AxxlRequestPriorityHigh,
};

@interface AxxlNetworkingRequest : NSObject

#pragma mark - Request和Response信息

///=============================================================================
/// @name Request和Response信息
///=============================================================================

/// session task
@property (nonatomic, strong) NSURLSessionTask *requestTask;

/// Shortcut for `requestTask.response`.
@property (nonatomic, strong, readonly) NSHTTPURLResponse *response;

/// The response status code.
@property (nonatomic, readonly) NSInteger responseStatusCode;

/// 返回对象
@property (nonatomic, strong, nullable) id responseObject;

@property (nonatomic, strong) NSString *responseString;

@property (nonatomic, strong) NSData *responseData;

@property (nonatomic, strong) id responseJSONObject;

/// 序列化错误或请求错误，如果成功，则为nil
@property (nonatomic, strong, nullable) NSError *error;

/// task是否已被取消
@property (nonatomic, readonly, getter=isCancelled) BOOL cancelled;

/// task是否正在执行
@property (nonatomic, readonly, getter=isExecuting) BOOL executing;

#pragma mark - request配置项

///=============================================================================
/// @name request配置项
///=============================================================================

/// 请求的URL
@property (nonatomic, copy, nullable) NSString *requestURL;

/// 请求参数
@property (nonatomic, strong, nullable) id params;

/// HTTP请求方式
@property (nonatomic, assign) AxxlRequestMethod requestMethod;

/// 请求序列化方式
@property (nonatomic, assign) AxxlRequestSerializerType requestSerializerType;

/// 响应序列化方式
@property (nonatomic, assign) AxxlResponseSerializerType responseSerializerType;

/// 请求超时时间（默认60秒）
@property (nonatomic, assign) NSTimeInterval requestTimeoutInterval;

/// HTTP认证用的Username和Password，格式：@[@"Username", @"Password"]
@property (nonatomic, copy) NSArray<NSString *> *requestAuthorizationHeaderFieldArray;

/// 自定义的请求头信息
@property (nonatomic, copy) NSDictionary<NSString *, NSString *> *requestHeaderFieldValueDictionary;

/// 自定义的MIME
@property (nonatomic, copy, nullable) NSSet <NSString *> *acceptableContentTypes;

/// 成功的回调
@property (nonatomic, copy, nullable) AxxlRequestCompletionBlock successCompletionBlock;

/// 失败的回调
@property (nonatomic, copy, nullable) AxxlRequestCompletionBlock failureCompletionBlock;

/// 构造HTTP POST请求的body
@property (nonatomic, copy, nullable) AxxlConstructingBlock constructingBodyBlock;

/// 断点续传下载路径
@property (nonatomic, copy, nullable) NSString *resumableDownloadPath;

/// 下载进度回调
@property (nonatomic, copy, nullable) AxxlURLSessionTaskProgressBlock resumableDownloadProgressBlock;

/// 上传进度回调
@property (nonatomic, copy, nullable) AxxlURLSessionTaskProgressBlock uploadProgressBlock;

/// 请求优先级
@property (nonatomic, assign) AxxlRequestPriority priority;

#pragma mark - 方法

///=============================================================================
/// @name 初始化方法
///=============================================================================

+ (instancetype)requestWithURL:(NSString * __nullable)URL params:(id __nullable)params method:(AxxlRequestMethod)method;

- (instancetype)initWithURL:(NSString * __nullable)URL params:(id __nullable)params method:(AxxlRequestMethod)method;

+ (instancetype)requestWithURL:(NSString * __nullable)URL params:(id __nullable)params;

- (instancetype)initWithURL:(NSString * __nullable)URL params:(id __nullable)params;

///=============================================================================
/// @name 请求方法
///=============================================================================

/// 开始请求
- (void)start;

/// 开始请求
/// @param success 成功回调
/// @param failure 失败回调
- (void)startWithSuccess:(nullable AxxlRequestCompletionBlock)success
                 failure:(nullable AxxlRequestCompletionBlock)failure;

/// 开始请求（上传）
/// @param constructingBlock 构造HTTP POST请求的body
/// @param uploadProgressBlock 上传进度回调
/// @param success 成功回调
/// @param failure 失败回调
- (void)startWithConstructingBlock:(nullable AxxlConstructingBlock)constructingBlock
               uploadProgressBlock:(nullable AxxlURLSessionTaskProgressBlock)uploadProgressBlock
                           success:(nullable AxxlRequestCompletionBlock)success
                           failure:(nullable AxxlRequestCompletionBlock)failure;

/// 开始请求（下载）
/// @param downloadPath 下载路径
/// @param downloadProgressBlock 下载进度回调
/// @param success 成功回调
/// @param failure 失败回调
- (void)startWithDownloadPath:(NSString *)downloadPath
        downloadProgressBlock:(nullable AxxlURLSessionTaskProgressBlock)downloadProgressBlock
                      success:(nullable AxxlRequestCompletionBlock)success
                      failure:(nullable AxxlRequestCompletionBlock)failure;

/// 停止请求
- (void)stop;

/// 请求成功和失败的回调
/// @param success 成功的回调
/// @param failure 失败的回调
- (void)setCompletionBlockWithSuccess:(nullable AxxlRequestCompletionBlock)success
                              failure:(nullable AxxlRequestCompletionBlock)failure;

/// 清除block
- (void)clearCompletionBlock;

@end

NS_ASSUME_NONNULL_END
