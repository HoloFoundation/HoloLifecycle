# HoloLifecycle

[![CI Status](https://img.shields.io/travis/gonghonglou/HoloLifecycle.svg?style=flat)](https://travis-ci.org/gonghonglou/HoloLifecycle)
[![Version](https://img.shields.io/cocoapods/v/HoloLifecycle.svg?style=flat)](https://cocoapods.org/pods/HoloLifecycle)
[![License](https://img.shields.io/cocoapods/l/HoloLifecycle.svg?style=flat)](https://cocoapods.org/pods/HoloLifecycle)
[![Platform](https://img.shields.io/cocoapods/p/HoloLifecycle.svg?style=flat)](https://cocoapods.org/pods/HoloLifecycle)

## Blog

[组件化分发生命周期](http://gonghonglou.com/2019/08/29/pod-lifecycle/)

[组件化分发生命周期 - AOP 方案](http://gonghonglou.com/2020/03/08/pod-lifecycle-aop/)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

```
@interface HoloLifecycleHomePod : HoloLifecycle

@end


@implementation HoloLifecycleHomePod

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary<UIApplicationLaunchOptionsKey,id> *)launchOptions {
    // do something
    
    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // do something
}

@end
```

## Installation

HoloLifecycle is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'HoloLifecycle'
```

## Author

gonghonglou, gonghonglou@icloud.com

## License

HoloLifecycle is available under the MIT license. See the LICENSE file for more info.


