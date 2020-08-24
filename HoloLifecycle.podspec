#
# Be sure to run `pod lib lint HoloLifecycle.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'HoloLifecycle'
  s.version          = '2.1.0'
  s.summary          = '组件化分发生命周期工具类'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = '所有继承 HoloBaseLifecycle 的子类都能够拥有执行 UIApplicationDelegate 生命周期方法的能力。或者，任意类在 load 方法内使用 HoloLifecycleManager 方法进行注册，遵循 HoloLifecycleProtocol 协议指定优先级 也可拥有执行 UIApplicationDelegate 生命周期方法的能力。'

  s.homepage         = 'https://github.com/HoloFoundation/HoloLifecycle'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'gonghonglou' => 'gonghonglou@icloud.com' }
  s.source           = { :git => 'https://github.com/HoloFoundation/HoloLifecycle.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '8.0'

  s.source_files = 'HoloLifecycle/Classes/**/*'
  
  # s.resource_bundles = {
  #   'HoloLifecycle' => ['HoloLifecycle/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
  
  s.dependency 'Aspects'
  s.vendored_libraries = 'HoloLifecycle/Classes/libffi/libffi.a'
  
end
