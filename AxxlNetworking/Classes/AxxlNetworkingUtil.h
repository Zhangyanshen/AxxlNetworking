//
//  AxxlNetworkingUtil.h
//  AxxlNetworking
//
//  Created by 张延深 on 2020/6/10.
//  Copyright © 2020 张延深. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AxxlNetworkingConfig.h"

@class AxxlNetworkingRequest;

NS_ASSUME_NONNULL_BEGIN

@interface AxxlNetworkingUtil : NSObject

/// 获取请求数据response的编码方式
+ (NSStringEncoding)stringEncodingWithRequest:(AxxlNetworkingRequest *)request;

/// 校验已经下载的数据
+ (BOOL)validateResumeData:(NSData *)data;

/// MD5
+ (NSString *)md5StringFromString:(NSString *)string;

@end

NS_ASSUME_NONNULL_END
