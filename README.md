# AxxlNetworking

[![CI Status](https://img.shields.io/travis/张延深/AxxlNetworking.svg?style=flat)](https://travis-ci.org/张延深/AxxlNetworking)
[![Version](https://img.shields.io/cocoapods/v/AxxlNetworking.svg?style=flat)](https://cocoapods.org/pods/AxxlNetworking)
[![License](https://img.shields.io/cocoapods/l/AxxlNetworking.svg?style=flat)](https://cocoapods.org/pods/AxxlNetworking)
[![Platform](https://img.shields.io/cocoapods/p/AxxlNetworking.svg?style=flat)](https://cocoapods.org/pods/AxxlNetworking)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

iOS 9.0 +

## Installation

AxxlNetworking is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'AxxlNetworking'
```

## 结构

- `AxxlNetworkingConfig`
    * 通用配置类，可以配置域名、HTTPS认证方式、请求头以及通用参数等。

- `AxxlNetworkingRequest`
    * 网络请求类，使用该类发起网络请求，封装了请求的URL、参数、HTTP请求方式、序列化等。

- `AxxlNetworkingAgent`
    * 真正发送网络请求的类，封装了AFNetworking的常用方法。

- `AxxlNetworkingUtil`
    * 网络请求工具类，封装了网络请求需要的一些工具。

## 使用

#### GET请求

```objective-c
AxxlNetworkingRequest *request = [AxxlNetworkingRequest requestWithURL:URL params:params method:AxxlRequestMethodGET];
[request startWithSuccess:^(AxxlNetworkingRequest * _Nonnull request) {
    // 成功的回调
} failure:^(AxxlNetworkingRequest * _Nonnull request) {
    // 失败的回调
}];
```

#### POST请求

```objective-c
AxxlNetworkingRequest *request = [AxxlNetworkingRequest requestWithURL:URL params:params method:AxxlRequestMethodPOST];
[request startWithSuccess:^(AxxlNetworkingRequest * _Nonnull request) {
    // 成功的回调
} failure:^(AxxlNetworkingRequest * _Nonnull request) {
    // 失败的回调
}];
```

#### 下载

```objective-c
AxxlNetworkingRequest *request = [[AxxlNetworkingRequest alloc] initWithURL:@"http://dldir1.qq.com/qqfile/QQforMac/QQ_V5.4.0.dmg" params:nil method:AxxlRequestMethodGET];
[request startWithDownloadPath:downloadPath downloadProgressBlock:^(NSProgress * _Nonnull progress) {
    // 下载进度
} success:^(AxxlNetworkingRequest * _Nonnull request) {
    // 成功的回调
} failure:^(AxxlNetworkingRequest * _Nonnull request) {
    // 失败的回调
}];
```

#### 上传

```objective-c
AxxlNetworkingRequest *request = [[AxxlNetworkingRequest alloc] initWithURL:url params:params method:AxxlRequestMethodPOST];
[request startWithConstructingBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
    // 构造HTTP body
} uploadProgressBlock:^(NSProgress * _Nonnull progress) {
    // 上传进度
} success:^(AxxlNetworkingRequest * _Nonnull request) {
    // 成功的回调
} failure:^(AxxlNetworkingRequest * _Nonnull request) {
    // 失败的回调
}];
```

#### 通用配置

```objective-c
AxxlNetworkingConfig *config = [AxxlNetworkingConfig sharedConfig];
// 配置域名
config.baseURL = @"http://route.showapi.com";
// 配置NSURLSession Configuration
config.sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
// 配置HTTP请求头
config.requestHeaderFieldValueDictionary = @{};
// 配置所有接口都需要的参数
config.systemParams = @{
    @"showapi_appid": @"262914",
    @"showapi_sign": @"f7d1ccab38d34fdb9f1753cb1b7da44b"
};
// 是否开启log
config.debugLogEnabled = YES;
```

## Author

张延深, zhangyanshen@aixuexi.com

## License

AxxlNetworking is available under the MIT license. See the LICENSE file for more info.
