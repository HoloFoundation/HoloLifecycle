//
//  HoloLifecyclePodC.m
//  HoloLifecycle_Example
//
//  Created by 与佳期 on 2020/6/7.
//  Copyright © 2020 gonghonglou. All rights reserved.
//

#import "HoloLifecyclePodC.h"
#import <HoloLifecycle/HoloLifecycle.h>

@interface HoloLifecyclePodC () <UIApplicationDelegate>

@end

@implementation HoloLifecyclePodC

+ (void)load {
    [[HoloLifecycleManager sharedInstance] registerLifecycle:self];
}


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary<UIApplicationLaunchOptionsKey,id> *)launchOptions {
    NSLog(@"%@ perform selector: %@", NSStringFromClass(self.class), NSStringFromSelector(_cmd));
    return YES;
}

@end
