//
//  AxxlNetworkingConfig.h
//  AxxlNetworking
//
//  Created by 张延深 on 2020/6/9.
//  Copyright © 2020 张延深. All rights reserved.
//  网络请求通用配置类

#import <Foundation/Foundation.h>

@class AFSecurityPolicy;

NS_ASSUME_NONNULL_BEGIN

@interface AxxlNetworkingConfig : NSObject

/// 单例
+ (instancetype)sharedConfig;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

/// 请求baseURL
@property (nonatomic, copy) NSString *baseURL;

/// 安全策略（AFSecurityPolicy）
@property (nonatomic, strong) AFSecurityPolicy *securityPolicy;

/// task session config
@property (nonatomic, strong) NSURLSessionConfiguration *sessionConfiguration;

/// 通用的请求头信息，默认为nil
@property (nonatomic, copy) NSDictionary<NSString *, NSString *> *requestHeaderFieldValueDictionary;

/// 系统级参数，所有接口都需要的参数，默认为nil
@property (nonatomic, strong) NSDictionary *systemParams;

/// 是否打印日志（默认NO）
@property (nonatomic, assign) BOOL debugLogEnabled;

@end

NS_ASSUME_NONNULL_END
