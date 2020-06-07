//
//  HoloLifecycleProtocol.h
//  HoloLifecycle
//
//  Created by 与佳期 on 2020/6/7.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// 手动注册，指定优先级
// ---------------------------------------------------------------------
// 说明: 所有遵循该协议的类都能够拥有执行 UIApplicationDelegate 生命周期方法的能力。
//
// 遵守 UIApplicationDelegate 协议，实现协议方法即可，例如:
// - (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
//     // Override point for customization after application launch.
//     return YES;
// }
//
// 注意: 只提供执行方法的能力，返回值无实用。
// ---------------------------------------------------------------------


/// 调用优先级
typedef NS_ENUM(NSInteger, HoloLifecyclePriority) {
    // 晚于 AppDelegate 执行
    HoloLifecyclePriorityAfterLow = 50,
    HoloLifecyclePriorityAfterMedium = 150,
    HoloLifecyclePriorityAfterHigh = 250,
    // 早于 AppDelegate 执行
    HoloLifecyclePriorityBeforeLow = 500,
    HoloLifecyclePriorityBeforeMedium = 750, // default
    HoloLifecyclePriorityBeforeHigh = 1000,
};

@protocol HoloLifecycleProtocol <NSObject>

/// 调用优先级
/// AppDelegate 的优先级为 300，若 HoloLifecycle 子类同样定义为 300，则先于 AppDelegate 执行
/// @return 合适的优先级，默认为 HoloLifecyclePriorityBeforeMedium
+ (HoloLifecyclePriority)priority;

@end

NS_ASSUME_NONNULL_END
