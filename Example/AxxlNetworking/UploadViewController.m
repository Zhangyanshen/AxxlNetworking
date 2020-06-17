//
//  UploadViewController.m
//  AxxlNetworking_Example
//
//  Created by 张延深 on 2020/6/17.
//  Copyright © 2020 张延深. All rights reserved.
//

#import "UploadViewController.h"
#import <AFNetworking/AFNetworking.h>
#import <AxxlNetworking/AxxlNetworking.h>

@interface UploadViewController ()

@property (weak, nonatomic) IBOutlet UIProgressView *uploadProgressView;
@property (weak, nonatomic) IBOutlet UILabel *percentLbl;

@end

@implementation UploadViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (IBAction)uploadFile:(UIButton *)sender {
    sender.enabled = NO;
    AxxlNetworkingRequest *request = [[AxxlNetworkingRequest alloc] initWithURL:@"http://api.51gugu.com/action.aspx" params:@{
        @"service": @"gugu.link.file_upload",
        @"client_id": @"10001754",
        @"client_key": @"6c837e9e35bb4a62af45e04d2644e8c5",
        @"save_path": @"/test"
    } method:AxxlRequestMethodPOST];
    [request startWithConstructingBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        NSString *filePath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:@"1.dmg"];
        NSURL *fileUrl = [NSURL fileURLWithPath:filePath];
        [formData appendPartWithFileURL:fileUrl name:@"files" error:nil];
    } uploadProgressBlock:^(NSProgress * _Nonnull progress) {
        int64_t totalUnitCount = progress.totalUnitCount;
        int64_t completedUnitCount = progress.completedUnitCount;
        CGFloat percent = completedUnitCount * 1.0 / totalUnitCount;
        [self.uploadProgressView setProgress:percent];
        self.percentLbl.text = [NSString stringWithFormat:@"%ld%%", (long)(percent * 100)];
    } success:^(AxxlNetworkingRequest * _Nonnull request) {
        sender.enabled = YES;
        [self.uploadProgressView setProgress:1.0];
        self.percentLbl.text = @"100%";
        NSLog(@"上传成功");
    } failure:^(AxxlNetworkingRequest * _Nonnull request) {
        sender.enabled = YES;
        NSLog(@"上传失败：%@", request.error);
    }];
}

@end
