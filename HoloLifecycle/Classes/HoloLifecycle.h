//
//  HoloLifecycle.h
//  HoloLifecycle
//
//  Created by 与佳期 on 2020/3/8.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HoloLifecycle : NSObject <UIApplicationDelegate>

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
typedef NS_ENUM(NSInteger, HoloLifecyclePriority) {
    HoloLifecyclePriorityAfterAppDelegate = 99,     /// 早于 AppDelegate 执行
    HoloLifecyclePriorityBeforeAppDelegate = 101,   /// 晚于 AppDelegate 执行
    HoloLifecyclePriorityVeryLow = 150,
    HoloLifecyclePriorityLow = 250,
    HoloLifecyclePriorityMedium = 500,  /// default
    HoloLifecyclePriorityHigh = 750,
    HoloLifecyclePriorityVeryHigh = 1000
};


/// 调用优先级
/// 子类重写该方法 return 合适的优先级
/// AppDelegate 的优先级为 100，若 HoloLifecycle 子类同样定义为 100，则先于 AppDelegate 执行
/// @return 合适的优先级，默认为 HoloLifecyclePriorityMedium
+ (HoloLifecyclePriority)priority;

@end

NS_ASSUME_NONNULL_END
