#
# Be sure to run `pod lib lint AxxlNetworking.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'AxxlNetworking'
  s.version          = '0.1.0'
  s.summary          = '爱学习在线网络库'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
爱学习在线网络库，基于AFNetworking封装，新增一些便利功能
                       DESC

  s.homepage         = 'https://gitee.com/stephencurry30/AxxlNetworking'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { '张延深' => 'zhangyanshen@aixuexi.com' }
  s.source           = { :git => 'https://gitee.com/stephencurry30/AxxlNetworking', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '9.0'

  s.source_files = 'AxxlNetworking/Classes/**/*'
  
  # s.resource_bundles = {
  #   'AxxlNetworking' => ['AxxlNetworking/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  s.dependency 'AFNetworking', '~> 4.0'
end
