//
//  AxxlNetworkingAgent.h
//  AxxlNetworking
//
//  Created by 张延深 on 2020/6/9.
//  Copyright © 2020 张延深. All rights reserved.
//  发送请求的类

#import <Foundation/Foundation.h>
#import "AxxlNetworkingRequest.h"

NS_ASSUME_NONNULL_BEGIN

@interface AxxlNetworkingAgent : NSObject

/// 单例
+ (instancetype)sharedAgent;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

#pragma mark - 网络请求遍历方法

/// 发送请求
/// @param request 请求
- (void)startRequest:(AxxlNetworkingRequest *)request;

/// 取消请求
/// @param request 请求
- (void)cancelRequest:(AxxlNetworkingRequest *)request;

/// 取消所有请求
- (void)cancelAllRequests;

@end

NS_ASSUME_NONNULL_END
