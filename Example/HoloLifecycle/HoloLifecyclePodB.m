//
//  HoloLifecyclePodB.m
//  HoloLifecycle_Example
//
//  Created by 与佳期 on 2020/3/8.
//  Copyright © 2020 gonghonglou. All rights reserved.
//

#import "HoloLifecyclePodB.h"

@implementation HoloLifecyclePodB

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary<UIApplicationLaunchOptionsKey,id> *)launchOptions {
    NSLog(@"%@ perform selector: %@", NSStringFromClass(self.class), NSStringFromSelector(_cmd));
    
    return YES;
}


@end
