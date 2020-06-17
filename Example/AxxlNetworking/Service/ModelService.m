//
//  ModelService.m
//  AxxlNetworking
//
//  Created by 张延深 on 2020/6/9.
//  Copyright © 2020 张延深. All rights reserved.
//

#import "ModelService.h"

@implementation ModelService

+ (void)getModelListWithURL:(NSString *)URL
                     params:(NSDictionary *)params
                    success:(AxxlRequestCompletionBlock)success
                    failure:(AxxlRequestCompletionBlock)failure
{
    AxxlNetworkingRequest *request = [AxxlNetworkingRequest requestWithURL:URL params:params method:AxxlRequestMethodGET];
//    request.requestTimeoutInterval = 0.1f;
    [request startWithSuccess:^(AxxlNetworkingRequest * _Nonnull request) {
        if (success) {
            success(request);
        }
    } failure:^(AxxlNetworkingRequest * _Nonnull request) {
        if (failure) {
            failure(request);
        }
    }];
}

@end
