//
//  HoloLifecycleManager.h
//  HoloLifecycle
//
//  Created by 与佳期 on 2020/3/8.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HoloLifecycleManager : NSObject

+ (instancetype)sharedInstance;

/// 打印所有 HoloLifecycle 子类执行方法及耗时
/// 在任意 + load 方法里调用该方法，以保证该方法早于 UIApplicationDelegate 方法调用
- (void)logSelectorsAndPerformTime;

@end

NS_ASSUME_NONNULL_END
