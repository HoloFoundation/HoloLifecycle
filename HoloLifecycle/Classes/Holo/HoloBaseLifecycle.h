//
//  HoloBaseLifecycle.h
//  HoloLifecycle
//
//  Created by 与佳期 on 2020/6/7.
//

#import <Foundation/Foundation.h>
#import "HoloLifecycleProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface HoloBaseLifecycle : NSObject <UIApplicationDelegate, HoloLifecycleProtocol>

// 自动注册，返回默认优先级
// ---------------------------------------------------------------------
// 说明: 所有继承该类的子类都能够拥有执行 UIApplicationDelegate 生命周期方法的能力。
//
// 直接在子类里实现这些方法即可，例如:
// - (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
//     // Override point for customization after application launch.
//     return YES;
// }
//
// 注意: 只提供执行方法的能力，返回值无实用。
// ---------------------------------------------------------------------


/// 调用优先级
/// 子类重写该方法 return 合适的优先级
/// AppDelegate 的优先级为 300，若 HoloBaseLifecycle 子类同样定义为 300，则先于 AppDelegate 执行
/// @return 合适的优先级，默认为 HoloLifecyclePriorityBeforeMedium
+ (HoloLifecyclePriority)priority;

/// 手动注册生命周期类
/// 子类在 + load 方法内调用该方法注册
+ (void)registerLifecycle;

/// 自动注册
/// 子类重写该方法决定是否自动注册
/// @return 是否自动注册，默认为 YES
+ (BOOL)autoRegister;

@end

NS_ASSUME_NONNULL_END
