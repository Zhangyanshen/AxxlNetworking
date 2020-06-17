//
//  IdiomService.m
//  AxxlNetworking
//
//  Created by 张延深 on 2020/6/9.
//  Copyright © 2020 张延深. All rights reserved.
//

#import "IdiomService.h"

@implementation IdiomService

+ (void)getIdiomWithURL:(NSString *)URL params:(NSDictionary *)params success:(AxxlRequestCompletionBlock)success failure:(AxxlRequestCompletionBlock)failure {
    AxxlNetworkingRequest *request = [AxxlNetworkingRequest requestWithURL:URL params:params method:AxxlRequestMethodPOST];
    request.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/json", @"text/javascript",@"text/html", nil];
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
