//
//  AXXLViewController.m
//  AxxlNetworking
//
//  Created by 张延深 on 06/15/2020.
//  Copyright (c) 2020 张延深. All rights reserved.
//

#import "AXXLViewController.h"
#import "ModelService.h"
#import "IdiomService.h"
#import <AxxlNetworking/AxxlNetworking.h>

@interface AXXLViewController () <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSArray *dataArr;
@property (nonatomic, assign) BOOL sendingRequest;

@end

@implementation AXXLViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	AxxlNetworkingConfig *config = [AxxlNetworkingConfig sharedConfig];
    config.baseURL = @"http://route.showapi.com";
    config.sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    config.systemParams = @{
        @"showapi_appid": @"262914",
        @"showapi_sign": @"f7d1ccab38d34fdb9f1753cb1b7da44b"
    };
    config.debugLogEnabled = YES;
    self.dataArr = @[
        @{@"淘女郎模特查询(GET)": @"126-2"},
        @{@"每日壁纸(POST)": @"1287-1"},
        @{@"下载": @""},
        @{@"上传": @""}
    ];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataArr.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellId = @"cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId];
    }
    cell.textLabel.text = [self.dataArr[indexPath.row] allKeys][0];
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (self.sendingRequest) {
        return;
    }
    NSDictionary *dic = self.dataArr[indexPath.row];
    NSString *key = dic.allKeys[0];
    NSString *url = dic[key];
    if ([key isEqualToString:@"淘女郎模特查询"]) {
        self.sendingRequest = YES;
        NSDictionary *params = @{
            @"type": @"韩版"
        };
        [ModelService getModelListWithURL:url params:params success:^(AxxlNetworkingRequest * _Nonnull request) {
            self.sendingRequest = NO;
            NSLog(@"%@请求成功：%@", key, request.responseObject);
        } failure:^(AxxlNetworkingRequest * _Nonnull request) {
            self.sendingRequest = NO;
            NSLog(@"%@请求失败：%@", key, request.error);
        }];
    } else if ([key isEqualToString:@"每日壁纸"]) {
        self.sendingRequest = YES;
        [IdiomService getIdiomWithURL:url params:@{} success:^(AxxlNetworkingRequest * _Nonnull request) {
            self.sendingRequest = NO;
            NSLog(@"%@请求成功：%@", key, request.responseObject);
        } failure:^(AxxlNetworkingRequest * _Nonnull request) {
            self.sendingRequest = NO;
            NSLog(@"%@请求失败：%@", key, request.error);
        }];
    } else if ([key isEqualToString:@"下载"]) {
        UIViewController *downloadVC = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"DownloadViewController"];
        [self.navigationController pushViewController:downloadVC animated:YES];
    } else {
        UIViewController *downloadVC = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"UploadViewController"];
        [self.navigationController pushViewController:downloadVC animated:YES];
    }
}

@end
