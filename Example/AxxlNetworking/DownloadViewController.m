//
//  DownloadViewController.m
//  AxxlNetworking_Example
//
//  Created by 张延深 on 2020/6/17.
//  Copyright © 2020 张延深. All rights reserved.
//

#import "DownloadViewController.h"
#import <AxxlNetworking/AxxlNetworking.h>

@interface DownloadViewController ()

@property (weak, nonatomic) IBOutlet UIProgressView *downloadProgressView;
@property (weak, nonatomic) IBOutlet UILabel *percentLbl;
@property (nonatomic, strong) AxxlNetworkingRequest *request;
@property (nonatomic, assign, getter=isPause) BOOL pause;

@end

@implementation DownloadViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.pause = YES;
}

#pragma mark - Setters/Getters

- (AxxlNetworkingRequest *)request {
    if (!_request) {
        _request = [[AxxlNetworkingRequest alloc] initWithURL:@"http://dldir1.qq.com/qqfile/QQforMac/QQ_V5.4.0.dmg" params:nil method:AxxlRequestMethodGET];
    }
    return _request;
}

#pragma mark - Event response

- (IBAction)startDownload:(UIButton *)sender {
    if (self.pause) {
        [sender setTitle:@"暂停" forState:UIControlStateNormal];
        __weak typeof(self) weakSelf = self;
        [self.request startWithDownloadPath:[self resumableDownloadPath] downloadProgressBlock:^(NSProgress * _Nonnull progress) {
            int64_t totalUnitCount = progress.totalUnitCount;
            int64_t completedUnitCount = progress.completedUnitCount;
            CGFloat percent = completedUnitCount * 1.0 / totalUnitCount;
            [weakSelf.downloadProgressView setProgress:percent];
            weakSelf.percentLbl.text = [NSString stringWithFormat:@"%ld%%", (long)(percent * 100)];
        } success:^(AxxlNetworkingRequest * _Nonnull request) {
            [self.downloadProgressView setProgress:1.0];
            self.percentLbl.text = @"100%";
            NSLog(@"下载成功：%@", request.responseObject);
            [sender setTitle:@"重新下载" forState:UIControlStateNormal];
            self.pause = YES;
        } failure:^(AxxlNetworkingRequest * _Nonnull request) {
            NSLog(@"下载失败：%@", request.error);
            [sender setTitle:@"重新下载" forState:UIControlStateNormal];
            self.pause = YES;
        }];
    } else {
        [self.request stop];
        [sender setTitle:@"开始" forState:UIControlStateNormal];
    }
    self.pause = !self.isPause;
}

#pragma mark - Private methods

- (NSString *)resumableDownloadPath {
    NSString *docPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    return [docPath stringByAppendingPathComponent:@"1.dmg"];
}

@end
