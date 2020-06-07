# HoloLifecycle

[![CI Status](https://img.shields.io/travis/gonghonglou/HoloLifecycle.svg?style=flat)](https://travis-ci.org/gonghonglou/HoloLifecycle)
[![Version](https://img.shields.io/cocoapods/v/HoloLifecycle.svg?style=flat)](https://cocoapods.org/pods/HoloLifecycle)
[![License](https://img.shields.io/cocoapods/l/HoloLifecycle.svg?style=flat)](https://cocoapods.org/pods/HoloLifecycle)
[![Platform](https://img.shields.io/cocoapods/p/HoloLifecycle.svg?style=flat)](https://cocoapods.org/pods/HoloLifecycle)

## Blog

[组件化分发生命周期](http://gonghonglou.com/2019/08/29/pod-lifecycle/)

[组件化分发生命周期 - AOP 方案](http://gonghonglou.com/2020/03/08/pod-lifecycle-aop/)


直接创建  `HoloBaseLifecycle`  的子类，并实现  `UIApplicationDelegate`  方法即可。 

或者创建生命周期分发类，在 load 方法里手动注册该类，以拥有分发生命周期的能力。

`HoloLifecycle` 将分发主工程的 `UIApplicationDelegate`  生命周期到这些子类上。


具体的能力参见以上博客及：

[HoloLifecycleProtocol.h](https://github.com/HoloFoundation/HoloLifecycle/blob/master/HoloLifecycle/Classes/Holo/HoloLifecycleProtocol.h) 

[HoloBaseLifecycle.h](https://github.com/HoloFoundation/HoloLifecycle/blob/master/HoloLifecycle/Classes/Holo/HoloBaseLifecycle.h) 

[HoloLifecycleManager.h](https://github.com/HoloFoundation/HoloLifecycle/blob/master/HoloLifecycle/Classes/Holo/HoloLifecycleManager.h) 


## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

```objc
@interface HoloLifecycleHomePod : HoloBaseLifecycle

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

or

```objc
@interface HoloLifecycleHomePod : NSObject <HoloLifecycleProtocol, UIApplicationDelegate>

@end


@implementation HoloLifecycleHomePod

+ (HoloLifecyclePriority)priority {
    return HoloLifecyclePriorityBeforeHigh;
}

+ (void)load {
    [[HoloLifecycleManager sharedInstance] registerLifecycle:self];
}

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


