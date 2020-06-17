//
//  AxxlNetworkingConfig.m
//  AxxlNetworking
//
//  Created by 张延深 on 2020/6/9.
//  Copyright © 2020 张延深. All rights reserved.
//

#import "AxxlNetworkingConfig.h"
#import <AFNetworking/AFSecurityPolicy.h>

@implementation AxxlNetworkingConfig

+ (instancetype)sharedConfig {
    static AxxlNetworkingConfig *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    if (self = [super init]) {
        _baseURL = @"";
        _securityPolicy = [AFSecurityPolicy defaultPolicy];
        _debugLogEnabled = NO;
        _sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    }
    return self;
}

@end
