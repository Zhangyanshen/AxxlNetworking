//
//  ModelService.h
//  AxxlNetworking
//
//  Created by 张延深 on 2020/6/9.
//  Copyright © 2020 张延深. All rights reserved.
//  模特相关接口

#import <Foundation/Foundation.h>
#import "AxxlNetworking.h"

NS_ASSUME_NONNULL_BEGIN

@interface ModelService : NSObject

+ (void)getModelListWithURL:(NSString *)URL params:(NSDictionary *)params success:(AxxlRequestCompletionBlock)success failure:(AxxlRequestCompletionBlock)failure;

@end

NS_ASSUME_NONNULL_END
